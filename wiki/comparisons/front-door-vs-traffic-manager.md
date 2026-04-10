# Azure Front Door vs Azure Traffic Manager

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Both services provide global traffic distribution across Azure regions. They operate at fundamentally different layers: Front Door is a Layer 7 reverse proxy with anycast edge PoPs, while Traffic Manager is DNS-only with no data plane. This page forces the decision and documents when to use each — including the pattern of using both together.

---

## At a glance

| Dimension | Azure Front Door | Azure Traffic Manager |
|---|---|---|
| **Layer** | L7 (HTTP/S) — reverse proxy | DNS (L7 application, but DNS-only) |
| **Data plane** | ✅ Yes — terminates connections at edge PoPs | ❌ No — returns DNS response; client connects directly to origin |
| **Network** | 118+ anycast PoPs on Microsoft edge | N/A — DNS responses direct clients to origin |
| **TLS termination** | ✅ Yes — edge PoP handles SSL/TLS | ❌ No — origin handles SSL/TLS |
| **WAF** | ✅ Yes — custom + managed rules (Premium) | ❌ No |
| **Caching / CDN** | ✅ Yes — static content caching | ❌ No |
| **Session affinity** | ✅ Yes — cookie-based (`ASLBSA`) | ❌ No — DNS has no client tracking |
| **Origin types** | Azure App Service, Storage, VM, Container Apps, API Management, Application Gateway, any public endpoint | Azure endpoints, External (on-prem, other cloud), Nested TM profiles |
| **Private origins** | ✅ Yes (Premium) — Private Link to App Service, Storage, ILB, APIM, App Gateway, Container Apps | ❌ No — public endpoints only |
| **Failover speed** | Seconds (active health probes + immediate routing change) | DNS TTL dependent (30–300 s typical; minimum 0 s but cached by resolvers) |
| **Latency added** | Edge PoP adds small latency to first request; subsequent requests benefit from split TCP | Zero — DNS only; all latency is origin-to-client |
| **Cost model** | Base fee/profile + requests + egress | Per DNS query + health check probes |

---

## Side-by-side comparison

### Routing methods

| Routing method | Front Door | Traffic Manager |
|---|---|---|
| **Latency-based** | ✅ Default — routes to lowest-latency origin | ✅ Performance method — routes to lowest-latency endpoint |
| **Priority** | ✅ Priority 1–5 per origin | ✅ Priority 1–1000 per endpoint |
| **Weighted** | ✅ Weight 1–1000 per origin | ✅ Weight 1–1000 per endpoint |
| **Geographic** | ✅ Via rules engine match conditions | ✅ Geographic method — maps regions to endpoints |
| **Session affinity** | ✅ Cookie-based (`ASLBSA` / `ASLBSACORS`) | ❌ Not supported — DNS has no session awareness |
| **Subnet-based** | ❌ Not directly (use rules engine IP match) | ✅ Subnet method — maps client IP CIDRs to endpoints |
| **Multivalue** | ❌ Not applicable | ✅ Returns all healthy endpoints in DNS response |

### Health probes

| Aspect | Front Door | Traffic Manager |
|---|---|---|
| **Probe types** | HTTP, HTTPS | TCP, HTTP, HTTPS |
| **Probe source** | Each PoP that receives real traffic | Microsoft global probe fleet |
| **Probe frequency** | Configurable interval; reduced for idle PoPs | 30 s (standard) or 10 s (fast — additional cost) |
| **Healthy response** | 200 OK only | Configurable status code ranges (up to 8 ranges) |
| **Custom headers** | ✅ Supported | ✅ Up to 8 `header:value` pairs |
| **Probe method** | GET or HEAD (HEAD recommended) | HTTP/HTTPS: configurable; TCP: connection success |
| **All-probes-down behavior** | Fail-open: routes round-robin to all origins | Fail-open: returns all endpoints in DNS |

### Failover characteristics

| Scenario | Front Door | Traffic Manager |
|---|---|---|
| **Origin failure detected** | Seconds — active probes from each PoP | Depends on probe interval (10–30 s) × tolerated failures (0–9) |
| **Traffic redirected** | Immediate at edge — next request goes to healthy origin | DNS TTL must expire before clients see new IP |
| **Client impact** | Seamless for new requests; existing connections may fail | Must wait for DNS TTL expiry + resolver cache flush |
| **Minimum TTL** | N/A — routing is immediate | 0 s (but resolver caching is unpredictable) |
| **Recommended TTL for fast failover** | N/A | 30–60 s (trade-off: more DNS queries = higher cost) |

### Security features

| Feature | Front Door | Traffic Manager |
|---|---|---|
| **WAF (custom rules)** | ✅ Standard + Premium | ❌ No |
| **WAF (managed rules)** | ✅ Premium only (DRS 2.x, Bot Manager) | ❌ No |
| **DDoS protection** | ✅ Built-in L3/L4; L7 via WAF | ❌ No — origin must handle DDoS |
| **Bot protection** | ✅ Premium — Bad/Good/Unknown classification | ❌ No |
| **Geo-filtering** | ✅ Via custom rules | ✅ Geographic routing (but no blocking — just routing) |
| **Rate limiting** | ✅ Via WAF rules | ❌ No |
| **TLS policy** | ✅ Predefined or custom cipher suites | N/A — no TLS termination |
| **End-to-end encryption** | ✅ TLS 1.2/1.3 to origin | N/A — origin handles TLS |

### CDN and acceleration

| Feature | Front Door | Traffic Manager |
|---|---|---|
| **Static content caching** | ✅ Yes — GET requests, configurable TTL | ❌ No |
| **Dynamic site acceleration** | ✅ Split TCP reduces RTT to origin | ❌ No — client connects directly to origin |
| **Compression** | ✅ Gzip, Brotli (1 KB – 8 MB files) | ❌ No |
| **Object chunking** | ✅ 8 MB chunks for large files | ❌ No |
| **Anycast edge network** | ✅ 118+ PoPs | N/A — DNS resolution only |

### Private origin support

| Aspect | Front Door | Traffic Manager |
|---|---|---|
| **Private Link origins** | ✅ Premium only | ❌ No — public endpoints only |
| **Supported origin types** | App Service, Blob Storage, Static Website, Internal LB (incl. AKS), APIM, App Gateway, Container Apps | N/A |
| **Private endpoint location** | Front Door-managed VNet (not customer VNet) | N/A |
| **Approval workflow** | Customer must approve PE connection | N/A |
| **Rate limit** | 7,200 RPS per regional cluster per profile [VERIFY] | N/A |

---

## Cost comparison

| Component | Front Door Standard | Front Door Premium | Traffic Manager |
|---|---|---|---|
| **Base fee** | ~$35/month/profile [VERIFY] | ~$330/month/profile [VERIFY] | $0 |
| **Requests (client → edge)** | Per-zone billing (8 zones) | Higher rate than Standard | N/A |
| **DNS queries** | N/A | N/A | Per million queries |
| **Egress (edge → client)** | Per-zone billing | Same as Standard | N/A |
| **Egress (edge → origin)** | Per-zone billing | Same as Standard | N/A |
| **Health probes** | Included | Included | Standard: per endpoint; Fast (10 s): higher rate |
| **WAF** | Custom rules included | Managed rules included | N/A |
| **Private Link** | N/A | Included in base | N/A |
| **Custom domains (>100)** | Free | Free | $5/domain/month |
| **Real User Measurements** | N/A | N/A | Per measurement sent |
| **Traffic View** | N/A | N/A | Per data point processed |

**Cost guidance:**
- **Front Door** is more expensive but provides edge acceleration, caching, and WAF
- **Traffic Manager** is cheaper for pure DNS-based global load balancing without edge features
- For **many small profiles**, Front Door Premium base fee (~$330/profile) can be prohibitive — consolidate endpoints
- For **high query volume without edge features**, Traffic Manager is significantly cheaper

---

## When to use Front Door

✅ **Use Azure Front Door when:**

| Scenario | Why Front Door |
|---|---|
| Global web application delivery | Edge PoP acceleration, caching, split TCP |
| WAF required at the edge | Block attacks before traffic reaches origin |
| Static + dynamic content mix | Single service handles both CDN and app delivery |
| Fast failover (<10 s) | Health probes + immediate routing; no DNS TTL dependency |
| SSL offload / certificate management | Managed certs, auto-rotation, BYOC from Key Vault |
| Origin lockdown | Private Link origins (Premium) eliminate public exposure |
| Session affinity | Cookie-based; maintains user session across requests |
| Bot protection | Bad bot classification, JS challenge, CAPTCHA (Premium) |
| Blue/green or canary deployments | Weighted routing between origin groups |
| Rate limiting at the edge | WAF rate limit rules absorb traffic spikes |

---

## When to use Traffic Manager

✅ **Use Azure Traffic Manager when:**

| Scenario | Why Traffic Manager |
|---|---|
| Non-HTTP workloads | Traffic Manager works with any TCP/UDP endpoint (DNS-only) |
| Global DNS LB without edge processing | Lower cost; no data-plane footprint |
| DNS-level multi-cloud / hybrid routing | External endpoints can be on-prem or other clouds |
| Geographic compliance / data residency | Deterministic geographic routing to specific regions |
| Multivalue response (client-side retry) | DNS returns all healthy endpoint IPs |
| Subnet-based routing | Route by source IP CIDR (corporate office, ISP-specific) |
| Very large number of endpoints | No base fee; cost scales with query volume |
| Origin must handle TLS/WAF | Already have WAF at origin; don't need edge termination |
| Complex multi-method routing | Nested profiles combine multiple routing methods |

---

## When to use BOTH together

The most resilient global architecture often combines Traffic Manager and Front Door:

```
┌──────────────────────────────────────────────────────────────────┐
│                        Client DNS query                          │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Traffic Manager                            │
│                   (Global DNS load balancer)                     │
│        • Priority / Performance routing across AFD profiles      │
│        • Failover between CDN providers (disaster scenario)      │
│        • Geographic compliance (direct to region-specific AFD)   │
└──────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
    ┌───────────────────────┐   ┌───────────────────────┐
    │   Front Door (US)     │   │   Front Door (EU)     │
    │   • L7 acceleration   │   │   • L7 acceleration   │
    │   • WAF               │   │   • WAF               │
    │   • Caching           │   │   • Caching           │
    └───────────────────────┘   └───────────────────────┘
                    │                       │
                    ▼                       ▼
            [US Origins]            [EU Origins]
```

### Use case: Multi-CDN failover

Traffic Manager provides DNS-level failover between:
- Primary: Azure Front Door
- Secondary: Alternate CDN provider (Akamai, Cloudflare, etc.)

If Front Door has a global outage, Traffic Manager detects probe failures and directs DNS to the alternate CDN.

### Use case: Regional data residency

Traffic Manager routes by geography:
- EU users → EU-specific Front Door profile → EU origins only
- US users → US-specific Front Door profile → US origins only

Each Front Door profile has independent WAF policies, caching rules, and origin configurations meeting regional compliance.

### Use case: Complex routing combinations

Traffic Manager nests multiple routing methods:
- Parent: Performance routing (global)
- Child (per region): Priority routing (primary/DR origins)

Front Door then provides L7 features per-region.

### Architectural rule

> **Traffic Manager must be *in front of* Front Door, never behind it.**

Traffic Manager returns DNS responses pointing to Front Door endpoints. Front Door cannot use Traffic Manager as an origin (Traffic Manager has no IP — it's DNS-only).

---

## Decision guide

| Requirement | Recommendation |
|---|---|
| HTTP/S web application with global users | **Front Door** |
| Need WAF at the edge | **Front Door Premium** |
| Need caching / CDN | **Front Door** |
| Need fast failover (<10 s) | **Front Door** |
| Need session affinity | **Front Door** |
| Non-HTTP workload (TCP/UDP) | **Traffic Manager** |
| DNS-only, no edge processing | **Traffic Manager** |
| Multi-cloud or hybrid endpoints | **Traffic Manager** (or both) |
| Cost-sensitive, high query volume, no edge features needed | **Traffic Manager** |
| Deterministic geographic routing (compliance) | **Traffic Manager** or **Front Door + rules engine** |
| Multivalue DNS response | **Traffic Manager** |
| Subnet-based routing | **Traffic Manager** |
| Mission-critical with CDN failover | **Traffic Manager** → **Front Door** |

---

## SKU comparison summary

### Front Door

| SKU | WAF | Private Link | Base cost | Notes |
|---|---|---|---|---|
| **Standard** | Custom rules only | ❌ | ~$35/mo [VERIFY] | Good for simple apps without managed WAF |
| **Premium** | Custom + managed rules + bot protection | ✅ | ~$330/mo [VERIFY] | Enterprise security requirements |
| **Classic** ⚠️ | Custom + managed (DRS 1.1 only) | ❌ | Per-rule pricing | **Retiring March 31, 2027** |

### Traffic Manager

Traffic Manager has no SKU tiers — consumption-based billing only:
- Per DNS query
- Per health check (standard vs. fast probing)
- Per Real User Measurement (if enabled)
- Per Traffic View data point (if enabled)

---

## Key operational notes

| Topic | Front Door | Traffic Manager |
|---|---|---|
| **Apex domain** | Supported via Azure DNS alias record | Requires CNAME workaround (Azure DNS alias record) |
| **Health probe visibility** | User-Agent: `Edge Health Probe` | Microsoft global probe IPs |
| **Maintenance windows** | No scheduled maintenance concept | No scheduled maintenance concept |
| **Monitoring** | Azure Monitor metrics, access logs, WAF logs | Azure Monitor metrics, diagnostic logs, Traffic View |
| **Origin restriction** | Use Front Door service tags to restrict origin | N/A — origin is directly exposed |
| **Host header** | Configurable per origin group | N/A — client sends Host header directly to origin |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure Front Door](../services/front-door.md) | Routing, caching, TLS, WAF, Private Link, SKUs, retirements |
| [Azure Traffic Manager](../services/traffic-manager.md) | Routing methods, health monitoring, nested profiles, limits |
| [Load Balancing Options](./load-balancing-options.md) | Full comparison of all Azure load balancing services |
