# Azure Load Balancer — Source Summary

> **Service:** Load Balancer | **Raw path:** `raw/articles/load-balancer/` | **Articles:** 95 | **Last synced:** 2026-04-10 | **Wiki page:** [services/load-balancer.md](../services/load-balancer.md)

## Key topics covered
- L4 pass-through load balancing (TCP/UDP)
- Public vs Internal LB types
- Standard, Gateway, Basic (retired), Global tier SKUs
- Zone-redundancy and HA ports
- Outbound SNAT and port allocation
- Health probes (TCP, HTTP, HTTPS)
- Distribution modes (5-tuple, 2-tuple, 3-tuple)
- Floating IP (Direct Server Return)
- Inbound NAT rules
- Admin State for maintenance
- Cross-region (Global) LB
- Gateway LB for NVA insertion

## Coverage strengths
- Outbound connectivity priority table
- Health probe behavior and known issues documented
- Retirement timeline (Basic LB, numberOfProbes, NAT rule V1)
- Gateway LB technical details

## Coverage gaps
- SNAT port allocation per pool size needs verification
- Global tier home region availability
- Subscription move limitations

## Related wiki pages
- [NAT Gateway](../services/nat-gateway.md)
- [Application Gateway](../services/application-gateway.md)
- [Private Link](../services/private-link.md)
