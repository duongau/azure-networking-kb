# Azure Web Application Firewall (WAF)

> **Compiled:** 2026-04-10 | **Source articles:** 77 | **Status:** ✅ current

## What it is

**Azure Web Application Firewall (WAF)** is a cloud-native, centralized Layer 7 security service that
protects web applications from common exploits and vulnerabilities — including **SQL injection (SQLi)**,
**cross-site scripting (XSS)**, protocol attacks, and bot-driven threats — without requiring changes to
back-end code. WAF is not a standalone resource: it is a feature deployed on top of one of four
supported Azure delivery platforms (**Application Gateway**, **Application Gateway for Containers**,
**Azure Front Door**, and **Azure CDN** [CDN preview closed; use Front Door instead]).

Key behavior:
- All WAF configuration lives in a **WAF Policy** resource; policies are associated to a gateway,
  listener, or path-based rule (App Gateway), or to a Front Door domain.
- Custom rules are always evaluated **before** managed rule sets.
- WAF operates in one of two modes: **Detection** (log only, no block) or **Prevention** (log + block).
- Default scoring for managed rules uses **anomaly scoring mode** (OWASP 3.x and DRS); traffic is
  blocked when cumulative score ≥ 5.
- WAF policy replication to all edge PoPs is automatic on Front Door.

---

## Key capabilities

| Capability | Detail |
|---|---|
| Managed rule sets | OWASP CRS (App Gateway legacy), Default Rule Set / DRS (App Gateway & Front Door), Bot Manager, HTTP DDoS Ruleset (preview) |
| Custom rules | IP match, geo-match, HTTP parameter match, size constraints, rate limits — priority 1–100, evaluated before managed rules |
| Bot protection | 3-tier classification: Bad / Good / Unknown; sourced from Microsoft Threat Intelligence feed; updated multiple times per day |
| JS Challenge | Invisible browser challenge to distinguish bots from humans; App Gateway (preview), Front Door Premium + Bot Manager 1.x |
| CAPTCHA | Interactive human verification; Front Door only; incurs additional usage-based charges [VERIFY] |
| Rate limiting | App Gateway WAF v2 (CRS 3.2+, sliding window, 1 or 5 min, group by ClientAddr / GeoLocation / None / XFF variants); Front Door (fixed window, 1 or 5 min) |
| Geo-filtering | Block or allow by country/region code; "ZZ" = unknown; available as custom rule on all platforms |
| HTTP DDoS Ruleset | Adaptive L7 DDoS protection; auto-learns traffic baselines; penalty box = 15 min; requires 24 h learning period (App GW) / 24–36 h (FD); evaluated FIRST, before custom rules |
| Exclusion lists | Per-rule (CRS 3.2+ / Bot 1.0+) or global; excludes header/cookie/arg keys or values from WAF evaluation |
| Sensitive data / log scrubbing | Rules engine scrubs IP address, header names, cookie names, arg names, POST args, JSON args — replaced with `_*******_` |
| Per-site / per-URI policies | App Gateway WAF v2 only; more-specific policy overrides less-specific |
| Azure Firewall Manager | Centralized policy management across subscriptions and regions |
| Azure Policy integration | Built-in policies: audit/deny WAF not enabled, mandate mode, require request body inspection, require resource logs |
| Microsoft Security Copilot | AI-assisted WAF log investigation (App GW + Front Door; **not** App GW for Containers) |
| Microsoft Sentinel integration | WAF solution in Content Hub; pre-built workbooks, analytic rule templates (SQLi, XSS, Log4J), playbook auto-response |
| Microsoft Defender for Cloud | Integrated; flags unprotected web apps; displays WAF health |
| JSON / XML body inspection | JSON inspection supported on all CRS versions; XML bodies not supported for exclusion selectors |
| IaC support | Azure portal, REST API, ARM templates, Bicep, Terraform, PowerShell, Azure CLI |

---

## SKUs / deployment modes

| Mode | Platform | Notes |
|---|---|---|
| **WAF_v1** | Application Gateway v1 | Legacy; no WAF policy associations; older CRS only; no rate limits, DRS, new WAF engine features. Not recommended for new deployments. |
| **WAF_v2** | Application Gateway v2 | Current; supports WAF policies (global / per-site / per-URI); new WAF engine with CRS 3.2+; rate limiting, DRS, JS challenge (preview), Security Copilot |
| **Front Door Standard + WAF** | Azure Front Door Standard tier | **Custom rules only**; no managed rule sets |
| **Front Door Premium + WAF** | Azure Front Door Premium tier | Full capabilities: managed rules (DRS, Bot Manager 1.1), JS Challenge, CAPTCHA, Security Copilot, HTTP DDoS Ruleset (limited preview) |
| **App GW for Containers + WAF** | Application Gateway for Containers | Kubernetes-native; `SecurityPolicy` + `WebApplicationFirewallPolicy` CRDs; supports DRS 2.1 + Bot Manager 1.0 / 1.1 only (see limitations) |
| **CDN WAF** | Azure CDN from Microsoft | **Preview closed** — no new customers; existing customers remain on preview SLA; migrate to Front Door WAF |

---

## Rule sets

### Managed rule sets — overview

| Rule Set | Platforms | Description |
|---|---|---|
| **CRS (Core Rule Set)** 3.0, 3.1, 3.2 | App Gateway | Legacy OWASP-based; CRS 3.2 activates new WAF engine. CRS 3.0 / 3.1 EOL **2027-02-26**; CRS 2.2.9 already EOL (March 2025) |
| **DRS (Default Rule Set)** 2.0, 2.1, 2.2 | App Gateway + Front Door | Microsoft-managed evolution of OWASP rules; DRS 2.2 released Feb 2026; DRS 2.1 Oct 2023 |
| **Bot Manager** 1.0, 1.1 | App Gateway + Front Door | IP reputation + bot classification (Bad/Good/Unknown); Bot Manager 0.1 not supported |
| **HTTP DDoS Ruleset** 1.0 | App Gateway (preview) + Front Door (limited preview) | Adaptive; learns baselines; evaluated FIRST (before custom rules and other managed rules); 2 rules (500100 all-traffic, 501100/500110 bot-traffic) |

### Supported ruleset versions and EOL schedule [VERIFY — as of Feb 2026]

**Active support:** Latest 3 releases (N, N-1, N-2) receive ongoing updates.  
**N-3 rule:** 12-month final support (critical security updates only); cannot create new policies with N-3 after N is released.

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

### Anomaly scoring (default for CRS / DRS)

| Severity | Score contribution |
|---|---|
| Critical | 5 |
| Error | 4 |
| Warning | 3 |
| Notice | 2 |

**Block threshold: ≥ 5.** A single Critical match blocks the request. Two Warning matches (score = 6) also block. Anomaly scoring does not apply to Bot Manager rules.

### Custom rules

- **Priority:** 1–100 (lower = higher priority); must be unique within a policy
- **Max custom rules per policy:** 100 [VERIFY]
- **Rule types:** `MatchRule`, `RateLimitRule`
- **Match variables:** `RemoteAddr`, `RequestMethod`, `QueryString`, `PostArgs`, `RequestUri`, `RequestHeaders`, `RequestBody`, `RequestCookies`
- **Operators:** `IPMatch`, `Equal`, `Any`, `Contains`, `LessThan`, `GreaterThan`, `LessThanOrEqual`, `GreaterThanOrEqual`, `BeginsWith`, `EndsWith`, `Regex`, `Geomatch`
- **Transforms:** `Lowercase`, `Uppercase`, `Trim`, `UrlDecode`, `UrlEncode`, `RemoveNulls`, `HtmlEntityDecode`
- **Actions:** `Allow`, `Block`, `Log`, `Redirect` (Front Door only), `AnomalyScore` (CRS/DRS only)
- Conditions within the same rule are AND-ed; OR logic requires separate rules
- `PostArgs` and `RequestBody`: `application/json` supported from CRS 3.2+ / Bot 1.0+ / Geomatch custom rules
- Redirect rules configured at the Application Gateway level **bypass WAF custom rules** [CAUTION]

### Exclusions

- **Global exclusions:** apply across all WAF rules
- **Per-rule exclusions:** apply to specific rules, rule groups, or rule sets; require **CRS 3.2+ or Bot Manager 1.0+**
- Exclusion match variables: `RequestHeaderKeys/Values/Names`, `RequestCookieKeys/Values/Names`, `RequestArgKeys/Values/Names`
- XML request bodies **not supported** as exclusion selectors
- CRS 3.2+: cookies, query strings, URL-encoded/JSON/multipart bodies are **case-sensitive**; headers are always **case-insensitive**
- Best practice: use per-rule exclusions, make them as narrow as possible

---

## Architecture patterns

### WAF on Azure Front Door (global edge)

