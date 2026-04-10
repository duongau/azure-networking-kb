# Load Balancing & Traffic Routing: Decision Guide

> **Compiled:** 2026-04-10 | **Sources:** wiki/services/ (Load Balancer · Application Gateway · Front Door · Traffic Manager · WAF) + raw/articles/networking/load-balancer-content-delivery/load-balancing-content-delivery-overview.md | **Status:** ✅ current

---

## Quick-pick matrix

✅ = purpose-built / native support | ⚠️ = supported with caveats | ❌ = not supported / wrong tool

| Use case | Azure Load Balancer | Application Gateway | Azure Front Door | Traffic Manager | WAF |
|---|---|---|---|---|---|
| **Global HTTP routing** | ⚠️ Global tier is L4 only; no HTTP awareness | ❌ Regional only; no cross-region capability | ✅ 118+ PoPs; split-TCP acceleration; CDN; WAF at edge | ⚠️ DNS CNAME redirect only; no TLS offload, no caching, client connects direct to origin | ❌ Not a router |
| **Regional HTTP routing** | ❌ No HTTP path/host awareness; L4 pass-through only | ✅ URL path, hostname, header/query routing; cookie affinity; URL rewrite | ⚠️ Adds global hop; overkill for single-region; no mTLS | ❌ DNS-only; cannot route within a region | ❌ Not a router |
| **L4 TCP/UDP** | ✅ Millions of flows; pass-through; lowest latency | ⚠️ TCP/TLS proxy public preview only; no WAF on L4 listeners | ❌ HTTP/HTTPS only | ⚠️ TCP health probes only; no L4 routing logic; client connects directly | ❌ No L4 capability |
| **DNS-based global routing** | ❌ IP-based; no DNS | ❌ Regional reverse proxy | ⚠️ Full proxy at edge — more than DNS; use when CDN/WAF/TLS offload is needed | ✅ Purpose-built; 6 routing methods; protocol-agnostic | ❌ Not a router |
| **WAF integration** | ❌ No inspection capability | ✅ WAF_v2: OWASP CRS 3.2/DRS; per-listener and per-path policies | ✅ Standard: custom rules; Premium: DRS 2.1+ + Bot Manager | ❌ DNS-only; no traffic inspection | ✅ WAF policy resource — attach to App GW (v2) or Front Door |
| **Private/internal traffic** | ✅ Internal LB: private VIP; VNet-scoped; RFC 1918 frontend | ✅ Private-only deployment (v2, GA); no public IP required | ❌ Internet-facing ingress only; Premium Private Link reaches private *origins*, but ingress is always public | ❌ Public internet only; no RFC 1918 routing | ⚠️ App Gateway WAF supports private; Front Door WAF is internet-facing only |
| **Multi-region failover** | ✅ Global tier: geo-proximity; auto-failover when regional LB health = 0 | ❌ Regional only; needs Front Door or TM in front for failover | ✅ Priority + health probes from all active PoPs; sub-minute failover | ✅ Priority routing; configurable TTL + fast probe (10 s) | ❌ Not a router |
| **WebSocket** | ✅ Pass-through (L4 transparent; no HTTP inspection) | ✅ Native; always on (no per-listener toggle) | ❓ Not documented in source articles; HTTP proxy model may not support WebSocket upgrades — verify before use | ⚠️ DNS-level only; WebSocket client connects directly to origin | ⚠️ App Gateway WAF_v2 only |
| **gRPC** | ✅ Pass-through (L4 TCP transparent) | ❌ HTTP/2 frontend-only; backend always HTTP/1.1 — breaks gRPC end-to-end HTTP/2 requirement | ❌ HTTP/1.1 to origin; gRPC end-to-end HTTP/2 not supported | ⚠️ DNS-level only; gRPC client connects directly to origin | ❌ |
| **mTLS (client cert auth)** | ✅ Pass-through (L4; TLS not terminated) | ✅ v2 strict mode (gateway validates client cert) or passthrough; max 100 trusted CA chains/SSL profile | ❌ Terminates TLS; no client certificate authentication | ⚠️ DNS-level only; mTLS handled entirely by origin | ⚠️ App Gateway WAF_v2 only; WAF inspects after mTLS validation |
| **Cost-sensitive** | ✅ No base fee; per-rule/hour + data processing; cheapest per-flow option | ✅ Autoscales to 0 min instances; idle cost approaches $0 (Standard_v2/Basic preview) | ⚠️ Standard ~$35/mo base fee; Premium ~$330/mo — unavoidable even at zero traffic | ✅ Per-query + per-probe billing; no base fee; lowest absolute cost for DNS routing | ⚠️ WAF_v2 CU cost embedded in App GW billing; Front Door WAF included in profile base |

---

## Service summaries

### Azure Load Balancer

Azure Load Balancer is a **Layer 4 (TCP/UDP), pass-through, non-terminating** network load balancer. It distributes inbound flows across backend VMs or VMSS without inspecting payload — original IP is preserved. Available in three SKUs (Standard, Gateway, Basic [retiring Sep 30, 2025]) and two deployment types (Public, Internal). Standard SKU adds a **Global tier** (cross-region) that routes via geo-proximity across regional Standard LBs using a static anycast IP. Gateway SKU is purpose-built for transparent NVA insertion using VXLAN encapsulation, requiring no UDRs.

| Property | Value |
|---|---|
| **OSI Layer** | Layer 4 (TCP/UDP) |
| **Scope** | Regional (Standard/Gateway) · Global / cross-region (Standard Global tier) |
| **Key SKUs** | Standard, Standard Global, Gateway, Basic *(retired Sep 30, 2025)* |
| **SLA** | 99.99% [VERIFY] (Standard, ≥ 2 healthy backend instances) |

---

### Application Gateway

Application Gateway is a **Layer 7, terminating reverse proxy** for regional HTTP/HTTPS workloads. It makes routing decisions on URL paths, host headers, query strings, and HTTP attributes. It terminates TLS, optionally re-encrypts to backends (end-to-end TLS), and integrates WAF (WAF_v2 SKU). Application Gateway for Containers is a separate product (next-gen Kubernetes-native ingress via ALB Controller).

| Property | Value |
|---|---|
| **OSI Layer** | Layer 7 (HTTP/HTTPS); Layer 4 TCP/TLS proxy *(public preview)* |
| **Scope** | Regional only |
| **Key SKUs** | Standard_v2, WAF_v2, Basic *(preview)*, v1 *(retiring Apr 28, 2026 — do not deploy)* |
| **SLA** | 99.95% [VERIFY] (Standard_v2 / WAF_v2) |

---

### Azure Front Door

Azure Front Door is a **globally-distributed CDN and application delivery controller** operating at Layer 7. It terminates client connections at the nearest of 118+ edge PoPs, applies WAF rules, serves cached responses, and accelerates dynamic content over Microsoft's private WAN. Standard/Premium use unicast routing with Traffic Manager for PoP selection; Classic (retiring Mar 31, 2027) used anycast. It is exclusively internet-facing.

| Property | Value |
|---|---|
| **OSI Layer** | Layer 7 (HTTP/HTTPS) |
| **Scope** | Global (118+ PoPs, 100+ metro areas) |
| **Key SKUs** | Standard (~$35/mo base [VERIFY]), Premium (~$330/mo base [VERIFY]), Classic *(retiring Mar 31, 2027)* |
| **SLA** | Not specified in source articles — [VERIFY] |

---

### Traffic Manager

Traffic Manager is a **DNS-based, global traffic load balancer** with no data-plane footprint. It returns a DNS response pointing the client to the best endpoint; the client then connects directly. All application traffic bypasses Traffic Manager entirely after DNS resolution. It supports any protocol, any endpoint type (Azure, external, nested profiles), and 6 distinct routing methods. Failover speed is bounded by DNS TTL and probe interval.

| Property | Value |
|---|---|
| **OSI Layer** | DNS (Application layer — no proxy, no data plane) |
| **Scope** | Global |
| **Key SKUs** | No tiers — consumption-based (per-query + per-probe) |
| **SLA** | Not specified in source articles — [VERIFY] |

---

### Web Application Firewall (WAF)

WAF is not a standalone load balancer — it is a **Layer 7 security add-on** deployed on Application Gateway (WAF_v2) or Azure Front Door (Standard/Premium). All WAF configuration lives in a **WAF Policy** resource associated to a gateway, listener, path, or Front Door domain. Custom rules are always evaluated before managed rule sets. WAF operates in Detection (log only) or Prevention (log + block) mode using anomaly scoring (block threshold ≥ 5).

| Property | Value |
|---|---|
| **OSI Layer** | Layer 7 inspection |
| **Scope** | Regional (App Gateway) or Global (Front Door) |
| **Key SKUs** | WAF_v2 on App Gateway · Standard WAF on Front Door · Premium WAF on Front Door |

---

## Decision flowchart (text)

```
START: What type of traffic?
│
├── L4 TCP/UDP (non-HTTP) ──────────────────────────────────────────────────────────────────────────────┐
│   │                                                                                                    │
│   ├── Is traffic private/internal (VNet)?                                                             │
│   │   ├── YES → Standard Internal Load Balancer                                                      │
│   │   └── NO (public internet) → Standard Public Load Balancer                                       │
│   │                                                                                                    │
│   ├── Do you need to insert an NVA (firewall/IDS) transparently?                                      │
│   │   └── YES → Gateway Load Balancer (VXLAN; no UDRs)                                               │
│   │                                                                                                    │
│   └── Do you need multi-region L4 failover with geo-proximity?                                        │
│       └── YES → Standard Load Balancer Global tier                                                    │
│                                                                                                        │
└── HTTP/HTTPS                                                                                           │
    │                                                                                                    │
    ├── Is scope GLOBAL (multiple Azure regions)?                                                        │
    │   │                                                                                                │
    │   ├── Do you need CDN caching, WAF, or TLS offload at the edge?                                   │
    │   │   └── YES → Azure Front Door (Standard or Premium)                                            │
    │   │       ├── Need managed OWASP rules / bot protection / Private Link origins?                   │
    │   │       │   └── YES → Front Door Premium                                                        │
    │   │       └── Custom WAF rules only / no managed rulesets needed?                                 │
    │   │           └── YES → Front Door Standard                                                       │
    │   │                                                                                                │
    │   └── DNS-only global routing (no TLS offload, no caching, cost-critical)?                        │
    │       └── YES → Traffic Manager                                                                   │
    │           ├── Active/passive failover? → Priority routing                                         │
    │           ├── Lowest latency per region? → Performance routing                                    │
    │           ├── Data sovereignty? → Geographic routing                                              │
    │           └── Gradual rollout? → Weighted routing                                                 │
    │                                                                                                    │
    └── Is scope REGIONAL (single Azure region)?                                                        │
        │                                                                                               │
        ├── Do you need WAF / TLS termination / path or host routing?                                   │
        │   └── YES → Application Gateway                                                              │
        │       ├── Need WAF (OWASP/DRS)? → WAF_v2 SKU                                                │
        │       ├── Internet-facing and no WAF needed? → Standard_v2 SKU                               │
        │       └── Private/internal only (no public IP)? → Private-only deployment (v2)              │
        │                                                                                               │
        └── Do you need raw TCP/UDP throughput with no HTTP inspection?                                 │
            └── YES → Azure Load Balancer (Standard)                                                   │
                ├── Internet-facing → Public Standard LB                                               │
                └── VNet-internal → Internal Standard LB                                               ←┘
```

**Combined patterns** (see [Common patterns](#common-patterns)):
- Global HTTP + regional WAF → **Front Door → Application Gateway**
- Global DNS + regional WAF → **Traffic Manager → Application Gateway**
- Zero public origin IPs → **Front Door Premium → Private Link → Internal LB or App Gateway**

---

## Head-to-head comparisons

### Azure Load Balancer vs Application Gateway

| Dimension | Azure Load Balancer (Standard) | Application Gateway (v2) |
|---|---|---|
| **Layer** | L4 (TCP/UDP) — pass-through; no connection termination | L7 (HTTP/HTTPS) — terminating reverse proxy; L4 TCP/TLS proxy in preview |
| **Scope** | Regional + Global tier (cross-region) | Regional only |
| **SSL/TLS termination** | ❌ Pass-through; TLS handled by backend | ✅ Terminates TLS 1.2+; optional end-to-end re-encrypt to backend (TLS 1.3 preferred) |
| **WAF** | ❌ None | ✅ WAF_v2 SKU: OWASP CRS 3.2 / DRS; custom rules; per-listener/per-path policies |
| **Health probes** | TCP, HTTP, HTTPS; source IP 168.63.129.16; 5 s default interval | Default auto-probe + custom (path, interval, response codes, response body match) |
| **Session affinity** | 2-tuple hash (client IP) or 3-tuple (client IP + protocol) — IP-based | Cookie-based (gateway-managed `ApplicationGatewayAffinity` cookie) |
| **HTTP routing** | ❌ No path/host/header routing | ✅ URL path, hostname, headers, query string |
| **mTLS** | ✅ Pass-through (client cert reaches backend unmodified) | ✅ Strict (gateway validates cert) or passthrough mode; max 100 CA chains/SSL profile [VERIFY] |
| **gRPC** | ✅ Pass-through (end-to-end HTTP/2 preserved) | ❌ HTTP/2 frontend only; backend always HTTP/1.1 — breaks gRPC |
| **Autoscaling** | ✅ Inherently elastic; no instances to scale | ✅ v2: 0–125 instances; scale-out 3–5 min; minimum count setting for burst absorption |
| **Private deployment** | ✅ Internal LB (private VIP, VNet-scoped) | ✅ Private-only v2 (GA; requires `EnableApplicationGatewayNetworkIsolation` feature flag) |
| **Pricing model** | Per rule/hour + data processing charge | Fixed $/hr (Standard_v2: $0.246/hr [VERIFY]) + capacity units/hr ($0.008/CU [VERIFY]) |
| **Typical use** | High-throughput TCP/UDP; NVA HA; SQL AG listeners; non-HTTP workloads | Web apps, microservices, AKS ingress, API gateways requiring L7 logic |

> ⚠️ **Key behavioral difference:** Load Balancer is pass-through — the backend sees the real client IP. Application Gateway is a terminating proxy — the backend sees the gateway's IP (use `X-Forwarded-For` header or Proxy Protocol to recover client IP).

---

### Application Gateway vs Azure Front Door

| Dimension | Application Gateway (v2) | Azure Front Door (Standard/Premium) |
|---|---|---|
| **Layer** | L7 (HTTP/HTTPS); terminating proxy | L7 (HTTP/HTTPS); terminating proxy at edge PoP |
| **Scope** | Regional only | Global — 118+ PoPs, 100+ metro areas |
| **WAF tier** | WAF_v2: OWASP CRS 3.2 / DRS 2.x; per-site and per-URI scope | Standard: custom rules only; Premium: DRS 2.1+ + Bot Manager 1.1; per-domain scope |
| **CDN / caching** | ❌ No caching capability | ✅ GET caching; `Cache-Control`/`Expires` TTL up to 366 days; 8 MB chunking; gzip/Brotli compression |
| **TLS offload** | ✅ At regional gateway; optional end-to-end TLS to backend | ✅ At nearest edge PoP; optional end-to-end TLS to origin |
| **TLS minimum** | TLS 1.2 (as of Aug 31, 2025) [VERIFY] | TLS 1.2 (TLS 1.0/1.1 not supported) |
| **mTLS** | ✅ Client cert validation (strict) or passthrough | ❌ No client certificate authentication |
| **Custom routing rules** | URL path maps, multi-site listeners, header/URL rewrite (v2), redirect rules | Rules engine: match conditions + actions; regex; server variables; can override origin group per request |
| **Session affinity** | Cookie-based (`ApplicationGatewayAffinity`) | Cookie-based (`ASLBSA` / `ASLBSACORS`) |
| **Routing methods** | Path-based, host-based (static config) | Latency (default), Priority, Weighted (1–1000), Session Affinity |
| **Latency** | Regional round-trip from client | Split TCP terminates at nearest PoP; pre-established long-lived connections to origin over Microsoft WAN reduce RTT |
| **Private origins** | ✅ Backend can be internal IP/FQDN reachable via VNet/VPN/ExpressRoute | ✅ Premium only: Private Link to App Service, Blob, ILB, API Management, App Gateway, Container Apps |
| **Private ingress** | ✅ Private-only deployment (no public IP) | ❌ Always internet-facing (public ingress) |
| **Autoscaling** | 0–125 instances; 3–5 min scale-out | Fully managed; no instance concept |
| **Pricing** | ~$0.246/hr + ~$0.008/CU (Standard_v2) [VERIFY] | ~$35/mo base (Standard) or ~$330/mo base (Premium) [VERIFY] + per-request/egress fees |
| **Typical use** | Regional WAF enforcement; AKS ingress; mTLS APIs; multi-site regional routing | Global multi-region web apps; CDN; edge WAF; blue/green deployments; origin lockdown |

> ⚠️ **Overlap caveat:** Both services can perform TLS offload, URL routing, and WAF at L7. The critical distinction is **scope** (regional vs. global), **caching** (Front Door only), and **mTLS** (App Gateway only). For global-to-regional patterns, chain them: Front Door (global) → App Gateway (regional).
>
> ⚠️ **WAF rule set version gap:** App Gateway WAF_v2 runs OWASP CRS 3.2 or DRS; Front Door Standard runs custom rules only — **no managed OWASP rulesets on Front Door Standard**. If managed rules are required at the global edge, Front Door Premium is mandatory.

---

### Azure Front Door vs Traffic Manager

| Dimension | Azure Front Door (Standard/Premium) | Traffic Manager |
|---|---|---|
| **Scope** | Global — 118+ PoPs | Global — DNS-only; no PoP network |
| **Protocol** | HTTP/HTTPS only | Any protocol (DNS-level; protocol-agnostic) |
| **Data-plane proxy** | ✅ Full proxy — terminates and re-originates connections | ❌ None — DNS CNAME response; client connects directly to endpoint |
| **Routing methods** | Latency (default), Priority, Weighted, Session Affinity | Priority, Weighted, Performance, Geographic, Multivalue, Subnet |
| **Health probes** | HTTP/HTTPS (GET or HEAD) from every active PoP; sliding window (SampleSize / SuccessfulSamplesRequired) | HTTP, HTTPS, or TCP; configurable interval (standard 30 s, fast 10 s [VERIFY]) and failure tolerance |
| **Failover speed** | Sub-minute — health probe failures detected independently at each PoP | TTL-dependent (default TTL 300 s; minimum 0 s [VERIFY]); fast probe reduces detection to ~10 s but DNS caching still delays client switchover |
| **Anycast / edge IP** | Standard/Premium: unicast PoP IPs via Traffic Manager DNS; Classic: anycast | None — DNS CNAME; no edge IP |
| **TLS offload** | ✅ At nearest PoP; managed cert auto-rotation | ❌ Client connects directly to origin for TLS handshake |
| **CDN / caching** | ✅ Full CDN (GET caching, compression, chunking) | ❌ None |
| **WAF** | ✅ Custom rules (Standard); managed DRS + Bot Manager (Premium) | ❌ None |
| **Session affinity** | ✅ Cookie-based at edge | ❌ Not supported — DNS-level only; no client tracking |
| **Private origins** | ✅ Premium: Private Link to origin (7,200 RPS limit [VERIFY]) | ❌ Public endpoints only |
| **Apex domain** | ✅ Supported via CNAME-alias workaround | ⚠️ CNAME cannot be set at zone apex — requires Azure DNS Alias record workaround |
| **Base cost** | ~$35–$330/mo base fee [VERIFY] + usage | ❌ No base fee — per DNS query + per probe |
| **Typical use** | Global web apps, APIs, CDN, edge WAF, zero-trust origin ingress | Non-HTTP global routing; cost-sensitive DNS failover; hybrid/multi-cloud endpoints; geographic compliance |

> ⚠️ **Do not place Traffic Manager *behind* Front Door.** Traffic Manager must be placed *in front of* Front Door if used together (e.g., mission-critical failover to alternate CDN provider). The reverse topology causes routing loops.
>
> ⚠️ **Failover speed comparison:** Front Door failover is near-real-time (independent per-PoP detection). Traffic Manager failover is limited by DNS TTL — a client with a cached DNS response continues routing to the unhealthy endpoint until TTL expires, regardless of probe frequency.

---

## Common patterns

### Pattern 1 — Global + Regional L7 with layered WAF: Front Door → Application Gateway

**Use case:** Global web application requiring edge CDN/WAF + regional deep-inspection WAF + mTLS or complex URL routing.

```
Client → Front Door Premium (global edge WAF, DRS 2.1+ + Bot Manager, CDN, TLS offload at PoP)
       → Private Link (optional; eliminates public origin IP)
       → Application Gateway WAF_v2 (regional WAF, URL path routing, mTLS, cookie affinity)
       → Backend pool (VMs / VMSS / App Service / AKS via AGIC)
```

**Notes:**
- Lock App Gateway to accept traffic only from the `AzureFrontDoor.Backend` service tag to prevent Front Door bypass.
- Front Door provides edge acceleration + global failover. App Gateway provides regional routing intelligence and mTLS enforcement.
- Two WAF layers: Front Door blocks globally-known threats at edge; App Gateway WAF provides per-site or per-path fine-grained rules.
- Cost: Front Door Premium base (~$330/mo [VERIFY]) + App Gateway WAF_v2 capacity units.

---

### Pattern 2 — Global DNS failover + Regional L7: Traffic Manager → Application Gateway

**Use case:** Multi-region active/passive failover for HTTP/HTTPS where Front Door pricing is prohibitive, or where non-HTTP protocols also need routing through the same global tier.

```
Client → Traffic Manager (Priority routing; health probe to App GW frontend; failover DNS TTL-bound)
       → Application Gateway WAF_v2 Region A (primary)
       → Application Gateway WAF_v2 Region B (failover)
```

**Notes:**
- Traffic Manager adds no latency post-DNS-resolution; failover speed governed by TTL + probe interval.
- Use fast probing (10 s [VERIFY]) and low TTL (e.g., 30–60 s) if SLA requires fast failover — but expect more DNS query billing.
- Does not provide CDN caching or edge TLS acceleration. If those are needed, upgrade to Front Door.
- Geographic or Performance routing method can replace Priority for active/active patterns.

---

### Pattern 3 — Internal + External L7 multi-tier: Load Balancer + Application Gateway

**Use case:** Multi-tier application with a public-facing Application Gateway tier and an internal Load Balancer tier for backend service distribution.

```
Internet → Application Gateway WAF_v2 (public; TLS termination; WAF; URL routing)
         → Standard Internal Load Balancer (private VIP; distributes across backend VMs/VMSS)
         → Backend VMs / VMSS
```

**Notes:**
- Application Gateway handles L7 concerns (TLS, WAF, routing) and presents a single public IP.
- Internal LB distributes L4 traffic across backend pool within the VNet — no additional public exposure.
- Internal LB health probes (TCP/HTTP/HTTPS) are independent from App Gateway health probes — configure both.
- Suitable for workloads requiring both L7 inspection and raw L4 backend distribution.

---

### Pattern 4 — Zero public origin IP: Front Door Premium → Private Link → Origin

**Use case:** Eliminate public IP exposure on origin services entirely; all ingress enters via Front Door edge.

```
Client → Front Door Premium (WAF; DRS 2.1+ + Bot Manager; CDN; TLS offload)
       → Private Link (Front Door-managed VNet; customer approves private endpoint)
       → Internal Load Balancer / App Service / API Management / Application Gateway (private)
```

**Notes:**
- Origin never receives traffic from the public internet — only from Front Door's private endpoint.
- Supported origin types: App Service, Blob Storage, Internal LB (incl. AKS/ARO), API Management, Application Gateway, Container Apps, Storage Static Website.
- Front Door Premium required (Private Link not available on Standard).
- Rate limit: 7,200 RPS per regional cluster per profile [VERIFY] — add Private Link origins in multiple regions if higher throughput is needed.
- Customer must approve the private endpoint connection before traffic flows.

---

## Limits & SKU summary

> All values marked [VERIFY] — cross-check with [Azure subscription and service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits) before architecture decisions.

| Service | SKU | Max rules / routes | Max backends | Throughput / RPS | SLA | Notes |
|---|---|---|---|---|---|---|
| **Azure Load Balancer** | Standard | Unlimited rules (per-frontend/port combinations) | Single VNet scope | Millions of flows; line-rate [VERIFY] | 99.99% [VERIFY] | 64,000 SNAT ports per public frontend IP [VERIFY] |
| **Azure Load Balancer** | Standard — Global tier | N/A | Regional Standard LBs only | Bounded by regional LB capacity | — | 5 s health check interval to regional LBs; 9 home regions [VERIFY] |
| **Azure Load Balancer** | Gateway | HA ports only (All/0) | Up to 2 backend pools per rule; 2 tunnel interfaces per pool | NVA-dependent | — | VXLAN encap; MTU ≥ 1550 recommended [VERIFY] |
| **Application Gateway** | Standard_v2 | 400 routing rules [VERIFY] | 100 pools × 1,200 backends/pool [VERIFY] | 62,500 CPS [VERIFY]; ~500 Mbps/instance [VERIFY] | 99.95% [VERIFY] | 100 listeners [VERIFY]; autoscale 0–125 instances; /24 subnet recommended |
| **Application Gateway** | WAF_v2 | 400 routing rules [VERIFY] | 100 pools × 1,200 backends/pool [VERIFY] | 62,500 CPS [VERIFY] | 99.95% [VERIFY] | Same as Standard_v2 + WAF; WAF does NOT inspect TCP/TLS listener traffic |
| **Application Gateway** | Basic *(preview)* | 5 rules [VERIFY] | 5 pools × 5 backends [VERIFY] | 200 CPS [VERIFY] | 99.9% [VERIFY] | No AGIC, no URL rewrite, no mTLS, no Private Link |
| **Azure Front Door** | Standard | 5,000 composite routes (domains × paths + rule overrides) | Unlimited origins | Per-PoP capacity | — | ~$35/mo base [VERIFY]; custom WAF rules only; no managed rulesets |
| **Azure Front Door** | Premium | 5,000 composite routes | Unlimited origins; Private Link: 7,200 RPS/regional cluster/profile [VERIFY] | Per-PoP capacity | — | ~$330/mo base [VERIFY]; DRS 2.1+ + Bot Manager; Private Link origins |
| **Traffic Manager** | N/A (consumption) | Unlimited endpoints; 1 Web App per region per profile [VERIFY] | Azure / External / Nested | N/A (DNS only; no data plane) | — | Default TTL 300 s; fast probe 10 s [VERIFY]; Priority values 1–1000 [VERIFY]; Weight 1–1000 [VERIFY] |
| **WAF (App GW)** | WAF_v2 | 100 custom rules/policy [VERIFY] | Inherits App GW limits | Inherits App GW limits | Inherits App GW SLA | CRS 3.0/3.1 EOL 2027-02-26; CRS 2.2.9 EOL March 2025 |
| **WAF (Front Door)** | Standard | 100 custom rules/policy [VERIFY] | — | — | — | Custom rules only; no managed rulesets |
| **WAF (Front Door)** | Premium | 100 custom rules/policy [VERIFY] | — | — | — | DRS 2.1+; Bot Manager 1.1; JS Challenge; CAPTCHA; Security Copilot |

---

## Related pages

- [[services/load-balancer]] — [Azure Load Balancer](../services/load-balancer.md): L4 TCP/UDP; Standard, Gateway, Global tier; SNAT; HA ports; Gateway LB for NVA chaining
- [[services/application-gateway]] — [Application Gateway](../services/application-gateway.md): L7 regional reverse proxy; URL routing; mTLS; AGIC; WAF_v2; private-only deployment
- [[services/front-door]] — [Azure Front Door](../services/front-door.md): Global CDN + L7 ADC; 118+ PoPs; split TCP; WAF; Private Link origins; Classic retirement Mar 31, 2027
- [[services/traffic-manager]] — [Traffic Manager](../services/traffic-manager.md): DNS-based global LB; 6 routing methods; protocol-agnostic; no proxy; nested profiles
- [[services/web-application-firewall]] — [Web Application Firewall](../services/web-application-firewall.md): WAF Policy resource; OWASP CRS / DRS; custom rules; Bot Manager; anomaly scoring; attach to App GW or Front Door
- [[decisions/choose-load-balancer]] — [Choose a load balancing solution](choose-load-balancer.md): Related stub — merge or link when compiled
- [[services/private-link]] — [Private Link](../services/private-link.md): Underlying technology for Front Door Premium Private Link origins; Internal LB as Private Link service origin
- [[services/ddos-protection]] — [DDoS Protection](../services/ddos-protection.md): L3/L4 volumetric DDoS for public IPs; Front Door provides built-in L3/4 DDoS + L7 via WAF; Standard DDoS adds SLA guarantee
- [[services/nat-gateway]] — [NAT Gateway](../services/nat-gateway.md): Preferred outbound SNAT for Load Balancer backends; supersedes LB outbound rules for production scale

---

## Source articles

- [Azure Load Balancer](../services/load-balancer.md) — compiled 2025-01-30 from 94 source articles
- [Application Gateway](../services/application-gateway.md) — compiled 2025-07-15 from 126 source articles
- [Azure Front Door](../services/front-door.md) — compiled 2026-04-09 from 102 source articles
- [Traffic Manager](../services/traffic-manager.md) — compiled 2025-07-31 from 44 source articles
- [Web Application Firewall](../services/web-application-firewall.md) — compiled 2026-04-10 from 77 source articles
- [What is load balancing and content delivery?](../../raw/articles/networking/load-balancer-content-delivery/load-balancing-content-delivery-overview.md) — Azure Docs overview article, synced 2025-06-24