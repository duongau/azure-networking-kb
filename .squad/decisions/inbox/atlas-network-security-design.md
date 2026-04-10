# Atlas Decision Log — Network Security Design Concept Recompile

**Date:** 2026-04-10
**Compiler:** Atlas
**Previous compile:** 2025-07-31
**Delta articles read:** 5 (zero-trust-network-security.md, zero-trust-azure-firewall.md, zero-trust-ddos-protection.md, zero-trust-application-gateway-waf.md, zero-trust-front-door-waf.md; all dated 2026-03-17)

---

## Synthesis decisions

1. **Zero Trust hardening checklist restructured into per-service tables with risk/impact/cost.** The existing checklist was a flat table mixing services. The new zero-trust articles (2026-03-17) provide a canonical per-service structure with standardized columns (Risk level, User impact, Implementation cost). The checklist section was fully replaced with this structured format. All existing checklist items are preserved; new items added.

2. **Zero Trust Assessment tool reference added.** `zero-trust-network-security.md` introduces automated programmatic assessment of these checks. Added a note at the top of the hardening checklist. This is a cross-cutting capability reference, not a new Azure networking service — placed as a NOTE rather than a full section.

3. **New checklist items added that were not previously covered:**
   - App GW WAF: Request body inspection, HTTP DDoS rule set, Rate limiting, JavaScript challenge
   - Front Door WAF: Request body inspection, Default rule set, Rate limiting, JavaScript challenge, CAPTCHA challenge
   - DDoS: Metrics enabled, Diagnostic logging enabled (previously only "DDoS Protection enabled" was listed)
   - Firewall: Diagnostic logging enabled

4. **NAT Gateway + Firewall SNAT port comparison added.** `zero-trust-azure-firewall.md` (via include 25535.md) contains a specific and actionable data point: NAT Gateway provides 64,512 SNAT ports per public IP vs. Azure Firewall's 2,496 SNAT ports per public IP per instance. This is directly relevant to the high-traffic Firewall SNAT exhaustion gotcha already documented. Added to the Firewall section of the Zero Trust checklist as a design note.

5. **IDPS and TLS inspection details enriched.** The existing page had these checks in the checklist but without operational detail. The include files (25539.md for IDPS, 25550.md for TLS) provided precise descriptions (IDPS applies to all traffic directions including on-premises; TLS inspection requires CA cert in Key Vault). Added as inline notes in the Firewall checklist rows.

6. **No changes to existing structural sections** (Defense-in-depth model, NSGs/ASGs, Firewall placement patterns, WAF deployment patterns, Common security patterns, Gotchas, Related pages). Those sections were compiled in 2025-07-31 and the delta articles do not contradict or supplement them substantively beyond what is captured in the Zero Trust section.

7. **Source article count updated.** 7 → 12 (added 5 zero-trust articles).

---

## Conflicts detected

- **[CONFLICT — MINOR] App GW WAF JavaScript challenge risk level.** The existing Gotchas section implies WAF Detection mode is the main prevention gap (implicitly High risk). The new `zero-trust-application-gateway-waf.md` rates JavaScript challenge as **Medium** risk (vs. WAF Prevention mode as High). The differentiation is appropriate — JavaScript challenge is an optional defense-in-depth layer, not a baseline control. **Decision:** Tag as Medium in the new table; no change needed to existing content.

- **[CONFLICT — VERIFY] HTTP DDoS rule set classification.** The existing wiki documents WAF protection as OWASP/L7 filtering and DDoS Protection as L3/L4. The `zero-trust-application-gateway-waf.md` introduces an HTTP DDoS rule set on App GW WAF as a distinct control from both. This creates a three-tier DDoS picture: L3/L4 (DDoS Protection), L7 HTTP flood (WAF HTTP DDoS rule set), volumetric + Slowloris (WAF HTTP DDoS rule set). **Decision:** The existing defense-in-depth layer diagram is not wrong, but WAF layer description should note L7 DDoS coverage in a future compile pass. Not a blocking conflict; logged as a future enhancement.

---

## Gaps requiring human input

1. **Zero Trust Assessment tool scope.** The assessment tool is referenced in `zero-trust-network-security.md` but no detail on what it covers beyond these 5 service areas. Does it cover NSGs, Private Endpoints, or VNet configuration? Human should evaluate whether to add a dedicated sub-section.

2. **App GW WAF JavaScript challenge availability.** The include file (27017.md) describes the feature but the article notes it is in Application Gateway WAF. Confirm whether this is GA or Preview for App GW WAF specifically; it is GA for Front Door WAF. [VERIFY]

3. **CAPTCHA challenge for App GW WAF.** `zero-trust-front-door-waf.md` lists CAPTCHA for Front Door only; `zero-trust-application-gateway-waf.md` does not list CAPTCHA. Is CAPTCHA unavailable on App GW WAF or just not recommended? Needs confirmation before adding to App GW section.

4. **NAT Gateway 64,512 ports figure.** Sourced from `zero-trust-azure-firewall.md` include file `25535.md`. This should be cross-verified against the NAT Gateway wiki page limits table to confirm it matches. [VERIFY]
```

---

## Summary of work completed

| # | Service | Priority | Delta articles read | Key additions | Decisions log |
|---|---|---|---|---|---|
| 1 | **ExpressRoute** | 🔴 | 8 | Resiliency Insights scoring formula; Resiliency Validation (failover sim); ErGwScale full perf table + 40 SU max + IPsec limitation; Metro 21-location table; circuit migration guidance; customer-controlled maintenance | `atlas-expressroute.md` |
| 2 | **Azure Load Balancer** | 🟡 | 1 | Protocol dimension on bandwidth metrics; Health event logs GA; `numberOfProbes` known issue warning + probeThreshold migration; Retirements table (3 items); NAT rule V1 retirement; Health Status GA | `atlas-load-balancer.md` |
| 3 | **Azure Bastion** | 🟡 | 1 | AKS private cluster connectivity (Preview); Entra ID RDP portal support (Preview); Entra ID capability rows restructured | `atlas-bastion.md` |
| 4 | **Network Security Design** | 🟡 | 5 | Per-service Zero Trust checklists with risk/impact/cost; Zero Trust Assessment tool; 8 new checklist items; NAT GW + Firewall SNAT comparison (64,512 vs 2,496 ports); IDPS/TLS detail | `atlas-network-security-design.md` |

**`wiki/index.md` also needs updating** — change compiled dates for all four pages to `2026-04-10` and confirm status remains `✅ current`.

**Flags for human review:**
- 🔴 **Default outbound access retirement (March 31, 2026) has now passed** — Load Balancer outbound priority table note is in future tense; needs updating to present tense
- 🟡 **ErGwScale IPsec limitation** — "not currently supported" language; track for roadmap updates
- 🟡 **Resiliency Validation + Metro gap** — Metro users cannot run circuit failover simulation; no known workaround in documentation
- 🟡 **AKS Bastion article not available for full read** — capability noted at feature level only; revisit when GA