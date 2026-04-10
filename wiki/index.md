# Azure Networking Knowledge Base — Index

> **Last compiled:** 2026-04-10 | **Atlas version:** — | **Coverage:** 23 / 23 services · 17 concepts · 10 comparisons · 8 patterns · 4 decision guides · 4 limits/tracking references · 23 source summaries

This is the entry point for the Azure Networking KB. All wiki pages are compiled by Atlas from source articles in `raw/`.

---

## Services

| Service | Wiki page | Status | Last compiled |
|---|---|---|---|
| Azure Virtual Network | [virtual-network.md](services/virtual-network.md) | ✅ current | 2025-07-31 |
| ExpressRoute | [expressroute.md](services/expressroute.md) | ✅ current | 2026-04-10 |
| VPN Gateway | [vpn-gateway.md](services/vpn-gateway.md) | ✅ current | 2025-11-25 |
| Azure Firewall | [azure-firewall.md](services/azure-firewall.md) | ✅ current | 2025-07-14 |
| Application Gateway | [application-gateway.md](services/application-gateway.md) | ✅ current | 2025-07-15 |
| Azure Load Balancer | [load-balancer.md](services/load-balancer.md) | ✅ current | 2026-04-10 |
| NAT Gateway | [nat-gateway.md](services/nat-gateway.md) | ✅ current | 2026-04-08 |
| Azure Bastion | [bastion.md](services/bastion.md) | ✅ current | 2026-04-10 |
| Private Link | [private-link.md](services/private-link.md) | ✅ current | 2025-07-30 |
| DDoS Protection | [ddos-protection.md](services/ddos-protection.md) | ✅ current | 2026-04-08 |
| Azure DNS | [dns.md](services/dns.md) | ✅ current | 2025-07-31 |
| Network Watcher | [network-watcher.md](services/network-watcher.md) | ✅ current | 2025-07-14 |
| Azure Front Door | [front-door.md](services/front-door.md) | ✅ current | 2026-04-09 |
| Traffic Manager | [traffic-manager.md](services/traffic-manager.md) | ✅ current | 2026-04-09 |
| Virtual WAN | [virtual-wan.md](services/virtual-wan.md) | ✅ current | 2026-04-10 |
| Azure Route Server | [route-server.md](services/route-server.md) | ✅ current | 2026-04-10 |
| Web Application Firewall | [web-application-firewall.md](services/web-application-firewall.md) | ✅ current | 2026-04-10 |
| Azure Firewall Manager | [firewall-manager.md](services/firewall-manager.md) | ✅ current | 2026-04-10 |
| Azure Virtual Network Manager | [virtual-network-manager.md](services/virtual-network-manager.md) | ✅ current | 2026-04-10 |
| Internet Peering | [internet-peering.md](services/internet-peering.md) | ✅ current | 2026-04-10 |
| Peering Service | [peering-service.md](services/peering-service.md) | ✅ current | 2026-04-10 |
| Network Function Manager | [network-function-manager.md](services/network-function-manager.md) | ✅ current | 2026-04-10 |

---

## Concepts

| Concept | Wiki page | Status |
|---|---|---|
| Hub-spoke topology | [hub-spoke-networking.md](concepts/hub-spoke-networking.md) | ✅ current |
| Hybrid connectivity | [hybrid-connectivity.md](concepts/hybrid-connectivity.md) | ✅ current |
| IP addressing and subnetting | [ip-addressing.md](concepts/ip-addressing.md) | ✅ current |
| Network security design | [network-security-design.md](concepts/network-security-design.md) | ✅ current |
| Routing | [routing.md](concepts/routing.md) | ✅ current |
| Private access to PaaS | [private-access-to-paas.md](concepts/private-access-to-paas.md) | ✅ current |
| Monitoring | [monitoring.md](concepts/monitoring.md) | ✅ current |
| Azure Networking Fundamentals | [azure-networking-fundamentals.md](concepts/azure-networking-fundamentals.md) | ✅ current |
| SNAT in Azure | [snat.md](concepts/snat.md) | ✅ current |
| BGP and dynamic routing | [bgp-dynamic-routing.md](concepts/bgp-dynamic-routing.md) | ✅ current |
| User-defined routes (UDRs) | [user-defined-routes.md](concepts/user-defined-routes.md) | ✅ current |
| Network Security Groups (NSGs) | [network-security-groups.md](concepts/network-security-groups.md) | ✅ current |
| VNet peering | [vnet-peering.md](concepts/vnet-peering.md) | ✅ current |
| DNS zones and records | [dns-zones-and-records.md](concepts/dns-zones-and-records.md) | ✅ current |
| Flow logs | [flow-logs.md](concepts/flow-logs.md) | ✅ current |
| Service endpoints | [service-endpoints.md](concepts/service-endpoints.md) | ✅ current |
| VNet encryption | [vnet-encryption.md](concepts/vnet-encryption.md) | ✅ current |

---

## Comparisons

Side-by-side decision matrices for choosing between Azure networking services.

| Comparison | Wiki page | Status |
|---|---|---|
| Load balancing options (L4 vs L7 vs global) | [load-balancing-options.md](comparisons/load-balancing-options.md) | ✅ current |
| VPN Gateway vs ExpressRoute | [vpn-gateway-vs-expressroute.md](comparisons/vpn-gateway-vs-expressroute.md) | ✅ current |
| Azure Firewall vs NSG | [firewall-vs-nsg.md](comparisons/firewall-vs-nsg.md) | ✅ current |
| Azure Firewall SKU comparison (Basic / Standard / Premium) | [firewall-sku-comparison.md](comparisons/firewall-sku-comparison.md) | ✅ current |
| Virtual WAN vs hub-spoke | [virtual-wan-vs-hub-spoke.md](comparisons/virtual-wan-vs-hub-spoke.md) | ✅ current |
| Private Endpoint vs Service Endpoint | [private-endpoints-vs-service-endpoints.md](comparisons/private-endpoints-vs-service-endpoints.md) | ✅ current |
| Application Gateway vs Azure Front Door | [app-gateway-vs-front-door.md](comparisons/app-gateway-vs-front-door.md) | ✅ current |
| Azure Front Door vs Traffic Manager | [front-door-vs-traffic-manager.md](comparisons/front-door-vs-traffic-manager.md) | ✅ current |
| DDoS IP Protection vs Network Protection | [ddos-ip-vs-network-protection.md](comparisons/ddos-ip-vs-network-protection.md) | ✅ current |
| Private DNS Resolver vs custom DNS | [private-dns-resolver-vs-custom-dns.md](comparisons/private-dns-resolver-vs-custom-dns.md) | ✅ current |

---

## Patterns

Deployment patterns with architecture diagrams and configuration notes.

| Pattern | Wiki page | Status |
|---|---|---|
| Hub-spoke with Azure Firewall | [hub-spoke-with-firewall.md](patterns/hub-spoke-with-firewall.md) | ✅ current |
| NAT Gateway in hub-spoke | [nat-gateway-hub-spoke.md](patterns/nat-gateway-hub-spoke.md) | ✅ current |
| Hybrid DNS resolution (Private Resolver) | [dns-hybrid-resolution.md](patterns/dns-hybrid-resolution.md) | ✅ current |
| ExpressRoute resiliency patterns | [expressroute-resiliency-patterns.md](patterns/expressroute-resiliency-patterns.md) | ✅ current |
| Multi-region active-active with Front Door | [multi-region-front-door.md](patterns/multi-region-front-door.md) | ✅ current |
| Zero Trust application delivery | [zero-trust-app-delivery.md](patterns/zero-trust-app-delivery.md) | ✅ current |
| Enterprise-scale hub-spoke with AVNM | [avnm-enterprise-scale.md](patterns/avnm-enterprise-scale.md) | ✅ current |
| Private AKS cluster networking | [private-aks-networking.md](patterns/private-aks-networking.md) | ✅ current |

---

## Decision guides

| Decision | Wiki page | Status |
|---|---|---|
| Choose a connectivity method | [connectivity-options.md](decisions/connectivity-options.md) | ✅ current |
| Choose a load balancing solution | [load-balancing-options.md](decisions/load-balancing-options.md) | ✅ current |
| Choose a firewall / security solution | [firewall-and-security-options.md](decisions/firewall-and-security-options.md) | ✅ current |
| Choose a private access pattern | [private-access-options.md](decisions/private-access-options.md) | ✅ current |

---

## Service limits and SKUs

| Article | Wiki page | Status |
|---|---|---|
| SKU comparison | [sku-comparison.md](limits-and-skus/sku-comparison.md) | ✅ current |
| Service limits quick reference | [service-limits-quick-reference.md](limits-and-skus/service-limits-quick-reference.md) | ✅ current |
| Retirement and deprecation tracker | [retirement-tracker.md](limits-and-skus/retirement-tracker.md) | ✅ current |
| [VERIFY] queue | [verify-queue.md](limits-and-skus/verify-queue.md) | ✅ current |

---

## Sources

Per-service source summaries: raw article counts, coverage strengths, gaps, and links to compiled wiki pages.

| Service | Source summary | Articles |
|---|---|---|
| Application Gateway | [application-gateway-docs.md](sources/application-gateway-docs.md) | 176 |
| Azure Bastion | [bastion-docs.md](sources/bastion-docs.md) | — |
| DDoS Protection | [ddos-protection-docs.md](sources/ddos-protection-docs.md) | — |
| Azure DNS | [dns-docs.md](sources/dns-docs.md) | — |
| ExpressRoute | [expressroute-docs.md](sources/expressroute-docs.md) | — |
| Azure Firewall | [firewall-docs.md](sources/firewall-docs.md) | — |
| Firewall Manager | [firewall-manager-docs.md](sources/firewall-manager-docs.md) | — |
| Azure Front Door | [frontdoor-docs.md](sources/frontdoor-docs.md) | — |
| Internet Peering | [internet-peering-docs.md](sources/internet-peering-docs.md) | — |
| Azure Load Balancer | [load-balancer-docs.md](sources/load-balancer-docs.md) | — |
| NAT Gateway | [nat-gateway-docs.md](sources/nat-gateway-docs.md) | — |
| Network Function Manager | [network-function-manager-docs.md](sources/network-function-manager-docs.md) | — |
| Network Watcher | [network-watcher-docs.md](sources/network-watcher-docs.md) | — |
| Azure Networking (cross-cutting) | [networking-docs.md](sources/networking-docs.md) | — |
| Peering Service | [peering-service-docs.md](sources/peering-service-docs.md) | — |
| Private Link | [private-link-docs.md](sources/private-link-docs.md) | — |
| Azure Route Server | [route-server-docs.md](sources/route-server-docs.md) | — |
| Traffic Manager | [traffic-manager-docs.md](sources/traffic-manager-docs.md) | — |
| Azure Virtual Network | [virtual-network-docs.md](sources/virtual-network-docs.md) | — |
| Virtual Network Manager | [virtual-network-manager-docs.md](sources/virtual-network-manager-docs.md) | — |
| Virtual WAN | [virtual-wan-docs.md](sources/virtual-wan-docs.md) | — |
| VPN Gateway | [vpn-gateway-docs.md](sources/vpn-gateway-docs.md) | — |
| Web Application Firewall | [web-application-firewall-docs.md](sources/web-application-firewall-docs.md) | — |

---

## Health

Run `Lore, run a full wiki health check` to generate [health-report.md](health-report.md).
