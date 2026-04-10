# Application Gateway vs Azure Front Door

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Both are managed Layer 7 HTTP/S load balancers with WAF capabilities. The distinction is scope: Application Gateway is **regional** (operates inside one Azure region); Front Door is **global** (terminates connections at the nearest of 118+ edge PoPs worldwide). This is not an either/or choice — the two services are designed to be combined.

---

## Core comparison

| Dimension | Application Gateway (v2) | Azure Front Door (Standard / Premium) |
|---|---|---|
| **Deployment scope** | Regional — single Azure region | Global — 118+ PoPs across 100+ metro areas |
| **Connection model** | Terminating reverse proxy inside the VNet | Terminates at nearest edge PoP; pre-established connections to origin over Microsoft WAN |
| **TLS offload** | ✅ At gateway (regional) — offloads crypto from backends; end-to-end TLS optional | ✅ At edge PoP — TLS terminates at the edge closest to the user |
| **TLS version minimum** | TLS 1.2 (TLS 1.0/1.1 ended August 31, 2025 [VERIFY]) | TLS 1.2 (TLS 1.0/1.1 not supported) |
| **Minimum TLS policy** | Configurable — Predefined or Custom SSL policy | Predefined or Custom (Standard/Premium only) |
| **Protocols** | HTTP, HTTPS, WebSocket, HTTP/2; TCP/TLS proxy (preview) | HTTP, HTTPS, WebSocket, HTTP/2 |
| **WAF** | WAF_v2 SKU — OWASP CRS 3.x / DRS 2.x; per-site and per-URI WAF policies | Standard: custom rules only; Premium: managed rules (DRS 2.1+), bot protection, JS Challenge, CAPTCHA |
| **WAF scope** | Regional — inspects traffic entering the region | Global edge — inspects before traffic reaches any region |
| **Caching / CDN** | ❌ No caching | ✅ GET requests; TTL up to 366 days; Brotli + Gzip compression; 8 MB object chunking |
| **URL-based routing** | ✅ URL path maps, multiple-site hosting (up to 5 hostnames per multi-site listener), wildcards | ✅ Route matching by host + path; rules engine with regex and server variables |
| **URL rewrite / header rewrite** | ✅ v2 only — add/remove/update headers and URL path/query string | ✅ Rules engine actions — header modification, URL redirect, forwarding override |
| **Cookie-based session affinity** | ✅ Gateway-managed cookie (AGIC does not affect this) | ✅ Cookie-based (ASLBSA / ASLBSACORS) |
| **Multi-region failover** | ❌ Not built-in — regional only; combine with Front Door or Traffic Manager | ✅ Built-in — priority + weighted routing across origin groups + health probes per PoP |
| **Custom domains** | ✅ Supported; use CNAME to gateway DNS name (never A-record the public IP on v1) | ✅ Apex domain (Alias-CNAME), wildcard domains; first 100/month free |
| **mTLS (client certificate auth)** | ✅ v2 only — strict or passthrough; OCSP revocation; up to 100 trusted CA chains/SSL profile | ❌ Not natively supported |
| **Private frontend (no public IP)** | ✅ Private-only deployment (GA, opt-in feature flag) | ❌ Front Door is internet-facing only |
| **Private Link origins** | ❌ App Gateway is itself a Private Link origin target | ✅ Premium only — App Service, ILB, API Mgmt, App Gateway, Container Apps, Blob, Static Site |
| **AKS / Kubernetes ingress** | ✅ AGIC (Application Gateway Ingress Controller); App GW for Containers (next-gen) | ❌ Not a native Kubernetes ingress controller |
| **Autoscaling** | ✅ 0–125 instances; scale-out ~3–5 min | ✅ Automatic (managed, no instance concept exposed to customer) |
| **Zone redundancy** | ✅ v2 spans Availability Zones by default | ✅ Global PoP network inherently redundant |
| **Pricing model** | Hourly fixed + per capacity unit (CU) | Monthly base fee (~$35 Std / ~$330 Premium [VERIFY]) + per-request + per-egress-GB |
| **WAF pricing** | WAF_v2: ~$0.443/hr + $0.0144/CU [VERIFY] | WAF included in base fee for Premium; Standard: custom rules only |
| **SLA** | 99.95% [VERIFY] | 99.99% [VERIFY] |

---

## WAF feature comparison (App Gateway WAF_v2 vs Front Door Premium WAF)

| WAF Feature | App Gateway WAF_v2 | Front Door Standard WAF | Front Door Premium WAF |
|---|---|---|---|
| OWASP / DRS managed rules | ✅ (DRS 2.x, CRS 3.2, 3.1, 3.0) | ❌ | ✅ (DRS 2.1+) |
| Bot Manager | ✅ (1.0, 1.1) | ❌ | ✅ (1.1) |
| Custom match rules | ✅ | ✅ | ✅ |
| Rate limiting | ✅ (sliding window, 1 or 5 min) | ✅ (fixed window, 1 or 5 min) | ✅ (fixed window, 1 or 5 min) |
| Geo-filtering | ✅ | ✅ | ✅ |
| Per-site / per-URI WAF policy | ✅ (v2) | ❌ (per-profile) | ❌ (per-profile) |
| JS Challenge | ✅ (preview) | ❌ | ✅ |
| CAPTCHA | ❌ | ❌ | ✅ |
| HTTP DDoS Ruleset (adaptive) | ✅ (preview) | ❌ | ✅ (limited preview) |
| Inspection scope | Regional requests entering gateway | None (custom only) | Global edge before region |
| Anomaly scoring | ✅ | ✅ | ✅ |
| Security Copilot AI investigation | ✅ | ❌ | ✅ |

---

## Use Application Gateway when…

- Your workload is **in a single Azure region** with no global user base
- You need **WAF with per-site or per-URI policies** (e.g., different WAF rules for `/admin` vs `/api`)
- You need **mTLS** — clients present certificates; gateway validates (IoT, API consumers)
- You need an **internal / private-only** L7 load balancer (no public IP) — e.g., private APIs accessible only via ER/VPN
- You need **AKS ingress** via AGIC or Application Gateway for Containers
- Your backend is in AKS and you want Kubernetes-native ingress management
- You need **TCP/TLS Layer 4 proxy** on the same endpoint as HTTP (preview on Standard_v2/WAF_v2)
- You need **DHE cipher suites** (v1 only — v2 dropped DHE; Front Door also dropping DHE April 2026 [VERIFY])

---

## Use Azure Front Door when…

- Your application serves users **globally** and you want edge TLS termination closest to users
- You need **CDN caching** alongside load balancing — reducing origin load and improving latency for static + dynamic content
- You need **global WAF** (managed rules at the edge, before traffic reaches any region) — Premium for bot + DRS managed rules
- You need **multi-region active/active or active/passive** failover with automatic health-probe-driven routing
- You need **blue/green or canary deployments** via weighted origin routing globally
- You want to lock down origin servers so they only accept traffic from Front Door (**Private Link origin** on Premium)
- You need **SSL certificate lifecycle management at scale** — managed auto-rotating certs
- Your workload is globally distributed with no single primary region

---

## The "use both together" pattern

This is the recommended production pattern for globally distributed public web applications:

```
Internet
    │
    ▼
[Azure Front Door — global edge]
    - TLS termination at nearest PoP
    - CDN caching for static assets
    - WAF Premium (DRS + Bot Manager) — global L7 filter
    - Private Link origin → locks down App Gateway from public internet
    │
    ▼ (private path via Front Door-managed VNet)
[Application Gateway WAF_v2 — regional]
    - Regional TLS termination (end-to-end TLS option)
    - Per-site / per-URI WAF policies (finer granularity than Front Door)
    - mTLS for specific API consumers
    - AKS ingress for backend services
    │
    ▼
[Backend: VMs / AKS / App Service — private subnet]
```

**Why both?**
- Front Door absorbs global CDN, edge WAF, and anycast acceleration — it cannot do per-URI WAF policies, mTLS, or AKS ingress
- Application Gateway provides regional WAF with granular policies, mTLS, and Kubernetes integration — it cannot deliver global CDN or multi-region failover on its own
- Front Door's Private Link origin ensures App Gateway is **not reachable directly from the internet** — only via Front Door; this closes the "bypass Front Door" attack vector

**Critical rule:** Do NOT put Traffic Manager **behind** Front Door. Traffic Manager must go in **front of** Front Door if used together (for Front Door failover to alternate CDN/delivery platform).

---

## Key limits and gotchas

| Topic | Application Gateway | Azure Front Door |
|---|---|---|
| Subnet size | /24 recommended for v2 autoscale (125 instances + reserved IPs) | No subnet — global PaaS |
| Scale-out latency | 3–5 minutes for new instances | Transparent — managed globally |
| WAF on TCP/TLS listeners | ❌ WAF does NOT inspect TCP/TLS listener traffic | N/A (HTTP/S only) |
| HTTP/2 to backend | ❌ Frontend only; backend always HTTP/1.1 | HTTP/2 supported end-to-end |
| URL path encoding | v2 decodes URL paths before routing (`/abc%2Fdef` → `/abc/def`) | N/A |
| SNI hole risk (v2) | When no SNI, returns cert from highest-priority HTTPS listener — configure SNI fallback listener | N/A |
| Cookie affinity domain | v2 does not append domain to Set-Cookie — subdomains cannot reuse affinity cookie | Cookie includes `.azurefd.net` domain scope |
| Private origin lockdown | App Gateway can be origin; customer must configure IP restrictions or NSG to allow only Front Door service tag | Front Door → App GW via Private Link origin (Premium) — no public exposure needed |

---

## Pricing quick comparison [VERIFY all]

| Component | Application Gateway Standard_v2 | Application Gateway WAF_v2 | Front Door Standard | Front Door Premium |
|---|---|---|---|---|
| Base/fixed | ~$0.246/hr | ~$0.443/hr | ~$35/month | ~$330/month |
| Variable | $0.008/CU/hr | $0.0144/CU/hr | Per-request + egress by zone | Per-request + egress by zone |
| WAF rules | Included in WAF_v2 | Included | Custom only (free) | Managed + custom (included) |

---

## Source pages

| Source | Notes |
|---|---|
| [Application Gateway](../services/application-gateway.md) | v2 SKUs, WAF_v2, mTLS, AGIC, private deployment, limits, gotchas |
| [Azure Front Door](../services/front-door.md) | Global PoPs, CDN, WAF SKUs, Private Link origins, billing, routing methods |