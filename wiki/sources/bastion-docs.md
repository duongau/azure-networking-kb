# Azure Bastion — Source Summary

> **Service:** Bastion | **Raw path:** `raw/articles/bastion/` | **Articles:** 43 | **Last synced:** 2026-04-10 | **Wiki page:** [services/bastion.md](../services/bastion.md)

## Key topics covered
- Browser-based RDP/SSH connectivity
- SKU comparison (Developer, Basic, Standard, Premium)
- Native client connections via Azure CLI
- Shareable links for portal-free access
- Session recording (Premium)
- Private-only deployment
- VNet peering support
- NSG requirements for AzureBastionSubnet
- Kerberos and Entra ID authentication
- Host scaling (2-50 instances)
- AKS private cluster connectivity (preview)

## Coverage strengths
- SKU feature matrix is complete with upgrade paths
- NSG requirements documented with exact port rules
- Session concurrency limits per SKU tier
- Architecture patterns (single-VNet, hub-spoke, private-only)

## Coverage gaps
- Developer SKU region availability needs verification
- Availability Zones deployment is still in preview
- Cost details marked [VERIFY]

## Related wiki pages
- [Azure Virtual Network](../services/virtual-network.md)
- [Azure Firewall](../services/azure-firewall.md)
- [DDoS Protection](../services/ddos-protection.md)
- [ExpressRoute](../services/expressroute.md)
