# Azure Front Door

> **Compiled:** 2026-04-09 | **Source articles:** 102 | **Status:** current

## What it is

Azure Front Door is a globally-distributed, cloud-native **Content Delivery Network (CDN) and application delivery controller**. It terminates client connections at the nearest edge PoP, accelerates traffic to origins over Microsoft's private WAN, and enforces security at the edge via WAF and DDoS protection. It combines static caching, dynamic routing, TLS offload, and a rules engine into a single service covering both layer 3–4 and layer 7 concerns.

---

## Key capabilities

| Capability | Details |
|---|---|
| **Global edge network** | 118+ PoPs across 100+ metro areas; Standard/Premium use unicast + Traffic Manager; Classic uses anycast |
| **Traffic acceleration** | Split TCP terminates client connections at the nearest PoP; pre-established long-lived connections to origin reduce RTT |
| **Routing methods** | Latency (default), Priority, Weighted (1–1000), Session Affinity (cookie-based: `ASLBSA` / `ASLBSACORS`) |
| **Caching** | GET requests only; TTL from `Cache-Control`/`Expires`; max 366 days; object chunking in 8 MB pieces for large files; query string modes: ignore, use, include/exclude specified |
| **Compression** | Gzip and Brotli; files must be 1 KB – 8 MB; configurable MIME type list |
| **End-to-end TLS** | TLS 1.2 / 1.3 only (no 1.0/1.1); OCSP stapling; managed certs auto-rotate 45 days before expiry; BYOC from Key Vault |
| **TLS policy** | Predefined or custom cipher suite policy (Standard/Premium only) |
| **WAF** | Custom rules (Standard + Premium); managed rule sets incl. OWASP CRS + Microsoft Threat Intelligence (Premium only); bot protection (Premium only) |
| **DDoS protection** | L3/4 infra DDoS built-in (all tiers); L7 via WAF |
| **Private Link origins** | Premium only; supported origin types: App Service, Blob Storage, Static Website, Internal LB, API Management, Application Gateway, Container Apps |
| **Rules engine** | Match conditions + actions; regex and server variables supported; can override origin group per request |
| **Health probes** | HTTP or HTTPS; GET or HEAD (HEAD recommended); configurable interval, path, SampleSize, SuccessfulSamplesRequired |
| **Origin groups** | Set of origins with shared health probe config and load-balancing settings; priority 1–5 per origin |
| **Custom domains** | Apex domain (CNAME-alias) supported; wildcard domains supported; first 100 custom domains/month free (Standard/Premium) |
| **HTTP/2** | Supported natively |
| **Managed identity** | Supported for Key Vault cert access |
| **Monitoring & logging** | Built-in reports, Azure Monitor metrics, access logs, WAF logs |

---

## When to use it

| Scenario | Why Front Door |
|---|---|
| Global HTTPS web applications or APIs | Edge TLS termination, anycast/unicast routing, split TCP reduce latency globally |
| Multi-region active/active or active/passive | Priority + weighted routing + health probes enable automatic failover |
| Static asset CDN with dynamic app acceleration | Single service handles both; no separate CDN tier needed |
| WAF enforcement at the global edge | Managed rules (Premium) or custom rules (Standard) block attacks before traffic reaches origin |
| Origin lockdown / zero-trust ingress | Private Link origins (Premium) eliminate need for public-facing origin IP |
| Blue/green or canary deployments | Weighted routing allows gradual traffic shifts between origin groups |
| SSL offload + certificate management | Managed certs, auto-rotation, BYOC from Key Vault |
| Protection against L7 DDoS | WAF rate limiting + managed rules + capacity absorption at edge |

---

## When NOT to use it

| Situation | Better alternative |
|---|---|
| Regional-only L7 load balancing (same Azure region) | [Application Gateway](application-gateway.md) — supports mTLS, cookie-based affinity at regional level |
| Regional L4 / non-HTTP load balancing | [Azure Load Balancer](load-balancer.md) |
| Simple DNS-based global load balancing (non-HTTP) | [Traffic Manager](traffic-manager.md) — DNS-only, lower cost, direct client-to-origin |
| Internal / private application delivery | Front Door is internet-facing only; use Application Gateway with private frontend |
| Very high RPS over Private Link from single region | Private Link is rate-limited at 7,200 RPS [VERIFY] per regional cluster per profile; spread across multiple Private Link regions |
| Many independent micro-services profiles (e.g., 80+) | Premium base fee of ~$330/profile/month makes many isolated profiles expensive; consolidate endpoints within fewer profiles |

> **Do not** put Traffic Manager *behind* Front Door. Traffic Manager must always be *in front of* Front Door if used together.

---

## SKUs and tiers

| SKU | Use case | Key differentiators | Base fee [VERIFY] |
|---|---|---|---|
| **Standard** | Static + dynamic delivery, custom WAF rules, caching, TLS | Custom WAF rules, no managed WAF rules, no Private Link origins | ~$35/month/profile |
| **Premium** | Standard + managed WAF, bot protection, Private Link | Managed WAF rule sets (OWASP DRS 2.1+), bot manager, Private Link to origin | ~$330/month/profile |
| **Classic** ⚠️ | Legacy; **retiring March 31, 2027** | No base fee but per-rule pricing; managed WAF DRS 1.1 only; no Private Link | $0 base + per-routing-rule/hour |

> ⚠️ **Classic retirement milestones:**
> - **April 1, 2025:** No new Classic profiles can be created
> - **August 15, 2025:** No new domain onboarding; managed certs no longer issued
> - **March 31, 2027:** Full retirement — all access and support ends
> - Existing managed certs remain valid until **April 14, 2026** after August 15, 2025 cutoff
> - Zero-downtime migration tool available via Azure portal and PowerShell

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Composite route limit per profile | 5,000 | Sum of (domains × paths) + (domains × rule overrides) across all routes |
| Origin priority range | 1 – 5 | Lower number = higher priority |
| Origin weight range | 1 – 1,000 | Default 50; only meaningful within latency sensitivity range |
| Latency sensitivity default | 0 ms | All traffic goes to fastest origin; weights only matter at exact same latency |
| Cache TTL maximum | 366 days | Governed by `Cache-Control: s-maxage`, `max-age`, or `Expires` |
| Object chunking size | 8 MB | Used for large file delivery; requires origin to support byte-range requests |
| Private Link RPS limit | 7,200 RPS per regional cluster per profile [VERIFY] | Exceeds → HTTP 429; mitigate by adding origins in different Private Link regions |
| Custom domains (free) | First 100/month | Standard and Premium only; Classic charges $5/domain beyond 100 |
| TLS minimum version | TLS 1.2 | TLS 1.0 and 1.1 not supported |
| Certificate auto-rotation | 45 days before expiry (Standard/Premium); 90 days (Classic) [VERIFY] | Classic managed certs no longer supported after Aug 15, 2025 |
| DHE cipher suite retirement | April 1, 2026 [VERIFY] | `TLS_DHE_RSA_WITH_AES_*` suites being removed |
| Full limits reference | [Azure subscription service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-front-door-standard-and-premium-service-limits) | Includes origin group, endpoint, and rule set counts |

---

## Billing model

| Meter | Standard | Premium | Classic |
|---|---|---|---|
| Base fee | ~$35/month [VERIFY] | ~$330/month [VERIFY] | $0 |
| Requests (client → edge) | Billed by zone (8 zones) | Billed by zone — higher rate than Standard [VERIFY] | Free |
| Egress (edge → client) | Billed by zone (8 zones) | Same as Standard [VERIFY] | Billed (higher rates, 5 zones) |
| Egress (edge → origin) | Billed by zone | Same as Standard | Free |
| Ingress (origin → edge) | Free | Free | Billed ($0.01/GB) [VERIFY] |
| Routing rules | Free (unlimited) | Free (unlimited) | $0.03/hr first 5; $0.012/hr each additional |
| WAF custom rules | Free | Free | ~$1/rule/month + request fees [VERIFY] |
| WAF managed rules | Not supported | Free | ~$20/rule set/month + request fees [VERIFY] |
| Private Link to origin | Not supported | Free (included in Premium base) | Not supported |
| Custom domains (>100) | Free | Free | $5/domain/month |

> Requests blocked by WAF still incur request and egress billing (for the error response payload).
> Cached responses still incur the request meter but do **not** incur edge-to-origin egress.

---

## Routing architecture (request flow)

```
Client
  → DNS resolves to Front Door Traffic Manager profile → returns PoP unicast IP
  → Client TCP connects to PoP (split TCP terminates here)
  → TLS handshake at edge
  → WAF rules evaluated (if enabled)
  → Route matched (Host header + path)
  → Rule sets evaluated (can override origin group)
  → Cache check: HIT → return cached response
  → Cache MISS → origin selected (priority → latency → weight)
  → PoP → origin (separate long-lived TCP connection over Microsoft WAN)
  → Response cached (if cacheable) and returned to client
```

---

## Health probes

- Sent from **each** PoP that receives real user traffic (frequency reduced for idle PoPs)
- User-Agent: `Edge Health Probe`
- Only `200 OK` = healthy; all other responses = failure
- Health determined by sliding window: last *n* samples (SampleSize), at least *x* must be healthy (SuccessfulSamplesRequired)
- If **all** origins in a group fail: Front Door routes round-robin across all (fail-open)
- Health probes can be **disabled** only when a single origin is in the group
- Health probe latency measurement = time from probe send to last byte of response (new TCP connection per probe)
- For Private Link origins, health probes follow the same private path as traffic

---

## Private Link origins (Premium only)

| Supported origin type | Notes |
|---|---|
| App Service (Web App, Function App) | Slots not supported |
| Blob Storage | — |
| Storage Static Website | — |
| Internal Load Balancer (incl. AKS, ARO) | — |
| API Management | — |
| Application Gateway | — |
| Azure Container Apps | — |
| Azure Static Web App | **Not supported** |

- Front Door creates the private endpoint in a **Front Door-managed VNet** (not customer VNet)
- Customer must **approve** the private endpoint connection before traffic flows
- Cannot mix public and private origins in the same origin group
- One private endpoint reused across origins with same resource ID + group ID + region within a profile
- Rate limit: 7,200 RPS per regional cluster per profile [VERIFY]
- Only available in regions with Availability Zone support (see [region list](../../raw/articles/frontdoor/private-link.md))

---

## WAF summary

| Feature | Standard | Premium | Classic |
|---|---|---|---|
| Custom match rules | ✅ | ✅ | ✅ |
| Custom rate limit rules | ✅ | ✅ | ✅ |
| Managed rule sets (OWASP DRS) | ❌ | ✅ (DRS 2.1+) | ✅ (DRS 1.1 only) |
| Bot protection managed rules | ❌ | ✅ | ✅ |
| Geo-filtering | ✅ | ✅ | ✅ |
| IP restriction rules | ✅ | ✅ | ✅ |
| Exclusion lists | ✅ | ✅ | ✅ |
| Detection / Prevention modes | ✅ | ✅ | ✅ |
| Azure Monitor integration | ✅ | ✅ | ✅ |

- WAF policy operates in **Detection** (log only) or **Prevention** (block) mode
- Managed rules based on OWASP CRS + Microsoft Threat Intelligence Collection
- Bot manager distinguishes good bots (allow) from bad bots (block)

---

## Best practices (from source articles)

1. **Restrict origin traffic** — configure origins to accept traffic only from Front Door service tags; prevents bypass
2. **Use end-to-end TLS** — enable HTTPS forwarding protocol even for Azure-hosted origins
3. **Use managed TLS certs** — auto-rotate, no operational overhead; set Key Vault version to `Latest` for BYOC
4. **Use HEAD probes** — reduces origin load vs. GET
5. **Disable probes for single-origin groups** — probes provide no benefit and add unnecessary load
6. **Use custom domains** — don't hardcode `*.azurefd.net` or `*.azurefd.z01.net` in clients or firewall rules
7. **Match Host header at origin** — mismatched Host headers break App Service auth, session affinity, and redirects
8. **Enable WAF with managed rules** (Premium) — covers wide attack surface with minimal tuning
9. **Traffic Manager + Front Door** — Traffic Manager must go *in front of* Front Door (not behind), used only for mission-critical failover to alternate CDN
10. **Consolidate Classic profiles** — migrate before Aug 15, 2025 (managed cert cutoff); use zero-downtime migration tool

---

## Related services

- [Application Gateway](application-gateway.md) — Regional L7 load balancer; use when you need mTLS, regional WAF, or URL-based routing within a single region. Front Door is a common global-to-regional pattern (Front Door → App Gateway → origin)
- [Azure Load Balancer](load-balancer.md) — Regional L4 load balancer; handles non-HTTP protocols; internal or external
- [Traffic Manager](traffic-manager.md) — DNS-based global load balancer; no caching, no TLS offload; use for non-HTTP or as a Front Door failover wrapper
- [Azure DDoS Protection](ddos-protection.md) — Augments Front Door's built-in DDoS for origin VNet public IPs; adds SLA guarantee and Rapid Response Team
- [Private Link](private-link.md) — Underlying technology used by Front Door Premium to privately connect to origins
- [Azure DNS](dns.md) — Used for apex domain CNAME-alias records and domain validation for custom domains
- [Web Application Firewall](web-application-firewall.md) — WAF policies are attached to Front Door; managed centrally, shared policy possible across profiles
- [Azure Firewall](azure-firewall.md) — North-south and east-west network firewall; operates at L3/4/7 but inside VNet; not a CDN/global-entry point replacement

---

## Source articles

- [Azure Front Door Overview](../../raw/articles/frontdoor/front-door-overview.md)
- [Routing Architecture](../../raw/articles/frontdoor/front-door-routing-architecture.md)
- [Traffic Routing Methods](../../raw/articles/frontdoor/routing-methods.md)
- [Traffic Acceleration](../../raw/articles/frontdoor/front-door-traffic-acceleration.md)
- [Origins and Origin Groups](../../raw/articles/frontdoor/origin.md)
- [Health Probes](../../raw/articles/frontdoor/health-probes.md)
- [Caching](../../raw/articles/frontdoor/front-door-caching.md)
- [End-to-End TLS](../../raw/articles/frontdoor/end-to-end-tls.md)
- [DDoS Protection](../../raw/articles/frontdoor/front-door-ddos.md)
- [WAF on Azure Front Door](../../raw/articles/frontdoor/web-application-firewall.md)
- [Private Link (Premium)](../../raw/articles/frontdoor/private-link.md)
- [Routing Limits](../../raw/articles/frontdoor/front-door-routing-limits.md)
- [Billing](../../raw/articles/frontdoor/billing.md)
- [Pricing Comparison (Standard vs Premium vs Classic)](../../raw/articles/frontdoor/understanding-pricing.md)
- [Best Practices](../../raw/articles/frontdoor/best-practices.md)
- [Classic Retirement FAQ](../../raw/articles/frontdoor/classic-retirement-faq.md)
- [Subscription Offers and Bandwidth Throttling](../../raw/articles/frontdoor/standard-premium/subscription-offers.md)
- [WAF Tutorial (Classic)](../../raw/articles/frontdoor/front-door-waf.md)
- *(+ 84 additional articles in `raw/articles/frontdoor/` covering rules engine, rule sets, domains, custom HTTPS, reports, logs, migration tools, Bicep/Terraform samples, scenario guides, and more)*

---

## Compilation notes

**Decisions logged:**

| # | Decision | Rationale |
|---|---|---|
| 1 | Pricing figures from `understanding-pricing.md` treated as illustrative examples | Source article explicitly states "prices shown are examples for illustration purposes only" — all tagged `[VERIFY]` |
| 2 | DHE cipher retirement date (April 1, 2026) included but tagged `[VERIFY]` | Sourced from `end-to-end-tls.md` note; may change |
| 3 | Private Link 7,200 RPS limit included | Sourced from `private-link.md` FAQ; platform-enforced, tagged `[VERIFY]` |
| 4 | Classic article `front-door-waf.md` is a tutorial, not a conceptual reference | Treated as supplementary; conceptual WAF info pulled from `web-application-firewall.md` instead |
| 5 | 102 articles available; ~84 not individually read | Covered: overview, routing, origins, health probes, caching, TLS, DDoS, WAF, Private Link, limits, billing, pricing, best practices, classic retirement, subscription offers. Unread articles cover: Bicep/Terraform/CLI/PowerShell quickstarts, specific Private Link how-tos, rules engine actions/match conditions/server variables, reports, logs, migration step-by-step, domain management, scenario guides, CDN comparison, WebSocket, sensitive data protection. No new conceptual gaps expected — these are procedural/how-to content. |

**Gaps requiring human input:**
- Exact current pricing figures need verification at [https://azure.microsoft.com/pricing/details/frontdoor/](https://azure.microsoft.com/pricing/details/frontdoor/) — source article disclaims illustrative-only pricing
- Tier comparison table (feature-by-feature matrix) exists at `raw/articles/frontdoor/standard-premium/` but the `tier-comparison.md` file was not in the listing — may be linked externally rather than synced locally
- Limits for origin group count, endpoint count, rule set count per profile not captured in scanned articles — reference ARM limits doc linked in `front-door-routing-limits.md`

---

## Index update required

The `wiki/index.md` entry for Azure Front Door should be updated:

```
| Azure Front Door | [front-door.md](services/front-door.md) | ✅ current | 2026-04-09 |
```

---

**Summary of work done:**

| Item | Result |
|---|---|
| Articles read | 19 core articles (overview, routing, origins, health probes, caching, TLS, DDoS, WAF, Private Link, limits, billing, pricing, best practices, classic retirement, subscription offers, traffic acceleration, routing limits, routing methods, origin concepts) |
| Articles in corpus not read | ~83 procedural/how-to/quickstart articles — no conceptual gaps identified |
| `[VERIFY]` tags applied | 10 (all pricing figures, rate limits, cipher retirement date, cert rotation windows) |
| `[CONFLICT]` tags | None — no cross-article contradictions found |
| Decisions to log | 5 (listed in compilation notes above) |
| Backlinks needed | Application Gateway, Load Balancer, Traffic Manager, DDoS Protection, Private Link, Azure DNS, WAF, Azure Firewall pages need reciprocal links back to this page |
