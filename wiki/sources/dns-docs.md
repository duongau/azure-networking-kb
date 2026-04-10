# Azure DNS — Source Summary

> **Service:** Azure DNS | **Raw path:** `raw/articles/dns/` | **Articles:** 69 | **Last synced:** 2025-07-31 | **Wiki page:** [services/dns.md](../services/dns.md)

## Key topics covered
- Four sub-services: Public DNS, Private DNS, Private Resolver, DNS Security Policy
- Record types (A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT, CAA, DS, TLSA)
- Alias records for zone apex and Azure resource tracking
- DNSSEC zone signing for public zones
- Private DNS autoregistration and VNet links
- DNS Private Resolver (inbound/outbound endpoints, forwarding rulesets)
- Split-horizon DNS patterns
- DNS Security Policy with threat intelligence
- NxDomainRedirect fallback for Private Link zones

## Coverage strengths
- Sub-service capabilities clearly segmented
- Private Resolver configuration and hybrid DNS patterns detailed
- DNS Security Policy rule processing documented
- VNet link types (registration vs resolution) explained

## Coverage gaps
- Pricing model needs verification for all sub-services
- DNS Security Policy pricing not explicitly stated
- Exact zone/record limits referenced via external docs

## Related wiki pages
- [Virtual Network](../services/virtual-network.md)
- [Private Link](../services/private-link.md)
- [Hybrid connectivity](../concepts/hybrid-connectivity.md)
