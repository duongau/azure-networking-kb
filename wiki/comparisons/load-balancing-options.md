# Azure Load Balancing Options — Decision Matrix

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Azure offers four managed load balancing services. Choosing the wrong one for your OSI layer or traffic scope is the most common architecture mistake in this space. This page forces the decision.

---

## At-a-glance comparison

| Dimension | Azure Load Balancer | Application Gateway | Azure Front Door | Traffic Manager |
|---|---|---|---|---|
| **OSI layer** | Layer 4 (TCP/UDP) | Layer 7 (HTTP/S) | Layer 7 (HTTP/S) | DNS (Application layer — no data plane) |
| **Scope** | Regional | Regional | Global (118+ PoPs) | Global (DNS only) |
| **Protocol support** | TCP, UDP, ICMP (limited) | HTTP, HTTPS, WebSocket, HTTP/2; TCP/TLS (preview) | HTTP, HTTPS, WebSocket, HTTP/2 | Any (DNS-level; protocol-agnostic) |
| **Connection model** | Pass-through (no termination) | Terminating reverse proxy | Terminating at edge PoP | No proxy — returns DNS response; client connects directly |
| **SSL/TLS termination** | ❌ No | ✅ Yes — offload or end-to-end TLS | ✅ Yes — at edge PoP | ❌ No |
| **WAF capability** | ❌ No | ✅ WAF_v2 only (OWASP CRS, DRS, bot protection) | ✅ Standard: custom rules; Premium: managed rules + bot | ❌ No |
| **Caching / CDN** | ❌ No | ❌ No | ✅ Yes — GET requests; up to 366-day TTL | ❌ No |
| **Health probes** | TCP / HTTP / HTTPS; source 168.63.129.16 | Default + custom (HTTP/HTTPS, path, thresholds) | HTTP/HTTPS GET/HEAD per PoP; sliding-window model | HTTP / HTTPS / TCP; configurable interval + tolerance |
| **Session persistence** | 2-tuple (client IP) or 3-tuple (client IP + proto) | Cookie-based affinity (gateway-managed) | Cookie-based (ASLBSA) | ❌ No — DNS-only |
| **URL/path-based routing** | ❌ No | ✅ URL path maps, multiple sites, host headers | ✅ Route match by host + path, rules engine | ❌ No |
| **Private / internal** | ✅ Yes — Internal LB with private frontend | ✅ Yes — private-only deployment (GA) | ❌ No — internet-facing only | ❌ No — public endpoints only |
| **SLA** | 99.99% [VERIFY] (Standard, ≥2 healthy backends) | 99.95% [VERIFY] (Standard_v2 / WAF_v2) | 99.99% [VERIFY] | 99.99% [VERIFY] |
| **Pricing model** | Hourly (rule count) + data processed | Hourly fixed + capacity units (CU) | Monthly base (~$35 Std / ~$330 Premium) [VERIFY] + requests + egress | Per DNS query + per probe [VERIFY] |
| **NVA transparency** | ✅ Gateway LB (VXLAN, chained) | ❌ N/A | ❌ N/A | ❌ N/A |

---

## Capability deep-dive

### Health probes

| Service | Protocols | Source | Behavior when all unhealthy |
|---|---|---|---|
| Load Balancer (Standard) | TCP, HTTP, HTTPS | 168.63.129.16 (`AzureLoadBalancer` tag) | Established TCP flows continue; new flows stop |
| Application Gateway | HTTP, HTTPS (custom) | Gateway's own IP | Backend pool marked unhealthy; custom error page served |
| Front Door | HTTP, HTTPS (per PoP) | `Edge Health Probe` user-agent | Fail-open — routes round-robin across all origins |
| Traffic Manager | HTTP, HTTPS, TCP | Traffic Manager probe IPs | Returns all endpoints if all degraded (except Geographic — no fallback) |

### Routing methods available

| Service | Methods |
|---|---|
| Load Balancer | 5-tuple hash (default), client IP (2-tuple), client IP + protocol (3-tuple) |
| Application Gateway | URL path-based, multi-site (hostname), path maps, redirect, rewrite |
| Front Door | Latency (default), Priority, Weighted (1–1000), Session Affinity |
| Traffic Manager | Priority, Weighted, Performance, Geographic, Multivalue, Subnet |

---

## When to use each service

### Azure Load Balancer
✅ Use when:
- You need L4 TCP/UDP load balancing — VMs, VMSS, containers at high throughput
- You need transparent NVA insertion (Gateway LB with VXLAN — no UDRs required)
- You need internal load balancing within a VNet (Internal LB)
- You are the origin for a Private Link Service
- You need cross-region failover via Global tier (geo-proximity to regional Standard LBs)

❌ Do NOT use when:
- You need HTTP path-based routing, host header inspection, or WAF → use **Application Gateway**
- You need global HTTP acceleration, CDN, or edge WAF → use **Front Door**
- You need outbound SNAT at scale → use **NAT Gateway** (preferred over LB outbound rules)

### Application Gateway
✅ Use when:
- You need Layer 7 HTTP/S routing (URL path, hostname, query string)
- You need WAF co-located with your regional load balancer (WAF_v2)
- You need TLS termination + optional end-to-end TLS
- You need cookie-based session affinity at the gateway
- You need AKS ingress (AGIC / Application Gateway for Containers)
- You need mTLS (IoT, API clients with client certificates)
- You need an internal-only (private frontend) L7 reverse proxy

❌ Do NOT use when:
- You need global HTTP routing, CDN caching, or edge WAF → use **Front Door**
- You need L4 TCP/UDP at high throughput → use **Load Balancer**
- You need active-active multi-region failover without additional services → combine with **Front Door**

### Azure Front Door
✅ Use when:
- You have a globally distributed HTTP/S application needing sub-20ms anycast edge termination
- You need CDN caching (static + dynamic) alongside global load balancing
- You need global WAF enforcement (managed rules on Premium, custom rules on Standard)
- You want Private Link origins (Premium) to eliminate public-facing origin IPs
- You need blue/green or canary deployments via weighted routing across origin groups
- You need SSL certificate lifecycle management at scale

❌ Do NOT use when:
- Your workload is regional-only with no global users → **Application Gateway** (lower cost, mTLS, private frontend)
- Your protocol is non-HTTP → **Traffic Manager** (DNS-based, any protocol)
- You need an internal/private application delivery service → Front Door is internet-only
- Cost of Premium profile (~$330/month [VERIFY]) is not justified for small workloads

### Traffic Manager
✅ Use when:
- You need DNS-based global routing for non-HTTP services (or services that can tolerate DNS caching delays)
- You need data-residency routing (Geographic method)
- You need subnet-specific routing (corporate vs. ISP traffic differentiation)
- You need multi-cloud or hybrid endpoint routing (Azure + External FQDNs/IPs)
- You need a simple active/passive DNS failover across regions at minimal cost

❌ Do NOT use when:
- You need HTTP routing, WAF, TLS offload, or caching → **Front Door** or **Application Gateway**
- You need sticky sessions → Traffic Manager has no session awareness; use App Gateway or Front Door
- You need private/internal routing → Traffic Manager only routes public internet-facing endpoints
- Failover must happen in <1 minute → DNS TTL caching may delay failover; reduce TTL (increases query cost)

---

## "Which one?" — Text flowchart

```
START: I need to distribute traffic to my application

├─ Is my traffic HTTP/HTTPS?
│   ├─ NO → Is it multi-region / global DNS routing?
│   │        ├─ YES → Traffic Manager (DNS-based, any protocol)
│   │        └─ NO  → Azure Load Balancer (L4 regional TCP/UDP)
│   │
│   └─ YES → Is it internet-facing globally (users worldwide)?
│             ├─ YES → Azure Front Door
│             │        (edge TLS, CDN, global WAF, Private Link origins)
│             │        └─ Also need regional WAF / mTLS / AKS ingress in same region?
│             │           └─ YES → Front Door (global) + App Gateway (regional) together
│             │
│             └─ NO → Single Azure region?
│                      └─ YES → Application Gateway (WAF_v2 / Standard_v2)
│                               - Path/host routing? ✅
│                               - WAF needed?        ✅ Use WAF_v2
│                               - Private-only?      ✅ Private-only deployment
│                               - AKS ingress?       ✅ AGIC or App GW for Containers

ALSO: Need transparent NVA in the data path?
└─ YES → Gateway Load Balancer (chained to Standard Public LB — no UDRs)

ALSO: Need outbound internet for VMs?
└─ YES → NAT Gateway (preferred) > LB outbound rules > instance PIP
```

---

## Combining services — common patterns

| Pattern | Services | Why |
|---|---|---|
| Global-to-regional L7 | Front Door → Application Gateway | FD handles global CDN + edge WAF; App GW handles regional WAF, mTLS, AKS ingress; FD Private Link origin locks down App GW from public internet |
| DNS failover + regional LB | Traffic Manager → Load Balancer (per region) | TM routes DNS to healthy region; LB distributes within region at L4 |
| DNS failover + regional L7 | Traffic Manager → Application Gateway (per region) | TM routes DNS; App GW handles L7 within each region; no edge CDN |
| Cross-region global L4 | Load Balancer (Global tier) → Load Balancer (Standard regional) | Geo-proximity routing to regional Standard LBs; static anycast IP; L4 pass-through |

---

## Service limits (key figures) [VERIFY all]

| Service | Key limit |
|---|---|
| Load Balancer | 100 backend instances (single VNet); 64,000 SNAT ports per public IP; 99.99% SLA (≥2 healthy backends) |
| Application Gateway v2 | 125 autoscale instances; 100 listeners; 100 backend pools; 1,200 backends/pool; 400 routing rules |
| Front Door | 5,000 composite routes per profile; 7,200 RPS per Private Link regional cluster per profile |
| Traffic Manager | 0–2,147,483,647 s DNS TTL; default 300 s; up to 8 custom health-check headers |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure Load Balancer](../services/load-balancer.md) | L4 capabilities, Gateway LB, Global LB, health probes, SNAT |
| [Application Gateway](../services/application-gateway.md) | L7 capabilities, WAF_v2, mTLS, SKUs, limits |
| [Azure Front Door](../services/front-door.md) | Global edge, CDN, WAF, Private Link origins, SKUs, billing |
| [Traffic Manager](../services/traffic-manager.md) | DNS routing methods, endpoint types, health monitoring |