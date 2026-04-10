# Azure Firewall — Source Summary

> **Service:** Azure Firewall | **Raw path:** `raw/articles/firewall/` | **Articles:** 86 | **Last synced:** 2025-07-14 | **Wiki page:** [services/azure-firewall.md](../services/azure-firewall.md)

## Key topics covered
- Three SKUs: Basic, Standard, Premium
- Stateful packet filtering and rule processing
- SNAT/DNAT behavior and port allocation
- Application FQDN filtering and web categories
- Threat Intelligence (alert/deny modes)
- TLS inspection (Premium, outbound + east-west)
- IDPS with 67,000+ signatures (Premium)
- DNS proxy and custom DNS configuration
- Forced tunneling with management NIC
- IP Groups for rule reuse
- Autoscaling behavior and triggers
- Policy analytics

## Coverage strengths
- SKU feature comparison table is comprehensive
- Rule processing order clearly documented
- TLS inspection requirements and limitations
- Performance figures by SKU tier

## Coverage gaps
- PCI DSS compliance scope needs verification
- Exact SNAT port limits per public IP
- IDPS throughput impact figures marked [VERIFY]

## Related wiki pages
- [Application Gateway](../services/application-gateway.md)
- [DDoS Protection](../services/ddos-protection.md)
- [NAT Gateway](../services/nat-gateway.md)
- [Firewall Manager](../services/firewall-manager.md)
