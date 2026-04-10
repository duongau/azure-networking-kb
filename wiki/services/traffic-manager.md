# Azure Traffic Manager

> **Compiled:** 2025-07-31 | **Source articles:** 44 | **Status:** current

## What it is

Azure Traffic Manager is a **DNS-based, global traffic load balancer** that distributes client
requests to internet-facing service endpoints across Azure regions and beyond. It operates
exclusively at the **DNS layer (Layer 7 Application layer — but no data-plane proxy)**: it
returns a DNS response pointing clients to the best endpoint; clients then connect directly
to that endpoint. Traffic Manager never sees application traffic itself.

## Key capabilities

| Capability | Details |
|---|---|
| **6 routing methods** | Priority, Weighted, Performance, Geographic, Multivalue, Subnet |
| **Endpoint health monitoring** | HTTP, HTTPS, or TCP probes; configurable interval, timeout, and failure tolerance |
| **Automatic failover** | Removes degraded endpoints from DNS responses; re-adds when healthy |
| **Hybrid / multi-cloud endpoints** | Azure, External (on-prem or other cloud, IPv4/IPv6/FQDN), Nested profiles |
| **Nested profiles** | Combine multiple routing methods via parent/child profile hierarchy |
| **Real User Measurements (RUM)** | JavaScript snippet embeds in web pages; feeds actual end-user latency data to Performance routing decisions |
| **Traffic View** | Visual map of DNS resolver locations, query volumes, and representative latency; updated every 48 h using last 7 days of data |
| **Configurable DNS TTL** | 0 – 2,147,483,647 s [VERIFY]; default 300 s |
| **EDNS0 client subnet support** | Uses RFC 7871 client subnet hint for improved geo/performance/subnet routing accuracy |
| **Custom health-check headers** | Up to 8 `header:value` pairs per probe; enables multi-tenant health routing |
| **Expected status code ranges** | Up to 8 HTTP status code ranges can be defined as "healthy" |
| **Fast probing** | 10-second probe interval (billed differently from 30-second standard) [VERIFY] |
| **TLS requirement** | TLS 1.2+ required; TLS 1.0/1.1 support ended 2025-02-28 |

## When to use it

| Scenario | Recommended method |
|---|---|
| Active/passive failover across regions | **Priority** |
| Gradual blue/green or canary rollout | **Weighted** |
| Route users to lowest-latency region | **Performance** |
| Data sovereignty / content localization | **Geographic** |
| Client-side retry with multiple IPs in one DNS response | **Multivalue** (IPv4/IPv6 external only) |
| Route corporate office or ISP-specific traffic differently | **Subnet** |
| Burst-to-cloud / hybrid on-prem + Azure | External endpoints with Priority or Weighted |
| Complex multi-method routing | **Nested profiles** |
| Global DNS LB in front of regional Application Gateways | TM (global) → App GW (regional L7) |

## When NOT to use it

| Anti-pattern | Why / Alternative |
|---|---|
| Regional load balancing within a single region | Use **Azure Load Balancer** (L4) or **Application Gateway** (L7) |
| Sticky sessions / client affinity | TM has no client tracking (DNS-level only); use Application Gateway cookie affinity or Front Door session affinity |
| Private / internal DNS routing (RFC 1918) | TM only routes public internet-facing traffic; use Azure Private DNS + internal Load Balancer |
| TLS termination, WAF, URL rewriting | Use **Application Gateway** or **Azure Front Door** |
| Apex/naked domain (without workaround) | TM requires CNAME which cannot be set at zone apex; workaround: Azure DNS Alias record pointing to TM profile |
| Ultra-low-latency anycast routing with CDN integration | Consider **Azure Front Door** (anycast PoP network, integrated CDN/WAF) |
| Traffic from private networks or VPN users making private DNS queries | TM cannot route such traffic |

## SKUs and tiers

Traffic Manager has **no traditional SKU tiers** — it is a consumption-based service billed per:
- DNS queries answered [VERIFY pricing page for current rate]
- Health check probes (standard vs. fast probing billed differently) [VERIFY]
- Real User Measurements (per measurement sent) [VERIFY]
- Traffic View (per data point / query processed) [VERIFY]

No reserved capacity, no Basic/Standard/Premium tier distinction exists for the profile itself.

> **Web App endpoint constraint:** The downstream Web App endpoint must be **Standard tier or higher** in App Service Plans to be used with Traffic Manager. [VERIFY]

## Service limits

| Limit | Value | Notes |
|---|---|---|
| DNS TTL minimum | 0 seconds [VERIFY] | All queries reach TM name servers; no caching |
| DNS TTL maximum | 2,147,483,647 seconds [VERIFY] | RFC-1035 maximum |
| Default DNS TTL | 300 seconds | Configurable per profile |
| Probing interval (standard) | 30 seconds [VERIFY] | Default |
| Probing interval (fast) | 10 seconds [VERIFY] | Additional billing applies |
| Probe timeout (30 s interval) | 5–10 s; default 10 s [VERIFY] | Must be < probing interval |
| Probe timeout (10 s interval) | 5–9 s; default 9 s [VERIFY] | Must be < probing interval |
| Tolerated failures before degraded | 0–9; default 3 [VERIFY] | 0 = single failure marks endpoint unhealthy |
| Priority values | 1–1000 [VERIFY] | Lower = higher priority; no duplicate values allowed |
| Weighted values | 1–1000 [VERIFY] | Optional; default 1 if omitted |
| Custom health-check headers | Up to 8 `header:value` pairs [VERIFY] | Per profile or per endpoint |
| Expected status code ranges | Up to 8 ranges [VERIFY] | HTTP/HTTPS monitoring only |
| Web App endpoints per region per profile | 1 [VERIFY] | Workaround: configure Web App as External endpoint |
| TLS version minimum | TLS 1.2 | TLS 1.0/1.1 retired 2025-02-28 |
| Traffic View data window | Last 7 days | Updated every 48 h |
| Traffic View in Sovereign clouds | Retired 2025-03-15 | Available in Public cloud only |

> **Performance note:** DNS lookup latency is typically ~50 ms; results cached per TTL. Once DNS resolves, all subsequent application traffic bypasses Traffic Manager entirely.

## Routing methods — reference

| Method | Behavior | Key constraint |
|---|---|---|
| **Priority** | All traffic to highest-priority endpoint; failover down the list | Priority values 1–1000; no shared values |
| **Weighted** | Traffic split proportional to weight; random selection per DNS query | DNS caching can skew distribution with small resolver populations |
| **Performance** | Routes to endpoint with lowest latency per Azure Internet Latency Table | Uses recursive DNS resolver IP as proxy for client location |
| **Geographic** | Maps DNS query source to geographic region; deterministic per region | One region to one endpoint mapping; returns endpoint even if unhealthy (no fallback unless Nested); strongly recommend Nested child profiles |
| **Multivalue** | Returns all healthy endpoints in a single DNS response | External endpoints with IPv4/IPv6 addresses only |
| **Subnet** | Maps source IP CIDR ranges to specific endpoints | Define fallback endpoint for unmapped ranges or TM returns NODATA |

### Nested profiles — key mechanics

- A **child profile** is added as an endpoint to a **parent profile**
- `MinChildEndpoints` (default: 1): minimum healthy child endpoints before parent treats child as unavailable
- `MinChildEndpointsIPv4` / `MinChildEndpointsIPv6`: separate thresholds for Multivalue child profiles
- Use cases: combine Performance (global) + Weighted (regional canary), enforce per-region failover order with Priority inside Performance, apply per-endpoint monitoring settings via different child profile configs

## Endpoint types — reference

| Type | Target | Health check billing |
|---|---|---|
| **Azure** | PaaS cloud services, Web Apps (Standard+), Web App Slots, Public IP resources | Azure endpoint rate |
| **External** | IPv4/IPv6 addresses, FQDNs, on-prem or other-cloud services | External endpoint rate; billing continues even if underlying service stopped |
| **Nested** | Another Traffic Manager profile (child) | Per child profile's endpoint types |

**Mixing constraints:** Cannot combine external endpoints of different target types (FQDN vs. IP address), and cannot mix IP-address external endpoints with Azure endpoints in the same profile.

## Health monitoring — endpoint monitor status

| Profile status | Endpoint status | Monitor status | Traffic received? |
|---|---|---|---|
| Enabled | Enabled | **Online** | Yes |
| Enabled | Enabled | **Degraded** | No (unless all degraded — then all returned) |
| Enabled | Enabled | **CheckingEndpoint** | Yes (transitional state) |
| Enabled | Enabled | **Stopped** | No (App Service not running / child profile disabled) |
| Enabled | Enabled | **Not monitored** | Yes (health checks disabled) |
| Enabled | Disabled | **Disabled** | No |
| Disabled | Any | **Inactive** | No — NXDOMAIN returned |

**Failover recovery:** TM continuously probes unhealthy endpoints and reinstates them when healthy — no manual intervention required.

## Observability

| Feature | Details |
|---|---|
| **Azure Monitor metrics** | Query count per profile, query count per endpoint, endpoint health probe results |
| **Diagnostic logs** | DNS query logs, endpoint health logs |
| **Alerts** | Threshold/metric alerts via Azure Monitor |
| **Traffic View** | Geographic user-base map, latency heatmap, CSV export; public cloud only; 48 h refresh |
| **Real User Measurements (RUM)** | JavaScript/Visual Studio SDK; feeds actual latency measurements into Performance routing; billed per measurement [VERIFY] |

## DNS behavior — important caveats

- Traffic Manager is **not a proxy**: no data-plane footprint; zero added latency post-DNS-resolution
- **Naked domain / apex:** CNAME cannot be set at zone apex — use Azure DNS Alias records or HTTP redirect
- **Sticky sessions:** Not supported — TM has no visibility into client identity
- **DNS caching:** Client and resolver caching can delay failover by up to the configured TTL. For fast failover, reduce TTL (with the cost trade-off of more DNS queries)
- **Geographic routing accuracy:** Based on recursive DNS resolver IP; RFC 7871 EDNS0 client subnet used when supported by resolver

## Related services

- [Application Gateway](../services/application-gateway.md) — Regional L7 load balancer; combine with TM for global DNS routing → regional L7 routing pattern
- [Azure Load Balancer](../services/load-balancer.md) — Regional L4 load balancer; use inside regions behind TM-routed endpoints
- [Azure Front Door](../services/front-door.md) — Anycast global HTTP/S routing with CDN, WAF, session affinity; preferred over TM for web workloads requiring SSL offload or caching
- [Azure DNS](../services/dns.md) — Required for apex domain workaround via Alias records pointing to TM profiles

## Source articles

- [Overview](../../raw/articles/traffic-manager/traffic-manager-overview.md)
- [How Traffic Manager Works](../../raw/articles/traffic-manager/traffic-manager-how-it-works.md)
- [Traffic-Routing Methods](../../raw/articles/traffic-manager/traffic-manager-routing-methods.md)
- [Endpoint Types](../../raw/articles/traffic-manager/traffic-manager-endpoint-types.md)
- [Endpoint Monitoring](../../raw/articles/traffic-manager/traffic-manager-monitoring.md)
- [Nested Profiles](../../raw/articles/traffic-manager/traffic-manager-nested-profiles.md)
- [Performance Considerations](../../raw/articles/traffic-manager/traffic-manager-performance-considerations.md)
- [Real User Measurements Overview](../../raw/articles/traffic-manager/traffic-manager-rum-overview.md)
- [Traffic View Overview](../../raw/articles/traffic-manager/traffic-manager-traffic-view-overview.md)
- [FAQ](../../raw/articles/traffic-manager/traffic-manager-FAQs.md)
- [Load Balancing with Azure Services](../../raw/articles/traffic-manager/traffic-manager-load-balancing-azure.md)
- [Configure Geographic Routing](../../raw/articles/traffic-manager/traffic-manager-configure-geographic-routing-method.md)
- [Configure Multivalue Routing](../../raw/articles/traffic-manager/traffic-manager-configure-multivalue-routing-method.md)
- [Configure Performance Routing](../../raw/articles/traffic-manager/traffic-manager-configure-performance-routing-method.md)
- [Configure Priority Routing](../../raw/articles/traffic-manager/traffic-manager-configure-priority-routing-method.md)
- [Configure Subnet Routing](../../raw/articles/traffic-manager/traffic-manager-configure-subnet-routing-method.md)
- [Configure Weighted Routing](../../raw/articles/traffic-manager/traffic-manager-configure-weighted-routing-method.md)
- [Diagnostic Logs](../../raw/articles/traffic-manager/traffic-manager-diagnostic-logs.md)
- [Metrics and Alerts](../../raw/articles/traffic-manager/traffic-manager-metrics-alerts.md)
- [Manage Endpoints](../../raw/articles/traffic-manager/traffic-manager-manage-endpoints.md)
- [Manage Profiles](../../raw/articles/traffic-manager/traffic-manager-manage-profiles.md)
- [Geographic Regions Reference](../../raw/articles/traffic-manager/traffic-manager-geographic-regions.md)
- [DNS Record Types](../../raw/articles/traffic-manager/dns-record-types.md)
- [Point Internet Domain to Traffic Manager](../../raw/articles/traffic-manager/traffic-manager-point-internet-domain.md)
- [Testing Settings](../../raw/articles/traffic-manager/traffic-manager-testing-settings.md)
- [Troubleshooting Degraded Status](../../raw/articles/traffic-manager/traffic-manager-troubleshooting-degraded.md)
- [Use with App Service](../../raw/articles/traffic-manager/traffic-manager-use-azure-app-service.md)
- [Use with Application Gateway](../../raw/articles/traffic-manager/traffic-manager-use-with-application-gateway.md)
- [Subnet Override (CLI)](../../raw/articles/traffic-manager/traffic-manager-subnet-override-cli.md)
- [Subnet Override (PowerShell)](../../raw/articles/traffic-manager/traffic-manager-subnet-override-powershell.md)
- [RUM with Web Pages](../../raw/articles/traffic-manager/traffic-manager-create-rum-web-pages.md)
- [RUM with Visual Studio](../../raw/articles/traffic-manager/traffic-manager-create-rum-visual-studio.md)
- [PowerShell ARM](../../raw/articles/traffic-manager/traffic-manager-powershell-arm.md)
- *(+ 10 quickstart/tutorial articles)*
