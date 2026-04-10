# Atlas Decision Log — Azure ExpressRoute Recompile

**Date:** 2026-04-10
**Compiler:** Atlas
**Previous compile:** 2025-01-27
**Delta articles read:** 8 (expressroute-introduction, resiliency-insights, resiliency-validation, evaluate-circuit-resiliency, metro, scalable-gateway, circuit-migration, customer-controlled-gateway-maintenance)

---

## Synthesis decisions

1. **Resiliency Insights and Resiliency Validation added as new section.** These two portal features (Nov 2025) are conceptually linked (Insights scores your posture; Validation actively tests it) and warranted a dedicated section rather than scattering across HA patterns and operational guidance. The score formula was reconstructed from `resiliency-insights.md` weight table.

2. **ErGwScale performance table added; existing circuit-connection-count table preserved.** The `scalable-gateway.md` article covers bandwidth/pps/conn-sec performance, while the existing gateway SKU table covers ER circuit connection counts. These are complementary, not conflicting — both are retained.

3. **IPsec on ErGwScale limitation added.** `scalable-gateway.md` explicitly states IPsec traffic over ExpressRoute is not currently supported on ErGwScale. This is a new limitation not previously captured and affects customers relying on IPsec over private peering with the scalable gateway. Tagged as a key limitation.

4. **Metro locations table added in full.** `metro.md` (2026-04-07) is now the authoritative source for metro locations. Added full table with 21 locations, site pairs, local Azure regions, and ER Direct availability. This replaces the prior stub reference.

5. **Circuit migration operational guidance added.** `circuit-migration.md` (2025-01-31) covers L2/Direct circuit migration. Summarized the 5-step process and noted it does NOT apply to L3 service provider circuits (those are handled via provider, not these steps). Added Cisco IOS / Junos examples as a note — full samples remain in raw article.

6. **Customer-controlled maintenance summary added.** `customer-controlled-gateway-maintenance.md` (2025-03-11) content is primarily procedural (portal/PS steps). Summarized key behavioral rules (start date, daily schedule, timing within window, upgrade frequency) in operational guidance.

7. **`expressroute-introduction.md` (2026-03-03) delta:** Article content largely unchanged from what was already compiled. Added reference to the ExpressRoute cheat sheet PDF. Updated guided portal experience note for maximum resiliency. No new capabilities vs. existing wiki.

8. **evaluate-circuit-resiliency.md added as operational guidance.** The manual BGP peering disable method (portal checkbox) is a lightweight complement to the automated Resiliency Validation feature. Added to Resiliency Validation section as "Manual failover alternative."

---

## Conflicts detected

- **[CONFLICT — MINOR]** `resiliency-validation.md` FAQ states the feature is "only available for ExpressRoute virtual network gateways configured in a Max Resiliency model." The body of the article says "at least two distinct peering locations." These are consistent (Max Resiliency = two circuits in different peering locations) but the FAQ wording is more restrictive — it implies the guided portal provisioning flow must have been used. **Decision:** Document the two-circuit-in-distinct-locations prerequisite; add note that it requires the Max Resiliency configuration. No `[CONFLICT]` tag needed; likely editorial inconsistency in source.

- **[CONFLICT — VERIFY]** Resiliency Validation not supported for ExpressRoute Metro (`resiliency-validation.md`), but Metro is scored in Resiliency Insights route score at 10% (`resiliency-insights.md`). So Metro users can see their score but cannot run the simulation test. Both articles agree on their respective scopes — this is intentional product design, not a contradiction. Noted in compile notes.

---

## Gaps requiring human input

1. **ErGwScale IPsec limitation** — `scalable-gateway.md` says "not currently supported." Is this a permanent architectural decision or a roadmap gap? Human should track whether this gets added.
2. **ErGwScale region availability** — the list of 9 unavailable regions may change. Marked `[VERIFY]`; needs periodic refresh.
3. **Resiliency Insights zone-redundancy score for ErGwScale** — `resiliency-insights.md` says "Up to four instances (two scale units): 8%; More than four instances: 10%." Is "four instances" = 4 scale units or 4 gateway instances per SU? Needs clarification from product docs. Compiled as written.
4. **Customer-controlled maintenance include files** — the `customer-controlled-gateway-maintenance.md` article body is mostly `[!INCLUDE]` directives pointing to VPN Gateway shared includes. The actual portal/PS steps are not in raw articles. Behavioral rules were compiled from the inline content only.
```

---

## 📋 DECISIONS LOG 2

**File:** `.squad/decisions/inbox/atlas-load-balancer.md`

```markdown