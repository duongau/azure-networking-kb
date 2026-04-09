# Azure Application Gateway

> **Compiled:** 2025-07-15 | **Source articles:** 126 (main) + 50 (for-containers/) | **Status:** current

## What it is

Azure Application Gateway is a **managed Layer 7 (OSI) reverse proxy and web traffic load balancer** that makes routing decisions based on HTTP request attributes — URL paths, host headers, query strings — rather than purely IP address and port. It terminates TLS at the gateway, inspects and rewrites HTTP traffic, and forwards requests to backend pools of VMs, scale sets, App Service, Container Apps, or on-premises servers. It also extends to Layer 4 (TCP/TLS proxy, currently in public preview on v2). Application Gateway is regional (not global); combine it with Azure Front Door or Traffic Manager for multi-region routing.

## Key capabilities

| Capability | Details |
|---|---|
| **SSL/TLS termination** | Terminates TLS at the gateway (offloads crypto from backends). Supports end-to-end TLS by re-encrypting to backend. TLS 1.2+ required as of August 31, 2025. [VERIFY] |
| **URL-based routing** | Routes requests to different backend pools by URL path (`/images/*` → pool A, `/video/*` → pool B). |
| **Multiple-site hosting** | Route 100+ distinct hostnames/domains to separate backend pools on a single gateway. Up to 5 hostnames per multi-site listener; wildcards supported. |
| **HTTP redirection** | Global or path-scoped redirect; port-to-port (HTTP→HTTPS); redirect to external sites. |
| **Cookie-based session affinity** | Gateway-managed affinity cookie keeps a user session on the same backend server. |
| **WebSocket & HTTP/2** | Native support; always on; no per-listener toggle. HTTP/2 is frontend-only — backend always uses HTTP/1.1. |
| **Header & URL rewrite** | Add, remove, or update request/response headers and URL path/query string. Supports condition-based rewrites. v2 SKU only. |
| **Custom error pages** | Custom branding for gateway-generated error pages (not backend errors). |
| **Connection draining** | Graceful removal of backend instances; existing connections allowed to complete within a configurable timeout. |
| **Health probes** | Default probe (auto-configured) + custom probes (interval, path, thresholds, status codes, response body match). |
| **Web Application Firewall (WAF)** | OWASP CRS 3.1 (WAF_v2 only), 3.0, and 2.2.9. Detection and Prevention modes. Custom rules, geo-filtering, bot protection. |
| **Autoscaling** | v2 only. Scale 0–125 instances dynamically. Scale-out takes 3–5 minutes. |
| **Zone redundancy** | v2 only. Spans multiple Availability Zones by default where AZs are supported. |
| **Static VIP** | v2 only. Public IP does not change for the gateway lifetime, even after restart. |
| **Key Vault integration** | v2 only. Attach TLS certificates from Azure Key Vault to listeners; automatic certificate rotation. |
| **Mutual authentication (mTLS)** | v2 only. Two modes: strict (gateway validates client cert) and passthrough (backend validates). OCSP revocation check supported. Max 100 trusted client CA chains/SSL profile; 200 total per gateway. [VERIFY] |
| **Private Link** | v2 only. Private endpoint access to the Application Gateway from other VNets/subscriptions. |
| **Private-only deployment** | v2 only. GA (opt-in required). No public IP required; deny-all outbound NSG supported; custom routes (0.0.0.0/0) allowed. |
| **AKS Ingress (AGIC)** | v2 only. Application Gateway Ingress Controller runs as AKS pod, translates Kubernetes Ingress resources to Application Gateway config. Supported via Helm or AKS add-on. |
| **TCP/TLS Layer 4 proxy** | **Public preview.** Standard_v2 and WAF_v2 only. Same gateway endpoint serves both L7 (HTTP/S) and L4 (TCP/TLS) traffic. Not inspected by WAF. |
| **IPv6** | Dual-stack frontend supported on v2. |
| **Proxy Protocol** | Pass client connection info to backends that support PROXY protocol header. |
| **Server-sent events (SSE)** | Supported natively (no special config). |
| **Application Gateway for Containers** | Separate product (not the same resource). Next-gen Kubernetes-native ingress using ALB Controller. See `for-containers/` articles. |

## When to use it

- You need **Layer 7 routing** by URL path, hostname, query string, or HTTP header — e.g., microservices split behind a single public IP.
- You want **TLS termination** centralized at the gateway, with optional end-to-end TLS to backends.
- You need **WAF** protection (OWASP rules, bot management, geo-filtering) co-located with your load balancer.
- You're deploying workloads to **AKS and want a managed L7 ingress** without a separate load balancer hop (AGIC).
- You want **multi-site** (multiple domains/hostnames) served from a single gateway with per-site backend pools.
- You need **autoscaling** L7 load balancer that scales to 0 at idle (consumption billing).
- You need **mTLS** at the gateway (IoT, API consumers requiring client certificate authentication).
- You need an **internal-only** (private) application gateway with no public IP (private-only deployment).

## When NOT to use it

| Anti-pattern | Better alternative |
|---|---|
| DNS-based global routing across regions | [Azure Traffic Manager](../services/load-balancer.md) or [Azure Front Door](../decisions/choose-load-balancer.md) |
| Global L7 acceleration + CDN + WAF at the edge | **Azure Front Door** |
| Transport layer (L4) TCP/UDP load balancing at high throughput and scale | **Azure Load Balancer** (pass-through, not terminating) |
| Ultra-low latency, millions of simultaneous TCP/UDP flows | **Azure Load Balancer** |
| You only need L4 TCP proxy — do not need HTTP features | **Azure Load Balancer** (or App Gateway TCP/TLS proxy if you want a single endpoint) |
| Global multi-region active-active | Combine App Gateway (regional) with Front Door (global) |
| Large-scale Kubernetes ingress with advanced traffic splitting, header-based routing per AKS spec | **Application Gateway for Containers** (next-gen) |
| FIPS 140-2 validated cryptography | FIPS mode not currently supported on v2 [VERIFY] |

## SKUs and tiers

> **⚠️ V1 retirement:** Application Gateway V1 (Standard, WAF) is **retired April 28, 2026**. No new V1 deployments since September 1, 2024. Migrate to v2 immediately.

### v2 SKUs (current — use these)

| SKU | Use case | SLA | Max CPS | Max listeners | Max backend pools | Max backends/pool | Max rules | Notes |
|---|---|---|---|---|---|---|---|---|
| **Basic** (preview) | Dev/test, low-traffic, simple routing | 99.9% [VERIFY] | 200 [VERIFY] | 5 | 5 | 5 | 5 | No AGIC, no URL rewrite, no mTLS, no Private Link, no TCP/TLS proxy. Requires feature registration. |
| **Standard_v2** | Production web workloads | 99.95% [VERIFY] | 62,500 [VERIFY] | 100 | 100 | 1,200 | 400 | Full feature set. Autoscaling 0–125 instances. |
| **WAF_v2** | Production + OWASP WAF | 99.95% [VERIFY] | 62,500 [VERIFY] | 100 | 100 | 1,200 | 400 | Same as Standard_v2 + WAF (CRS 3.1/3.0/2.2.9). WAF does NOT inspect TCP/TLS listener traffic. |

### v1 SKUs (legacy — do not deploy)

| SKU | Sizes | Notes |
|---|---|---|
| **Standard (v1)** | Small, Medium, Large | Retiring April 28, 2026. Up to 32 instances. No autoscaling, no zone redundancy, no static VIP. |
| **WAF (v1)** | Small, Medium, Large | Same retirement timeline. WAF CRS 3.0, 2.2.9 (no CRS 3.1). |

**v1 throughput (SSL offload enabled, approximate):** [VERIFY]

| Page size | Small | Medium | Large |
|---|---|---|---|
| 6 KB | 7.5 Mbps | 13 Mbps | 50 Mbps |
| 100 KB | 35 Mbps | 100 Mbps | 200 Mbps |

### Feature comparison: v1 vs v2

| Feature | v1 | v2 |
|---|---|---|
| Autoscaling | ❌ | ✅ |
| Zone redundancy | ❌ | ✅ |
| Static VIP | ❌ | ✅ |
| Key Vault integration | ❌ | ✅ |
| Header/URL rewrite | ❌ | ✅ |
| mTLS | ❌ | ✅ |
| Private Link | ❌ | ✅ |
| AKS Ingress (AGIC) | ❌ | ✅ |
| WAF custom rules | ❌ | ✅ |
| TCP/TLS Layer 4 proxy | ❌ | ✅ (preview) |
| URL-based routing | ✅ | ✅ |
| Multiple-site hosting | ✅ | ✅ |
| TLS termination / end-to-end TLS | ✅ | ✅ |
| Session affinity | ✅ | ✅ |
| WebSocket / HTTP/2 | ✅ | ✅ |
| Connection draining | ✅ | ✅ |
| Custom error pages | ✅ | ✅ |
| WAF (OWASP) | ✅ | ✅ |
| DHE ciphers | ✅ | ❌ |
| Path-based rule URL encoding | ✅ | ❌ (v2 decodes before routing) |

## Service limits

> All limits marked [VERIFY] — cross-check with [Azure subscription service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-application-gateway-limits) before relying on these for architecture decisions.

### Scaling

| Limit | v1 | v2 (Standard_v2 / WAF_v2) | Notes |
|---|---|---|---|
| Max instances (autoscale) | N/A | 125 [VERIFY] | 0 minimum = no reserved capacity |
| Max instances (manual) | 32 [VERIFY] | 125 [VERIFY] | |
| Scale-out time | N/A | 3–5 minutes | New instances take time to be ready |
| Scale-in drain | N/A | 5 minutes | Existing connections allowed to complete |

### Capacity unit (v2 billing unit)

| Parameter | Value per CU |
|---|---|
| Persistent connections | 2,500 [VERIFY] |
| Throughput | 1 GB/hr = 2.22 Mbps [VERIFY] |
| Compute unit | 1 [VERIFY] |
| CUs per instance | 10 minimum [VERIFY] |

**Per-instance capacity (Standard_v2):** 10 CUs, 25,000 persistent connections, 500 Mbps throughput [VERIFY]

**Compute unit capacity:** Standard_v2 ≈ 50 TLS connections/sec (RSA 2048-bit) per CU; WAF_v2 ≈ 10 concurrent req/sec per CU [VERIFY]

### Networking

| Limit | v1 | v2 |
|---|---|---|
| Recommended subnet size | /26 min | /24 recommended [VERIFY] |
| NSG inbound port range required | 65503–65534 | 65200–65535 (not required for private deployment) [VERIFY] |
| IPs consumed per instance | 1 | 1 |
| Additional IPs (private frontend) | +1 | +1 |
| Azure-reserved IPs per subnet | 5 | 5 |

### TLS / Certificates

| Limit | Value | Notes |
|---|---|---|
| Minimum TLS version (frontend) | TLS 1.2 | As of August 31, 2025 — TLS 1.0/1.1 support ended [VERIFY] |
| Backend TLS (v2) | TLS 1.3 preferred, TLS 1.2 fallback | v1: governed by TLS policy |
| Max trusted client CA chains per SSL profile | 100 [VERIFY] | mTLS strict mode |
| Max trusted client CA chains per gateway | 200 [VERIFY] | mTLS strict mode |
| Max file size per CA certificate upload | 25 KB [VERIFY] | mTLS |

### Listeners / Rules / Pools (Standard_v2 / WAF_v2)

| Limit | Value |
|---|---|
| Max listeners | 100 [VERIFY] |
| Max backend pools | 100 [VERIFY] |
| Max backends per pool | 1,200 [VERIFY] |
| Max routing rules | 400 [VERIFY] |
| Max hostnames per multi-site listener | 5 [VERIFY] |
| Max websites per gateway | 100+ [VERIFY] |

### Pricing (East US, illustration only — use Azure pricing page for actuals) [VERIFY]

| SKU | Fixed cost/hr | Capacity unit cost/hr |
|---|---|---|
| Standard_v2 | $0.246 | $0.008/CU |
| WAF_v2 | $0.443 | $0.0144/CU |

*A partial hour is billed as a full hour. Outbound data transfer billed at standard Azure bandwidth rates.*

## Architecture components

| Component | Role |
|---|---|
| **Frontend IP** | Public, private, or both. v2: static public IP only (or private-only). v1: dynamic public IP. |
| **Listeners** | Accept connections by IP + port + protocol + hostname. Types: Basic (single domain) or Multi-site (multiple hostnames). Protocols: HTTP, HTTPS, TLS (v2 preview), TCP (v2 preview). |
| **Request routing rules** | Bind listener → backend pool + HTTP settings. Types: Basic (all requests) or Path-based (URL path map). |
| **Backend pools** | Target VMs, VMSS, App Service, Container Apps, on-premises servers (via FQDN/IP over ExpressRoute/VPN), public IPs. |
| **HTTP settings** | Define backend protocol/port, connection draining, affinity, host header override, probe association. |
| **Health probes** | Default (auto) or custom (path, interval, thresholds, status codes). |
| **WAF policy** | Attached at gateway or per-listener/per-path. CRS rules + custom rules + exclusions. |
| **SSL profiles** | Group TLS policy + client auth config (mTLS). Associated per-listener. |
| **Rewrite rule sets** | Condition-based header/URL rewrites; attached to routing rules. |

## Key design decisions and gotchas

| Topic | Detail |
|---|---|
| **Don't mix v1 and v2 on same subnet** | Not supported. |
| **v2 requires /24 subnet for autoscaling** | /24 ensures room for 125 instances + private frontend IP + 5 Azure-reserved IPs. |
| **AGIC takes full ownership of the gateway** | AGIC overwrites all Application Gateway config not defined in Kubernetes Ingress resources. Back up config before enabling. Use Helm's `ProhibitedTargets` for shared gateways. |
| **HTTP/2 is frontend-only** | Backend connections always use HTTP/1.1. |
| **Cookie affinity domain scoping** | v2 does not append domain to the Set-Cookie header — subdomain clients cannot reuse the affinity cookie. [CONFLICT: v1 may behave differently — not explicitly stated in sources.] |
| **v2 path encoding** | v2 decodes URL paths before routing (`/abc%2Fdef` treated as `/abc/def`). v1 does not decode. |
| **WAF_v2 + chunked transfer** | Cannot disable request buffering in WAF_v2 (required for WAF inspection). Workaround: path rule + disabled WAF policy for affected URL. |
| **TCP/TLS proxy WAF gap** | WAF_v2 does not inspect traffic on TCP/TLS listeners — only L7 (HTTP/S) listeners. |
| **SNI behavior v2 vs v1** | v2: when no SNI header, returns cert from highest-priority HTTPS listener rule — NOT the basic listener cert. Configure an "SNI hole" to prevent leaking production certs on IP-only connections. |
| **Scale-out latency** | Autoscale takes 3–5 minutes. Set minimum instance count to absorb short traffic bursts without waiting for scale-out. |
| **Private deployment opt-in** | Feature flag `EnableApplicationGatewayNetworkIsolation` must be registered per subscription. GA but labeled "preview" in portal. |
| **FIPS mode** | Not supported on v2. [VERIFY] |
| **Microsoft Defender for Cloud** | Not integrated with v2 yet. [VERIFY] |

## Related services

- [Azure Load Balancer](../services/load-balancer.md) — L4 pass-through; use when you need TCP/UDP at scale without HTTP intelligence or when App Gateway's terminating proxy model is unwanted.
- [Azure Firewall](../services/azure-firewall.md) — Layer 4–7 stateful firewall for east-west and outbound traffic; App Gateway WAF covers web exploits, Azure Firewall covers network-level threats. Often deployed together.
- [Private Link](../services/private-link.md) — App Gateway v2 supports Private Link on its frontend, enabling private endpoint consumers from other VNets/subscriptions.
- [Azure DNS](../services/dns.md) — Use CNAME records pointing to the Application Gateway DNS name (the VIP DNS name never changes, even on v1). Do not A-record the public IP on v1 (dynamic).
- [DDoS Protection](../services/ddos-protection.md) — App Gateway WAF provides L7 DDoS mitigation; Azure DDoS Protection Standard covers L3/L4 volumetric attacks. Use both for full coverage.
- [Network Watcher](../services/network-watcher.md) — Diagnostics for App Gateway connections; NSG flow logs for the App Gateway subnet.
- [ExpressRoute](../services/expressroute.md) / [VPN Gateway](../services/vpn-gateway.md) — App Gateway can reach on-premises backends via these hybrid connectivity paths.
- **Azure Front Door** *(not yet in KB)* — Global L7 CDN + WAF + anycast. Combine with App Gateway for global-in, regional-out pattern.
- **Azure Web Application Firewall (WAF)** *(not yet in KB)* — WAF policy resource; can be associated with App Gateway WAF_v2 at gateway, listener, or path scope.
- **Application Gateway for Containers** *(not yet in KB)* — Next-gen Kubernetes-native ingress (ALB Controller); 50 source articles in `for-containers/` subdirectory.

## Source articles

Core articles read for this compilation:

- [What is Azure Application Gateway](../../raw/articles/application-gateway/overview.md)
- [Azure Application Gateway features](../../raw/articles/application-gateway/features.md)
- [What is Azure Application Gateway v2?](../../raw/articles/application-gateway/overview-v2.md)
- [How an application gateway works](../../raw/articles/application-gateway/how-application-gateway-works.md)
- [Application gateway components](../../raw/articles/application-gateway/application-gateway-components.md)
- [Understanding Pricing for Azure Application Gateway and WAF](../../raw/articles/application-gateway/understanding-pricing.md)
- [Scaling Application Gateway v2 and WAF v2](../../raw/articles/application-gateway/application-gateway-autoscaling-zone-redundant.md)
- [Application Gateway infrastructure configuration](../../raw/articles/application-gateway/configuration-infrastructure.md)
- [Overview of TLS termination and end-to-end TLS](../../raw/articles/application-gateway/ssl-overview.md)
- [Mutual authentication overview](../../raw/articles/application-gateway/mutual-authentication-overview.md)
- [Application Gateway TCP/TLS proxy overview](../../raw/articles/application-gateway/tcp-tls-proxy-overview.md)
- [Application Gateway Ingress Controller overview](../../raw/articles/application-gateway/ingress-controller-overview.md)
- [Private Application Gateway deployment](../../raw/articles/application-gateway/application-gateway-private-deployment.md)
- [Application Gateway high traffic support](../../raw/articles/application-gateway/high-traffic-support.md)
- [Migrate from Application Gateway V1 to V2 by April 28, 2026](../../raw/articles/application-gateway/v1-retirement.md)

Additional articles in scope (not individually read — informs coverage gaps):
126 files in `raw/articles/application-gateway/` + 50 files in `raw/articles/application-gateway/for-containers/`
```

---

## Updated `wiki/index.md` entry

The Application Gateway row should be updated to:

```
| Application Gateway | [application-gateway.md](services/application-gateway.md) | ✅ current | 2025-07-15 |
```

---

## Decision log → `.squad/decisions/inbox/atlas-application-gateway.md`

```markdown
# Atlas decision log — Application Gateway compilation
Date: 2025-07-15

## Decisions made

1. **Scope: for-containers excluded from primary page.**
   Application Gateway for Containers has 50 dedicated articles and is a separate Azure resource (ALB Controller, not Application Gateway v2). Treated as a related service with a stub note. Recommend a separate wiki page: `wiki/services/application-gateway-for-containers.md`.

2. **v1 limits marked [VERIFY].**
   v1 is retiring. Throughput figures from `features.md` are labeled "approximate" in the source. Flagged all v1 perf numbers as [VERIFY].

3. **Pricing figures marked [VERIFY].**
   Source (`understanding-pricing.md`) explicitly states prices are East US examples for illustration only, subject to change. All pricing rows tagged [VERIFY] with pointer to Azure pricing page.

4. **[CONFLICT] Cookie affinity subdomain behavior.**
   `overview-v2.md` states v2 does not append domain to session affinity Set-Cookie. Behavior on v1 is not explicitly described in available articles. Flagged as [CONFLICT] — needs verification against v1 documentation if still relevant pre-retirement.

5. **TCP/TLS proxy marked preview.**
   Source articles consistently label TCP/TLS Layer 4 proxy as "public preview." Will need status update when GA.

6. **Private-only deployment marked GA.**
   `application-gateway-private-deployment.md` states it is Generally Available despite being labeled "preview" in the portal. Compiled as GA with a note about the portal label discrepancy.

7. **Application Gateway for Containers stub.**
   50 articles in `for-containers/` not read. Recommend follow-up compilation task.

## Gaps requiring human input

- Exact service limits not confirmed against the Azure subscription limits reference page (link-only in source articles; table not scraped).
- Pricing for regions other than East US not compiled.
- For-containers compilation is outstanding.
- FIPS v2 support status: source says "currently not supported" with no roadmap signal.
- Microsoft Defender for Cloud integration: source says "not yet available" with no date.
