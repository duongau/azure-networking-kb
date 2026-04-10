# Azure DDoS Protection — Source Summary

> **Service:** DDoS Protection | **Raw path:** `raw/articles/ddos-protection/` | **Articles:** 32 | **Last synced:** 2026-04-08 | **Wiki page:** [services/ddos-protection.md](../services/ddos-protection.md)

## Key topics covered
- L3/L4 attack mitigation with ML-based profiling
- Three protection tiers (Infrastructure, IP, Network)
- Auto-tuned mitigation policies (TCP SYN, TCP, UDP)
- DDoS Rapid Response (DRR) for Network Protection
- Cost protection and WAF discount
- Attack analytics, flow logs, and metrics
- Simulation testing with approved partners
- Inline L7 protection via Gateway Load Balancer + NVAs
- Microsoft Sentinel integration

## Coverage strengths
- SKU tier comparison with clear decision criteria
- Integration patterns with other services (Firewall, WAF, LB)
- Attack metrics and alerting well documented
- Reference architecture patterns included

## Coverage gaps
- Exact pricing breakeven calculations need verification
- Detection-to-mitigation timing estimates marked [VERIFY]
- VMSS telemetry orchestration mode limitations

## Related wiki pages
- [Azure Firewall](../services/azure-firewall.md)
- [Application Gateway](../services/application-gateway.md)
- [Load Balancer](../services/load-balancer.md)
- [Network Watcher](../services/network-watcher.md)
