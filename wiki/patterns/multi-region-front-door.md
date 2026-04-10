# Multi-Region Active-Active with Azure Front Door

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

This is the canonical enterprise pattern for globally distributed web applications. Azure Front Door serves as the global edge, terminating TLS at 118+ PoPs worldwide, while regional Application Gateways provide per-region WAF enforcement and backend distribution. The pattern delivers sub-second failover, edge caching, and defense-in-depth without exposing regional infrastructure directly to the internet.

---

## Architecture diagram

```
                             INTERNET
                                │
                    ┌───────────┴───────────┐
                    │                       │
             Tokyo PoP              Virginia PoP         ... (118+ PoPs)
                    │                       │
                    └───────────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │    AZURE FRONT DOOR   │
                    │    (Premium Tier)     │
                    │                       │
                    │  - TLS termination    │
                    │  - WAF (DRS 2.1+)     │
                    │  - Caching (static)   │
                    │  - Health probes      │
                    │  - Routing (latency/  │
                    │    priority/weighted) │
                    └───────────┬───────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
   Private Link          Private Link          Private Link
   (Premium only)        (Premium only)        (Premium only)
          │                     │                     │
          ▼                     ▼                     ▼
 ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
 │ REGION: EAST US │  │ REGION: WEST EU │  │ REGION: JAPAN   │
 │                 │  │                 │  │                 │
 │ App Gateway     │  │ App Gateway     │  │ App Gateway     │
 │ WAF_v2          │  │ WAF_v2          │  │ WAF_v2          │
 │ (per-site WAF)  │  │ (per-site WAF)  │  │ (per-site WAF)  │
 │                 │  │                 │  │                 │
 │ Backend Pool:   │  │ Backend Pool:   │  │ Backend Pool:   │
 │ - App Service   │  │ - AKS (via ILB) │  │ - VMs           │
 │ - VMSS          │  │ - Container App │  │ - App Service   │
 │                 │  │                 │  │                 │
 │ (Private VNet)  │  │ (Private VNet)  │  │ (Private VNet)  │
 └─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## How the traffic flows

| Step | Component | Action |
|---|---|---|
| 1 | Client DNS | Resolves `app.contoso.com` → Front Door anycast IP (nearest PoP) |
| 2 | Edge PoP | TLS handshake terminates at PoP; WAF evaluates request (DRS + Bot Manager) |
| 3 | Cache check | For GET requests: cache HIT returns immediately; MISS proceeds to origin |
| 4 | Origin selection | Health probe status + routing method (latency/priority/weighted) determines target origin group |
| 5 | Private Link | Front Door connects to regional App Gateway over Microsoft backbone via Private Link |
| 6 | Regional App Gateway | Re-terminates TLS; applies per-site/per-URI WAF rules; routes to backend pool |
| 7 | Backend | App Service / AKS / VMs process request; response flows back through chain |

---

## Health probes and failover

Front Door health probes are sent **from each PoP that receives real user traffic** — not from a single location. This provides true edge-perspective health visibility.

| Health probe setting | Recommended value | Rationale |
|---|---|---|
| Protocol | HTTPS | Validates TLS cert chain + application response |
| Method | HEAD | Lower origin load than GET; same health signal |
| Path | `/health` or `/healthz` | Dedicated endpoint returning 200 only when app is healthy |
| Interval | 5–30 seconds [VERIFY] | Lower = faster failover; higher = less probe load |
| Sample size | 4 [VERIFY] | Number of recent probes to evaluate |
| Successful samples required | 2 [VERIFY] | Threshold for "healthy" status |

**Failover behavior:**
- If all origins in the primary group fail: Front Door routes to the next-priority origin group automatically
- If **all** origins across **all** groups fail: Front Door round-robins across all origins (fail-open — prevents total outage)
- Failover latency: typically 10–30 seconds depending on probe interval and sample thresholds

---

## Origin groups: active-active vs active-passive

### Active-active (recommended for global latency optimization)

| Origin | Priority | Weight | Effect |
|---|---|---|---|
| East US App Gateway | 1 | 1000 | Equal priority — latency determines selection |
| West EU App Gateway | 1 | 1000 | Equal priority — latency determines selection |
| Japan App Gateway | 1 | 1000 | Equal priority — latency determines selection |

With **latency sensitivity = 0 ms** (default): all traffic goes to the lowest-latency origin. With latency sensitivity > 0: origins within the sensitivity window share traffic by weight.

### Active-passive (recommended for disaster recovery only)

| Origin | Priority | Weight | Effect |
|---|---|---|---|
| East US App Gateway | 1 | 1000 | Primary — all traffic unless unhealthy |
| West EU App Gateway | 2 | 1000 | Standby — activated only when priority-1 fails |

---

## Key configuration areas

### 1. Private Link origin (Premium only — strongly recommended)

Private Link eliminates public IP exposure on App Gateway. Front Door creates a private endpoint in a **Front Door-managed VNet**, not your customer VNet.

| Configuration step | Detail |
|---|---|
| Origin type | Application Gateway |
| Private Link sub-resource | `appGatewayFrontendIP` |
| Approval | Manual (admin approves PE connection request) or Auto (if RBAC-permitted) |
| Region | Private Link origin must be in a [supported region](../../raw/articles/frontdoor/private-link.md) with AZ support [VERIFY] |

**Rate limit:** 7,200 RPS per regional cluster per profile [VERIFY]. Mitigate by adding origins in multiple Private Link regions.

### 2. TLS configuration: end-to-end encryption

```
Client ──HTTPS──► Front Door PoP ──HTTPS──► App Gateway ──HTTPS──► Backend
         TLS 1.2+             re-encrypts              re-encrypts
```

| Segment | Certificate |
|---|---|
| Client → Front Door | Front Door managed cert (auto-rotates 45 days before expiry) or BYOC from Key Vault |
| Front Door → App Gateway | App Gateway listener cert (private CA acceptable over Private Link) |
| App Gateway → Backend | Backend cert; App Gateway can validate or skip validation |

### 3. Session affinity placement

| Affinity location | Use case |
|---|---|
| **Front Door only** | Stateless backends; session pinned to one region; simplest model |
| **App Gateway only** | Regional stateful backends; no cross-region affinity needed |
| **Both (layered)** | Rare — only when regional App Gateway routes to multiple backend servers that also need affinity |

Front Door affinity cookie: `ASLBSA` / `ASLBSACORS`. App Gateway affinity cookie: gateway-managed (does not append domain — subdomain clients cannot reuse).

### 4. Custom domain and certificate management

| Approach | Pros | Cons |
|---|---|---|
| **Front Door managed cert** | Zero-touch; auto-renews 45 days before expiry | Only DV certificates; no custom CA |
| **BYOC from Key Vault** | EV/OV certs; custom CA; full control | Must manage Key Vault access policy; set version to `Latest` for auto-rotation |

---

## Operational considerations

### Restricting direct App Gateway access

Without lockdown, attackers can bypass Front Door by hitting App Gateway's public IP directly. Two methods:

| Method | Configuration |
|---|---|
| **NSG + service tag** (Standard/Premium — public App Gateway) | Inbound rule: Allow source `AzureFrontDoor.Backend` to App Gateway subnet; Deny all other internet |
| **Private Link origin** (Premium — no public IP) | App Gateway has no public IP; only reachable via Front Door-managed private endpoint |

Private Link origin is the preferred approach — it removes the attack surface entirely.

### Blue/green deployments via weight shifting

| Deployment phase | East US (current) | East US (new) | Effect |
|---|---|---|---|
| Before | weight: 1000 | weight: 0 | 100% to current |
| Canary | weight: 900 | weight: 100 | 10% to new |
| Ramp | weight: 500 | weight: 500 | 50/50 |
| Full | weight: 0 | weight: 1000 | 100% to new |
| Rollback | weight: 1000 | weight: 0 | Instant rollback |

### DDoS Protection placement

| Layer | Protection | Notes |
|---|---|---|
| Front Door | Built-in L3/L4 DDoS at edge; WAF for L7 (rate limiting, bot management) | Always active; no additional cost |
| Regional VNet (App Gateway) | Azure DDoS Network Protection (optional) | Adds SLA guarantee, cost protection, Rapid Response Team; required if App Gateway has public IP exposed |

**Recommendation:** If using Private Link origins (no public IP on App Gateway), VNet DDoS Protection is not required for that public IP — there is no public IP to protect. However, DDoS Protection is still valuable for other public IPs in the VNet (VMs, Load Balancers).

### Monitoring: what to alert on

| Layer | Metric / Log | Alert condition | Severity |
|---|---|---|---|
| Front Door | `OriginHealthPercentage` | < 50% | Critical |
| Front Door | `RequestCount` (4xx/5xx split) | Error rate > 5% | High |
| Front Door | WAF `Blocked` action count | Spike above baseline | Medium |
| Front Door | `TotalLatency` | P95 > threshold | Medium |
| App Gateway | `UnhealthyHostCount` | > 0 | High |
| App Gateway | `BackendResponseStatus` 5xx | > threshold | High |
| App Gateway | `CapacityUnits` | Near limit (approaching 125 instances) | Medium |

---

## When to use this pattern

✅ **Use this pattern when:**
- You serve users **globally** and want edge TLS termination for latency reduction
- You need **multi-region active-active** with automatic failover
- You want to **lock down regional infrastructure** from direct internet access (Private Link origins)
- You need **layered WAF**: global edge protection (Front Door) + regional per-URI policies (App Gateway)
- You need **CDN caching** at the edge for static assets
- You want **centralized certificate management** with auto-rotation

❌ **Consider simpler alternatives when:**
- Single-region deployment only → Use Application Gateway alone
- No WAF needed, purely internal traffic → Use Azure Load Balancer
- Low traffic, cost-sensitive → Front Door Premium base fee (~$330/month [VERIFY]) may not justify the benefit

---

## Decision checklist

Before implementing this pattern, confirm:

| # | Question | Expected answer |
|---|---|---|
| 1 | Do users access this app from multiple geographic regions? | Yes |
| 2 | Is sub-minute failover between regions required? | Yes |
| 3 | Is origin lockdown (no direct internet to regional infra) required? | Yes → use Private Link origins |
| 4 | Do you need per-URI or per-site WAF policies at regional level? | Yes → use App Gateway WAF_v2 in addition to Front Door WAF |
| 5 | Are your backends all HTTP/HTTPS? | Yes — Front Door is L7 only |
| 6 | Is CDN caching for static content valuable? | Yes → enable caching on Front Door |
| 7 | Can you justify ~$330/month base fee + per-request + per-GB egress? | Yes |

---

## Limits reference [VERIFY all]

| Limit | Value | Notes |
|---|---|---|
| Private Link RPS per regional cluster per profile | 7,200 [VERIFY] | Add origins in multiple regions to scale |
| Health probe interval minimum | 5 seconds [VERIFY] | |
| Origin groups per profile | 100 [VERIFY] | |
| Origins per origin group | 100 [VERIFY] | |
| Custom domains per profile (free) | 100/month | |
| App Gateway max instances (v2 autoscale) | 125 | Scale-out takes 3–5 min |

---

## Related pages

| Page | Relationship |
|---|---|
| [Azure Front Door](../services/front-door.md) | Global tier, Private Link origins, WAF, health probes, routing methods |
| [Application Gateway](../services/application-gateway.md) | Regional WAF, per-site policies, mTLS, backend pools |
| [App Gateway vs Front Door](../comparisons/app-gateway-vs-front-door.md) | Feature comparison, when to use each, combined pattern |
| [Private Link](../services/private-link.md) | Private endpoint architecture, DNS configuration |
| [Web Application Firewall](../services/web-application-firewall.md) | DRS rule sets, bot protection, anomaly scoring |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure Front Door](../services/front-door.md) | Private Link origins, routing methods, health probes, billing, limits |
| [Application Gateway](../services/application-gateway.md) | WAF_v2, per-site policies, autoscaling, backend pools, pricing |
| [App Gateway vs Front Door](../comparisons/app-gateway-vs-front-door.md) | Combined pattern architecture, WAF feature comparison |
