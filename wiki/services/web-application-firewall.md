# Azure Web Application Firewall (WAF)

> **Compiled:** 2026-04-10 | **Source articles:** 77 | **Status:** ✅ current

## What it is

**Azure Web Application Firewall (WAF)** is a cloud-native, centralized Layer 7 security service that protects web applications from common exploits and vulnerabilities — including **SQL injection (SQLi)**, **cross-site scripting (XSS)**, protocol attacks, and bot-driven threats — without requiring changes to back-end code. WAF is not a standalone resource: it is a feature deployed on one of four supported Azure delivery platforms (**Application Gateway**, **Application Gateway for Containers**, **Azure Front Door**, and **Azure CDN** [CDN preview closed; use Front Door instead]).

Key behavior:
- All WAF configuration lives in a **WAF Policy** resource; policies are associated to a gateway, listener, or path-based rule (App Gateway), or to a Front Door domain.
- Custom rules are always evaluated **before** managed rule sets.
- WAF operates in one of two modes: **Detection** (log only, no block) or **Prevention** (log + block).
- Default scoring for managed rules uses **anomaly scoring mode** (DRS 2.0+); traffic is blocked when cumulative score ≥ 5.
- WAF policy replication to all edge PoPs is automatic on Front Door.

---

## SKUs / deployment modes

| Mode | Platform | Managed Rules | Notes |
|---|---|---|---|
| **WAF_v1** | Application Gateway v1 | CRS only (legacy) | No WAF policy associations; older CRS only; no rate limits, DRS, JS challenge, or new WAF engine features. **Not recommended for new deployments.** |
| **WAF_v2** | Application Gateway v2 | CRS 3.0/3.1/3.2, DRS 2.0/2.1/2.2, Bot Manager 1.0/1.1, HTTP DDoS 1.0 (preview) | Current; supports WAF policies (global / per-site / per-URI); new WAF engine with CRS 3.2+; rate limiting, JS Challenge (preview), Security Copilot |
| **Front Door Standard + WAF** | Azure Front Door Standard tier | **Custom rules only** | No managed rule sets |
| **Front Door Premium + WAF** | Azure Front Door Premium tier | DRS 2.0/2.1/2.2, Bot Manager 1.0/1.1, HTTP DDoS (limited preview) | Full capabilities: managed rules, JS Challenge, CAPTCHA, Security Copilot, HTTP DDoS Ruleset |
| **App GW for Containers + WAF** | Application Gateway for Containers | DRS 2.1 only, Bot Manager 1.0/1.1 | Kubernetes-native; `SecurityPolicy` + `WebApplicationFirewallPolicy` CRDs; see limitations section |
| **CDN WAF** | Azure CDN from Microsoft | Limited | **Preview closed** — no new customers; existing customers remain on preview SLA; migrate to Front Door WAF |

---

## Key capabilities

| Capability | Detail |
|---|---|
| Managed rule sets | OWASP CRS (App Gateway legacy), Default Rule Set / DRS (App Gateway & Front Door), Bot Manager, HTTP DDoS Ruleset (preview) |
| Custom rules | IP match, geo-match, HTTP parameter match, size constraints, rate limits — priority 1–100, evaluated before managed rules |
| Bot protection | 3-tier classification: Bad / Good / Unknown; sourced from Microsoft Threat Intelligence feed; updated multiple times per day |
| JS Challenge | Invisible browser challenge to distinguish bots from humans; App Gateway (preview), Front Door Premium + Bot Manager 1.x |
| CAPTCHA | Interactive human verification; **Front Door Premium only**; incurs additional usage-based charges [VERIFY] |
| Rate limiting | App Gateway WAF v2 (CRS 3.2+, sliding window, 1 or 5 min, group by ClientAddr / GeoLocation / None / XFF variants); Front Door (fixed window, 1 or 5 min) |
| Geo-filtering | Block or allow by country/region code; "ZZ" = unknown; available as custom rule on all platforms |
| HTTP DDoS Ruleset | Adaptive L7 DDoS protection; auto-learns traffic baselines; penalty box = 15 min; requires 24 h learning period (App GW) / 24–36 h (FD); evaluated FIRST, before custom rules |
| Exclusion lists | Per-rule (CRS 3.2+ / Bot 1.0+) or global; excludes header/cookie/arg keys or values from WAF evaluation |
| Sensitive data / log scrubbing | Rules engine scrubs IP address, header names, cookie names, arg names, POST args, JSON args — replaced with `_*******_` |
| Per-site / per-URI policies | App Gateway WAF v2 only; more-specific policy overrides less-specific |
| Azure Firewall Manager | Centralized policy management across subscriptions and regions |
| Azure Policy integration | Built-in policies: audit/deny WAF not enabled, mandate mode, require request body inspection, require resource logs |
| Microsoft Security Copilot | AI-assisted WAF log investigation (App GW + Front Door; **not** App GW for Containers) |
| Microsoft Sentinel integration | WAF solution in Content Hub; pre-built workbooks, analytic rule templates (SQLi, XSS, Log4J, Code Injection, Path Traversal), playbook auto-response |
| Microsoft Defender for Cloud | Integrated; flags unprotected web apps; displays WAF health |
| JSON / XML body inspection | JSON inspection supported on all CRS 3.2+ / DRS 2.0+ versions; XML bodies not supported for exclusion selectors |
| IaC support | Azure portal, REST API, ARM templates, Bicep, Terraform, PowerShell, Azure CLI |

---

## Rule sets

### Managed rule sets — overview

| Rule Set | Platforms | Description |
|---|---|---|
| **CRS (Core Rule Set)** 3.0, 3.1, 3.2 | App Gateway | Legacy OWASP-based; CRS 3.2 activates new WAF engine. CRS 3.0 / 3.1 support ends **2027-02-26**; CRS 2.2.9 EOL March 2025 |
| **DRS (Default Rule Set)** 2.0, 2.1, 2.2 | App Gateway + Front Door | Microsoft-managed evolution of OWASP rules; DRS 2.2 released Feb 2026; DRS 2.1 Oct 2023; includes Microsoft Threat Intelligence Collection rules |
| **Bot Manager** 1.0, 1.1 | App Gateway + Front Door | IP reputation + bot classification (Bad/Good/Unknown); Bot Manager 0.1 not supported |
| **HTTP DDoS Ruleset** 1.0 | App Gateway (preview) + Front Door (limited preview) | Adaptive; learns baselines; evaluated FIRST (before custom rules and other managed rules); 2 rules (500100 all-traffic, 501100/500110 bot-traffic) |

### Ruleset support policy (N, N-1, N-2)

Starting February 2026, Azure WAF actively **supports the latest three ruleset releases**:
- **N:** Latest available rule set version (e.g., DRS 2.2)
- **N-1:** Previous rule set version (e.g., DRS 2.1)
- **N-2:** Second previous rule set version (e.g., CRS 3.2 / DRS 2.0)

When a new ruleset (N) releases, N-3 enters **12-month final support** (critical security updates only). New WAF policies cannot be created with N-3 after N releases.

### Ruleset EOL schedule [VERIFY — as of Feb 2026]

| Ruleset | App Gateway support end | Front Door support end |
|---|---|---|
| DRS 2.2 | Not defined | Not defined |
| DRS 2.1 | Not defined | Not defined |
| CRS 3.2 / DRS 2.0 | Support ends 1 year after first DRS post-2.2 | Support ends 1 year after first DRS post-2.2 |
| CRS 3.1 / 3.0 / DRS 1.x | **2027-02-26** | **2027-02-26** |
| CRS 2.2.9 | **Ended March 2025** | N/A |
| Bot Manager 1.1 | Not defined | Not defined |
| Bot Manager 1.0 | Not defined | Not defined |
| Bot Manager 0.1 | Not supported | Not applicable |

### DRS 2.2 rule groups

| Rule Group | Description |
|---|---|
| General | General group |
| METHOD-ENFORCEMENT | Lock-down methods (PUT, PATCH) |
| PROTOCOL-ENFORCEMENT | Protect against protocol and encoding issues |
| PROTOCOL-ATTACK | Header injection, request smuggling, response splitting |
| APPLICATION-ATTACK-LFI | Local file inclusion attacks |
| APPLICATION-ATTACK-RFI | Remote file inclusion attacks |
| APPLICATION-ATTACK-RCE | Remote code execution attacks |
| APPLICATION-ATTACK-PHP | PHP injection attacks |
| APPLICATION-ATTACK-NodeJS | Node.js attacks |
| APPLICATION-ATTACK-XSS | Cross-site scripting attacks |
| APPLICATION-ATTACK-SQLI | SQL injection attacks |
| APPLICATION-ATTACK-SESSION-FIXATION | Session fixation attacks |
| APPLICATION-ATTACK-SESSION-JAVA | Java attacks |
| MS-ThreatIntel-WebShells | Web shell attacks |
| MS-ThreatIntel-AppSec | AppSec attacks |
| MS-ThreatIntel-SQLI | SQLI attacks (Microsoft Threat Intelligence) |
| MS-ThreatIntel-CVEs | CVE attacks |
| MS-ThreatIntel-XSS | XSS attacks (Microsoft Threat Intelligence) |

### Anomaly scoring (DRS 2.0+ / CRS 3.x)

| Severity | Score contribution |
|---|---|
| Critical | 5 |
| Error | 4 |
| Warning | 3 |
| Notice | 2 |

**Block threshold: ≥ 5.** A single Critical match blocks the request. Two Warning matches (score = 6) also block. Anomaly scoring does not apply to Bot Manager rules.

### Paranoia levels

DRS 2.2 supports Paranoia Level 1 (PL1) enabled by default, with PL2 rules disabled. Higher paranoia = more detection + more potential false positives. PL3/PL4 not currently supported.

---

## Custom rules

| Property | Details |
|---|---|
| **Priority** | 1–100 (lower = higher priority); must be unique within a policy |
| **Max custom rules per policy** | 100 [VERIFY] |
| **Rule types** | `MatchRule`, `RateLimitRule` |
| **Match variables** | `RemoteAddr`, `SocketAddr` (FD), `RequestMethod`, `QueryString`, `PostArgs`, `RequestUri`, `RequestHeaders`, `RequestBody`, `RequestCookies` |
| **Operators** | `IPMatch`, `Equal`, `Any`, `Contains`, `LessThan`, `GreaterThan`, `LessThanOrEqual`, `GreaterThanOrEqual`, `BeginsWith`, `EndsWith`, `Regex`, `GeoMatch` |
| **Transforms** | `Lowercase`, `Uppercase`, `Trim`, `UrlDecode`, `UrlEncode`, `RemoveNulls`, `HtmlEntityDecode` |
| **Actions** | `Allow`, `Block`, `Log`, `Redirect` (Front Door only), `AnomalyScore` (CRS/DRS only), `JSChallenge` (Bot Manager), `Captcha` (FD Premium) |

**Notes:**
- Conditions within the same rule are AND-ed; OR logic requires separate rules
- `PostArgs` and `RequestBody`: `application/json` supported from CRS 3.2+ / Bot 1.0+ / Geomatch custom rules
- Redirect rules configured at the Application Gateway level **bypass WAF custom rules** [CAUTION]
- Front Door uses `SocketAddr` for client IP; `RemoteAddr` is the original client IP from X-Forwarded-For header

### Geomatch custom rules

- Use country/region codes (ISO 3166-1 alpha-2)
- "ZZ" captures IP addresses not yet mapped to a country/region
- Best practice: use `Block` with negation (block all except X) rather than `Allow` specific countries
- Avoid `Allow` actions as they bypass managed rulesets

---

## JavaScript Challenge

| Property | App Gateway | Front Door |
|---|---|---|
| **Status** | Preview | GA (Premium tier) |
| **Available on** | Custom rules, Bot Manager 1.x | Custom rules, Bot Manager 1.x |
| **Cookie name** | `appgw_azwaf_jsclearance` | `afd_azwaf_jsclearance` |
| **Cookie validity** | 5–1,440 minutes (default 30) | 5–1,440 minutes (default 30) |
| **POST body limit** | 128 KB | 64 KB |

**Limitations:**
- AJAX and API calls not supported
- Non-HTML embedded resources not supported
- Not supported on Internet Explorer
- Rate limit rules not supported with JS Challenge on App Gateway (preview)
- App Gateway for Containers does not support JS Challenge

---

## CAPTCHA (Front Door Premium only)

| Property | Value |
|---|---|
| **Cookie name** | `afd_azwaf_captcha` |
| **Cookie validity** | 5–1,440 minutes (default 30) |
| **POST body limit** | 64 KB |
| **Pricing** | Additional usage-based charges [VERIFY] |

**Limitations:**
- Mobile apps not supported
- AJAX and API calls not supported
- Non-HTML embedded resources not supported
- Not supported on Internet Explorer

---

## HTTP DDoS Ruleset (Preview)

Adaptive Layer 7 DDoS protection that learns traffic baselines automatically.

| Property | App Gateway | Front Door |
|---|---|---|
| **Status** | Preview | Limited preview (signup required) |
| **Learning period** | 24 hours minimum | 24–36 hours (requires 50%+ traffic in past 7 days) |
| **Penalty box duration** | 15 minutes | N/A (throttling instead) |
| **Evaluation order** | **First** — before custom rules and managed rules | **First** |

**Rules:**
- **Rule 500100:** Anomaly detected on high rate of client requests — tracks all traffic
- **Rule 501100 (App GW) / 500110 (FD):** Suspected bots sending high rates of requests — stricter thresholds for bot traffic

**Sensitivity levels:** Low, Medium (default), High — higher sensitivity = lower threshold

**Key behaviors:**
- Custom rules with `Allow` action do NOT bypass HTTP DDoS ruleset
- High-risk bots blocked immediately when global threshold breached
- No ability to whitelist specific IPs during preview

---

## Rate limiting

| Property | App Gateway WAF v2 | Front Door |
|---|---|---|
| **Window type** | Sliding window | Fixed window |
| **Window duration** | 1 or 5 minutes | 1 or 5 minutes |
| **GroupBy variables** | `ClientAddr`, `GeoLocation`, `None`, `ClientAddrXFFHeader`, `GeoLocationXFFHeader` | Socket IP only |
| **Requires** | CRS 3.2+ (new WAF engine) | Any tier |

**Best practices:**
- Use larger window sizes (5 min over 1 min) for more accurate enforcement
- Use higher thresholds (200+ requests) for production
- Lower thresholds may allow some requests above threshold through

---

## Exclusion lists

| Scope | Description |
|---|---|
| **Rule set** | Applies to all rules within a rule set |
| **Rule group** | Applies to all rules in a category (e.g., SQL injection rules) |
| **Rule** | Applies to a single rule — **recommended for narrowest scope** |

**Match variables:**
- Request header name
- Request cookie name
- Query string args name
- Request body POST args name
- Request body JSON args name (DRS 2.0+)

**Operators:** `Equals`, `Starts with`, `Ends with`, `Contains`, `Equals any`

**Case sensitivity:**
- Headers and cookies: case-insensitive
- Query strings, POST args, JSON args: case-sensitive

**Per-rule exclusions require:** CRS 3.2+ or Bot Manager 1.0+

---

## Policy association

### Application Gateway WAF v2

| Level | Description |
|---|---|
| **Global** | Policy applies to all sites behind the App Gateway |
| **Per-site** | Policy applies to specific listener; overrides global |
| **Per-URI** | Policy applies to specific path-based rule; overrides per-site and global |

### Front Door

- One WAF policy per domain at a time
- Policy replicates to all global edge PoPs automatically

### Application Gateway for Containers

- Uses Kubernetes CRDs: `SecurityPolicy` + `WebApplicationFirewallPolicy`
- Can target `Gateway`, `HTTPRoute`, or specific listeners
- WAF policy must be in same subscription and region as the App GW for Containers resource

---

## Request size limits (Application Gateway)

| Setting | CRS 3.1 and earlier | CRS 3.2+ / DRS |
|---|---|---|
| **Max request body size** | Required when body inspection enabled | Can be disabled entirely |
| **Max file upload size** | Fixed | Can be disabled entirely |
| **Request body inspection limit** | Tied to max body size | Independent — can set lower for performance |

For CRS 3.2+, high-priority custom rules (e.g., priority 0) that act on headers/cookies/URI are evaluated **before** max size limits are enforced.

---

## Microsoft Security Copilot integration

| Feature | Description |
|---|---|
| **Platforms** | App Gateway WAF, Front Door WAF (**not** App GW for Containers) |
| **Access** | Standalone experience at https://securitycopilot.microsoft.com |
| **Capabilities** | Top triggered WAF rules with attack vectors; malicious IP identification; SQLi attack summaries; XSS attack summaries |

**Sample prompts:**
- "Was there a SQL injection attack in my global WAF in the last day?"
- "What were the top regional WAF rules triggered in the last 24 hours?"
- "Show me list of all XSS attacks in my Azure Front Door WAF"
- "What was the top offending IP in regional WAF in the last day?"

**Limitation:** If using Azure Log Analytics dedicated tables on App Gateway WAF V2, Security Copilot skills are not functional. Use Azure Diagnostics destination table as workaround.

---

## Microsoft Sentinel integration

| Component | Description |
|---|---|
| **Content Hub solution** | "Azure Web Application Firewall" |
| **Data connector** | Azure Web Application Firewall (WAF) |
| **Pre-built workbooks** | Top 40 blocked URIs, top 50 event triggers, top 10 attacking IPs, attack events over time |
| **Analytic rule templates** | SQLi, XSS, Log4J, Code Injection, Path Traversal, Scanner-based attacks |
| **Playbook examples** | Auto-block attacker IPs via WAF custom rules |

**Log types to enable:**
- App Gateway: `ApplicationGatewayAccessLog`, `ApplicationGatewayFirewallLog`
- Front Door Standard/Premium: `FrontDoorAccessLog`, `FrontDoorFirewallLog`
- Front Door Classic: `FrontdoorAccessLog`, `FrontdoorFirewallLog`

---

## Monitoring and logging

### Metrics

| Metric | Platforms | Description |
|---|---|---|
| Web Application Firewall Request Count | All | Requests matching WAF rules (excludes duplicate Log actions) |
| JS Challenge Request Count | Front Door | JS Challenge outcomes: Issued, Passed, Valid, Blocked |
| Penalty Box Size | App Gateway (preview) | IPs currently in HTTP DDoS penalty box |
| Penalty Box Blocks | App Gateway (preview) | Blocks due to penalty box |

### Log categories

| Platform | Access Log | Firewall Log |
|---|---|---|
| App Gateway | ApplicationGatewayAccessLog | ApplicationGatewayFirewallLog |
| Front Door Standard/Premium | FrontDoorAccessLog | FrontDoorWebApplicationFirewallLog |
| Front Door Classic | FrontdoorAccessLog | FrontdoorWebApplicationFirewallLog |

### Firewall log fields

| Field | Description |
|---|---|
| action | Allow, Block, Log, AnomalyScoring, JSChallengeIssued, JSChallengePass, JSChallengeValid, JSChallengeBlock |
| clientIP | Client IP (from X-Forwarded-For if present) |
| socketIP | Source IP seen by WAF (TCP session) |
| host | Host header |
| requestUri | Full URI |
| ruleName | Matched rule name |
| policy | WAF policy name |
| policyMode | Prevention or Detection |
| trackingReference | Unique request ID (X-Azure-Ref) |
| details | Match variable name and value |

---

## Azure Policy definitions for WAF

| Policy | Effect | Description |
|---|---|---|
| WAF should be enabled for Front Door | Audit/Deny/Disable | Ensures WAF is attached to Front Door |
| WAF should be enabled for App Gateway | Audit/Deny/Disable | Ensures WAF is attached to App Gateway |
| WAF should use specified mode | Audit/Deny/Disable | Mandates Detection or Prevention mode |
| Request body inspection should be enabled | AuditIfNotExists/Disable | Ensures body inspection is on |
| Resource logs should be enabled | AuditIfNotExists/Disable | Ensures diagnostic logs are configured |
| Front Door should use Premium tier | Audit/Deny/Disable | Recommends Premium for managed rules + Private Link |
| Rate limit rule should be enabled | Audit/Deny/Disable | Recommends rate limiting for DDoS |
| Migrate WAF Config to WAF Policy | Audit/Deny/Disable | Legacy WAF Config should be migrated |

---

## App Gateway for Containers WAF limitations

The following features are **not supported** on WAF policies associated with Application Gateway for Containers:

| Limitation | Details |
|---|---|
| Cross-region/cross-subscription policy | WAF policy must be in same subscription and region |
| Core Rule Set (CRS) | Only DRS 2.1 supported |
| Bot Manager 0.1 | Not supported; use 1.0 or 1.1 |
| JavaScript Challenge | Not supported |
| CAPTCHA | Not supported |
| Security Copilot | Not supported |
| Custom block response | Not supported |
| X-Forwarded-For in custom rules | Not supported |
| HTTP DDoS Ruleset | Not supported |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Max custom rules per policy | 100 [VERIFY] | |
| Max exclusions per policy | Check Azure limits doc [VERIFY] | |
| Max WAF policies per subscription | Check Azure limits doc [VERIFY] | |
| JS Challenge cookie validity | 5–1,440 minutes | |
| CAPTCHA cookie validity | 5–1,440 minutes | |
| HTTP DDoS penalty box duration | 15 minutes | App Gateway only |
| Rate limit window | 1 or 5 minutes | |
| Custom rule priority range | 1–100 | |

---

## When to use it

| Use case | Recommended platform |
|---|---|
| Regional web app protection with L7 load balancing | Application Gateway WAF v2 |
| Global edge protection for web apps | Azure Front Door Premium + WAF |
| Kubernetes-native container workloads | Application Gateway for Containers + WAF |
| Bot protection with managed rules | Front Door Premium or App Gateway v2 with Bot Manager 1.1 |
| Need CAPTCHA for human verification | Front Door Premium |
| API protection behind APIM | Front Door Premium WAF in front of APIM |
| Centralized multi-subscription policy management | Azure Firewall Manager |

---

## When NOT to use it

| Scenario | Alternative |
|---|---|
| Network-layer (L3/L4) traffic filtering | Azure Firewall, NSG |
| DDoS volumetric attack protection | Azure DDoS Protection |
| East-west traffic within VNet | Azure Firewall, NSGs |
| Non-HTTP/HTTPS protocols | Azure Firewall |
| WAF for legacy App Gateway v1 without migration path | Migrate to v2 or Front Door |

---

## Related services

- [Application Gateway](../services/application-gateway.md) — regional L7 load balancer; hosts WAF_v2
- [Azure Front Door](../services/front-door.md) — global CDN/load balancer; hosts WAF at edge
- [Azure Firewall](../services/azure-firewall.md) — network-layer firewall for L3/L4
- [DDoS Protection](../services/ddos-protection.md) — volumetric DDoS mitigation
- [Azure Firewall Manager](../services/firewall-manager.md) — centralized WAF policy management
- [Microsoft Sentinel](https://learn.microsoft.com/azure/sentinel/) — SIEM integration for WAF logs

---

## Source articles

- [overview.md](../../raw/articles/web-application-firewall/overview.md)
- [ag/ag-overview.md](../../raw/articles/web-application-firewall/ag/ag-overview.md)
- [afds/afds-overview.md](../../raw/articles/web-application-firewall/afds/afds-overview.md)
- [waf-copilot.md](../../raw/articles/web-application-firewall/waf-copilot.md)
- [waf-javascript-challenge.md](../../raw/articles/web-application-firewall/waf-javascript-challenge.md)
- [waf-sentinel.md](../../raw/articles/web-application-firewall/waf-sentinel.md)
- [waf-new-threat-detection.md](../../raw/articles/web-application-firewall/waf-new-threat-detection.md)
- [ruleset-support-policy.md](../../raw/articles/web-application-firewall/ruleset-support-policy.md)
- [afds/waf-front-door-drs.md](../../raw/articles/web-application-firewall/afds/waf-front-door-drs.md)
- [afds/captcha-challenge.md](../../raw/articles/web-application-firewall/afds/captcha-challenge.md)
- [ag/ddos-ruleset.md](../../raw/articles/web-application-firewall/ag/ddos-ruleset.md)
- [afds/http-ddos-ruleset.md](../../raw/articles/web-application-firewall/afds/http-ddos-ruleset.md)
- [ag/rate-limiting-overview.md](../../raw/articles/web-application-firewall/ag/rate-limiting-overview.md)
- [afds/waf-front-door-rate-limit.md](../../raw/articles/web-application-firewall/afds/waf-front-door-rate-limit.md)
- [ag/custom-waf-rules-overview.md](../../raw/articles/web-application-firewall/ag/custom-waf-rules-overview.md)
- [afds/waf-front-door-exclusion.md](../../raw/articles/web-application-firewall/afds/waf-front-door-exclusion.md)
- [ag/waf-sensitive-data-protection.md](../../raw/articles/web-application-firewall/ag/waf-sensitive-data-protection.md)
- [geomatch-custom-rules-examples.md](../../raw/articles/web-application-firewall/geomatch-custom-rules-examples.md)
- [ag/policy-overview.md](../../raw/articles/web-application-firewall/ag/policy-overview.md)
- [ag/waf-application-gateway-for-containers-overview.md](../../raw/articles/web-application-firewall/ag/waf-application-gateway-for-containers-overview.md)
- [shared/manage-policies.md](../../raw/articles/web-application-firewall/shared/manage-policies.md)
- [ag/application-gateway-waf-request-size-limits.md](../../raw/articles/web-application-firewall/ag/application-gateway-waf-request-size-limits.md)
- [afds/waf-front-door-monitor.md](../../raw/articles/web-application-firewall/afds/waf-front-door-monitor.md)
- [shared/waf-azure-policy.md](../../raw/articles/web-application-firewall/shared/waf-azure-policy.md)
- [ag/web-application-firewall-logs.md](../../raw/articles/web-application-firewall/ag/web-application-firewall-logs.md)
