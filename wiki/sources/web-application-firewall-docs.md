# Web Application Firewall — Source Summary

> **Service:** Web Application Firewall | **Raw path:** `raw/articles/web-application-firewall/` | **Articles:** 77 | **Last synced:** 2026-04-10 | **Wiki page:** [services/web-application-firewall.md](../services/web-application-firewall.md)

## Key topics covered
- WAF Policy resource model
- Deployment platforms (App Gateway, App GW for Containers, Front Door, CDN)
- Managed rule sets (CRS, DRS, Bot Manager, HTTP DDoS)
- Custom rules (IP match, geo, rate limiting)
- Bot protection and JS Challenge
- CAPTCHA (Front Door only)
- Anomaly scoring mode
- Exclusion lists (global and per-rule)
- Sensitive data scrubbing
- Per-site/per-URI policies (App Gateway)
- Microsoft Sentinel and Security Copilot integration
- Rule set EOL schedule

## Coverage strengths
- Platform comparison matrix (WAF_v1, WAF_v2, Front Door Standard/Premium)
- Rule set version support and EOL dates
- Custom rule mechanics and operators
- Exclusion configuration guidance

## Coverage gaps
- CAPTCHA pricing needs verification
- CDN WAF is preview-closed (migrate to Front Door)
- Max custom rules per policy needs verification

## Related wiki pages
- [Application Gateway](../services/application-gateway.md)
- [Azure Front Door](../services/front-door.md)
- [Firewall Manager](../services/firewall-manager.md)
- [Network security design](../concepts/network-security-design.md)
