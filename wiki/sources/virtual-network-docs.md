# Virtual Network — Source Summary

> **Service:** Virtual Network | **Raw path:** `raw/articles/virtual-network/` | **Articles:** 75 | **Last synced:** 2025-07-31 | **Wiki page:** [services/virtual-network.md](../services/virtual-network.md)

## Key topics covered
- VNet isolation and custom address space
- Subnets and Azure IP reservations (5 per subnet)
- NSGs, ASGs, and service tags
- Security admin rules (VNet Manager)
- User-defined routes and system default routes
- VNet peering (local and global)
- Subnet peering
- Service endpoints
- Private endpoints (Private Link)
- Subnet delegation
- VNet encryption (DTLS-based)
- Accelerated Networking
- Public IP SKUs (Standard v1/v2, Basic retired)
- Default outbound access retirement
- VNet flow logs

## Coverage strengths
- NSG rule processing order clearly documented
- Address space planning guidance
- Service limits table (VNets, subnets, peerings, NSG rules)
- Default outbound access retirement timeline

## Coverage gaps
- VNet encryption supported VM series needs verification
- Some limits referenced via external docs
- Full subscription limits via Azure Networking Limits page

## Related wiki pages
- [IP addressing](../concepts/ip-addressing.md)
- [Routing](../concepts/routing.md)
- [Network security groups](../concepts/network-security-groups.md)
- [Private Link](../services/private-link.md)
