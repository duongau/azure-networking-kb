# NAT Gateway — Source Summary

> **Service:** NAT Gateway | **Raw path:** `raw/articles/nat-gateway/` | **Articles:** 27 | **Last synced:** 2026-04-08 | **Wiki page:** [services/nat-gateway.md](../services/nat-gateway.md)

## Key topics covered
- Dynamic SNAT port allocation
- StandardV2 vs Standard SKU comparison
- Zone redundancy (V2) and IPv6 support (V2)
- Up to 16 public IPs and ~1M SNAT ports
- Idle timeout configuration (TCP 4-120 min)
- SNAT exhaustion mitigation patterns
- Coexistence with Azure Firewall and Load Balancer
- Flow logs (StandardV2 only)
- Default outbound access retirement (March 2026)

## Coverage strengths
- SKU feature comparison table is clear
- Service limits documented with scaling formulas
- SNAT exhaustion mitigation patterns
- Monitoring metrics and flow log details

## Coverage gaps
- StandardV2 unsupported delegated subnets list needs verification
- StandardV2 regional gaps need updates
- Per-connection bandwidth limits

## Related wiki pages
- [Virtual Network](../services/virtual-network.md)
- [Azure Firewall](../services/azure-firewall.md)
- [Load Balancer](../services/load-balancer.md)
