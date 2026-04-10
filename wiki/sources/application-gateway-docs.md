# Application Gateway — Source Summary

> **Service:** Application Gateway | **Raw path:** `raw/articles/application-gateway/` | **Articles:** 176 (126 main + 50 for-containers/) | **Last synced:** 2025-07-15 | **Wiki page:** [services/application-gateway.md](../services/application-gateway.md)

## Key topics covered
- L7 reverse proxy architecture and components (frontend, listeners, backend pools, rules, probes)
- SSL/TLS termination and end-to-end encryption
- URL-based and multi-site routing
- WAF integration (OWASP CRS 3.0, 3.1, 3.2)
- Mutual authentication (mTLS)
- v1 to v2 migration (v1 retiring April 2026)
- TCP/TLS Layer 4 proxy (preview)
- Private deployment and Private Link support
- AKS Ingress Controller (AGIC)
- Autoscaling and zone redundancy
- Application Gateway for Containers (separate resource)

## Coverage strengths
- SKU comparison (v1 vs v2, Basic/Standard/WAF variants) is comprehensive
- Scaling architecture and capacity unit calculations well documented
- TLS configuration and certificate management detailed
- Architecture components table is production-ready

## Coverage gaps
- Application Gateway for Containers has 50 articles but compiled as separate stub only
- Exact subscription limits referenced via include files not directly scraped
- FIPS mode status needs verification
- Pricing figures marked illustrative only

## Related wiki pages
- [Azure Load Balancer](../services/load-balancer.md)
- [Azure Firewall](../services/azure-firewall.md)
- [Private Link](../services/private-link.md)
- [Web Application Firewall](../services/web-application-firewall.md)
