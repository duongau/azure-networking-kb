# Atlas Decision Log — networking/ cross-cutting articles routing

**Date:** 2026-04-10
**Compiler:** Atlas

## Decision

Route `raw/articles/networking/` articles to existing wiki destinations rather than creating a single "Networking Overview" service page.

## Rationale

The `networking/` directory is a docset umbrella, not a service. Articles span monitoring, hybrid connectivity, hub-spoke design, zero trust, load balancing overview, and foundational networking. Forcing them into one page would create an oversized, unfocused article. Routing to existing concepts and decision guides preserves the wiki's service-oriented structure.

## Routing map

| Articles | Destination |
|---|---|
| `network-monitoring-overview.md` | `wiki/concepts/monitoring.md` (compiled this session) |
| `hybrid-connectivity-overview.md` | `wiki/concepts/hybrid-connectivity.md` |
| `connectivity-interoperability-*.md` (3 articles) | `wiki/concepts/hybrid-connectivity.md` (recompile) |
| `design-secure-hub-spoke-network.md` | `wiki/concepts/hub-spoke-networking.md` (recompile) |
| `security/zero-trust-*.md` (5 articles, dated 2026-03-17) | `wiki/concepts/network-security-design.md` (recompile — HIGH priority, very fresh) |
| `azure-for-network-engineers.md`, `microsoft-global-network.md`, `networking-overview.md`, `network-foundations-overview.md`, `architecture-guides.md`, `azure-network-latency.md`, `nva-accelerated-connections.md` | NEW: `wiki/concepts/azure-networking-fundamentals.md` (stub created) |
| `load-balancing-content-delivery-overview.md` | `wiki/decisions/load-balancing-options.md` decision guide (recompile) |
| `scripts/`, `includes/`, `lumenisity-patent-list.md` | EXCLUDED — not KB reference material |

## Flag

Zero Trust security articles (5 articles, `networking/security/zero-trust-*.md`) are dated **2026-03-17** — extremely fresh. The existing `network-security-design.md` concept page should be recompiled to incorporate these. This is a **high-priority** recompile candidate not previously identified.
