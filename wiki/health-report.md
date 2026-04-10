# Wiki Health Report

> **Generated:** 2026-04-10 | **Analyst:** Lore | **Requested by:** Atlas

---

## Coverage Summary

| Layer | Total pages | ✅ Current | 🔲 Stub | ❌ Missing |
|---|---|---|---|---|
| Services | 23 tracked | 22 | 0 | 1 (networking/ cross-cutting — design decision pending) |
| Concepts | 7 tracked | 5 | 2 → **compiled this session** | 0 |
| Decision guides | 4 tracked | 4 | 0 | 0 |
| Limits & SKUs | 2 tracked | 1 | 1 → **compiled this session** | 0 |

---

## Staleness Flags

Pages marked `✅ current` in the index but whose compile date is ≥ 12 months old AND whose raw articles contain meaningful post-compile changes:

| Service | Compiled | Age | Evidence of post-compile changes | Verdict |
|---|---|---|---|---|
| ExpressRoute | 2025-01-27 | ~15 months | Raw `expressroute-introduction.md` ms_date 2026-03-03; new articles: `resiliency-insights.md`, `resiliency-validation.md`, `evaluate-circuit-resiliency.md`, `metro.md`, `scalable-gateway.md`, `circuit-migration.md`, `customer-controlled-gateway-maintenance.md` all post-compile | 🔴 **RECOMPILE — significant new content** |
| Azure Load Balancer | 2025-01-30 | ~14 months | `whats-new.md`: bandwidth metrics Protocol dimension (Dec 2025), health event logs GA (Feb 2025 — right after compile); new retirements: numberOfProbes property (Sep 2027), Inbound NAT rule V1 (Sep 2027) | 🟡 **RECOMPILE — minor but several features missing** |
| Azure Bastion | 2025-01-30 | ~14 months | `whats-new.md`: AKS private cluster connectivity (Aug 2025), Entra ID for RDP in portal (Nov 2025 preview), Availability Zones public preview (May 2024 — potentially included) | 🟡 **RECOMPILE — at least 2 features missing** |
| Azure Firewall | 2025-07-14 | ~9 months | Moderate staleness; no critical evidence found in this check | 🟢 OK — monitor |
| Network Watcher | 2025-07-14 | ~9 months | Moderate staleness; VNet flow logs GA noted in wiki already | 🟢 OK — monitor |
| Application Gateway | 2025-07-15 | ~9 months | Moderate staleness | 🟢 OK — monitor |
| Private Link | 2025-07-30 | ~8.5 months | NSP feature GA status evolving; PLS Direct Connect in public preview post-compile | 🟢 OK — monitor |

---

## Structural / Quality Issues Found

### Issue 1 — CRITICAL: `wiki/services/load-balancer.md` contains embedded draft notes

Lines 264–304 in `load-balancer.md` contain compilation draft artifacts — an `Updated wiki/index.md entry` section and a `Decisions log → .squad/decisions/inbox/atlas-load-balancer.md` section — rendered inside the wiki page as triple-backtick code blocks. These are compiler working notes that were accidentally included in the published page. They have been removed and the decisions log content moved to `.squad/decisions/inbox/atlas-load-balancer.md`.

### Issue 2 — manifest.json: all `wiki_page` fields are null

Every article in `manifest.json` has `"wiki_page": null`. This breaks programmatic traceability from raw article → compiled wiki page. See Manifest Fix section below.

### Issue 3 — manifest.json: `source_paths` array incomplete

The manifest `source_paths` array lists only 13 paths, missing 10 services that have raw articles and compiled wiki pages. See Manifest Fix section below.

### Issue 4 — atlas/history.md: no compilation runs logged

`.squad/agents/atlas/history.md` contains "No compilation runs yet" despite 22+ service pages being compiled. Recommend back-filling with known compile dates from `wiki/index.md`.

### Issue 5 — Scribe decisions inbox: empty

`.squad/decisions.md` has no entries. Either decisions were made but not logged, or compilation work predates the decision-logging infrastructure.

### Issue 6 — Concepts: `private-access-to-paas.md` and `monitoring.md` were stubs

**Resolved this session** — both compiled.

### Issue 7 — Limits: `service-limits-quick-reference.md` was a stub

**Resolved this session** — compiled.

### Issue 8 — Backlink reciprocity not verified

Full backlink audit not performed. Recommend Atlas run a targeted backlink check on services compiled before 2025-06-01 (ExpressRoute, Load Balancer, Bastion) as part of their recompile.

---

## Recommended Actions (Prioritized)

| Priority | Action | Owner | Status |
|---|---|---|---|
| P1 | Remove draft artifacts from `load-balancer.md` lines 264–304 | Human/Atlas | ✅ Done this session |
| P1 | Recompile ExpressRoute — 15 months old, significant new raw articles | Atlas | 🔜 Next session |
| P2 | Recompile Load Balancer — new features, retirement notices post-compile | Atlas | 🔜 Next session |
| P2 | Recompile Bastion — AKS connectivity, Entra ID RDP missing | Atlas | 🔜 Next session |
| P2 | Recompile `network-security-design.md` — 5 new Zero Trust articles (2026-03-17) | Atlas | 🔜 Next session |
| P2 | Fix manifest.json `source_paths` and back-populate `wiki_page` fields | Atlas | 🔜 Next session |
| P3 | Compile `azure-networking-fundamentals.md` stub | Atlas | 🔜 Next session |
| P3 | Back-fill atlas/history.md with known compile dates | Atlas | 🔜 Next session |
| P3 | Initialize Scribe decisions log with synthesis decisions from past compilations | Scribe | 🔜 Next session |
| P3 | Run full backlink audit on all pre-June-2025 service pages | Atlas | 🔜 Next session |
| P3 | Recompile hub-spoke-networking.md (new cross-service design article) | Atlas | 🔜 Next session |
| P3 | Recompile hybrid-connectivity.md (3 interoperability articles) | Atlas | 🔜 Next session |
