# Virtual WAN — Source Summary

> **Service:** Virtual WAN | **Raw path:** `raw/articles/virtual-wan/` | **Articles:** 133 | **Last synced:** 2026-04-10 | **Wiki page:** [services/virtual-wan.md](../services/virtual-wan.md)

## Key topics covered
- Microsoft-managed hub-and-spoke architecture
- S2S VPN, P2S VPN, ExpressRoute gateways
- VNet connections and hub-to-hub transit
- Secure Virtual Hub with Azure Firewall/NVA/SaaS
- Routing Intent and Routing Policies
- NVA-in-hub (SD-WAN, NGFW partners)
- Route-maps for BGP manipulation
- NAT rules for overlapping address spaces
- Hub routing preference
- Gateway scale units and Routing Infrastructure Units
- Global P2S profile
- IPsec over ExpressRoute

## Coverage strengths
- SKU comparison (Basic vs Standard) with feature matrix
- Gateway scale unit throughput table
- Architecture patterns (7 documented)
- Routing Intent configuration guidance

## Coverage gaps
- S2S VPN pricing conflict between source articles [CONFLICT]
- ER ECMP activation requirements
- Single TCP flow throughput limits need verification

## Related wiki pages
- [ExpressRoute](../services/expressroute.md)
- [VPN Gateway](../services/vpn-gateway.md)
- [Azure Firewall](../services/azure-firewall.md)
- [Hub-spoke networking](../concepts/hub-spoke-networking.md)
