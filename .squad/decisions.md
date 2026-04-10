# Team Decisions

_Maintained by Scribe. Decisions logged chronologically. Each entry records what was decided, by whom, and why._

---

## 2026-04-10 | Atlas | Networking cross-cutting article routing

**Decision:** Route `raw/articles/networking/` articles to existing wiki destinations rather than creating a new "Networking Overview" service page.

**Rationale:** The `networking/` directory is a docset umbrella, not a service. Articles span monitoring, hybrid connectivity, hub-spoke design, zero trust, load balancing overview, and foundational networking. Forcing them into one page creates an oversized, unfocused article. Routing to existing concepts and decision guides preserves the wiki's service-oriented structure.

**Routing map:**
- `network-monitoring-overview.md` → `wiki/concepts/monitoring.md`
- `hybrid-connectivity-overview.md` + `connectivity-interoperability-*.md` → `wiki/concepts/hybrid-connectivity.md`
- `design-secure-hub-spoke-network.md` → `wiki/concepts/hub-spoke-networking.md`
- `security/zero-trust-*.md` (5 articles) → `wiki/concepts/network-security-design.md`
- `azure-for-network-engineers.md`, `networking-overview.md`, et al. → `wiki/concepts/azure-networking-fundamentals.md`
- `load-balancing-content-delivery-overview.md` → `wiki/decisions/load-balancing-options.md`
- `scripts/`, `includes/`, `lumenisity-patent-list.md` → EXCLUDED

**Source:** `.squad/decisions/inbox/atlas-networking-crosscutting.md`

---

## 2026-04-10 | Atlas | ExpressRoute recompile synthesis decisions

**Decisions:** Eight synthesis decisions applied during ExpressRoute recompile (delta: 8 articles post 2025-01-27).

1. Resiliency Insights + Validation added as a dedicated section
2. ErGwScale performance table added alongside existing gateway SKU table
3. IPsec-on-ErGwScale limitation flagged prominently — not supported on ErGwScale
4. Metro locations table added in full (21 locations, site pairs, local regions, ER Direct availability)
5. Circuit migration guidance added — L2/Direct only, does NOT apply to L3 service provider circuits
6. Customer-controlled maintenance behavioral rules added (procedural `[!INCLUDE]` compiled inline)
7. `expressroute-introduction.md` delta minimal — cheat sheet PDF and guided portal note only
8. `evaluate-circuit-resiliency.md` added as manual failover complement to Resiliency Validation

**Conflicts:** Two minor editorial inconsistencies; no `[CONFLICT]` tags applied.

**Gaps for human review:** ErGwScale IPsec limitation roadmap; ErGwScale region availability `[VERIFY]`; Resiliency Insights zone-redundancy score ambiguity; customer-controlled maintenance include files out of scope.

**Source:** `.squad/decisions/inbox/atlas-expressroute.md`

---

## 2026-04-10 | Atlas | Azure Load Balancer recompile synthesis decisions

**Decisions:** Seven synthesis decisions applied during Load Balancer recompile (delta: `whats-new.md` entries post 2025-01-30).

1. Bandwidth metrics Protocol dimension added (December 2025 — TCP=6, UDP=17)
2. Health event logs promoted to GA (February 2025)
3. `numberOfProbes` known issue warning added — property is NOT honored today (active customer impact)
4. New "Retirements and deprecations" section added — Basic LB, numberOfProbes, NAT rule V1, default outbound access
5. Inbound NAT rule V1 retirement added — September 30, 2027; migration path is NAT rule V2
6. Health Status feature (November 2024) added to Key capabilities
7. Gateway LB IPv6 GA (September 2023) added — was missing from prior compile

**Gaps for human review:** 🔴 Default outbound access retirement (March 31, 2026) has passed — wiki notes it in future tense; needs updating to present tense.

**Source:** `.squad/decisions/inbox/atlas-load-balancer.md`

---

## 2026-04-10 | Atlas | Azure Bastion recompile synthesis decisions

**Decisions:** Five synthesis decisions applied during Bastion recompile (delta: `whats-new.md` entries post 2025-01-30).

1. AKS private cluster connectivity added (August 2025 Public Preview)
2. Entra ID for RDP via portal added (November 2025 Public Preview) — cannot be used concurrently with graphical session recording
3. Entra ID RDP capability rows restructured — split into three rows (SSH GA, RDP portal preview, RDP native)
4. Pre-compile `whats-new.md` entries verified as already compiled — no gaps found
5. Source article count updated 41 → 43

**Conflicts:** None.

**Gaps for human review:** AKS private cluster article not fully read (revisit at GA); Entra ID RDP portal preview additional limitations unconfirmed; AZ region list marked `[VERIFY]`.

**Source:** `.squad/decisions/inbox/atlas-bastion.md`

---

## 2026-04-10 | Atlas | Network Security Design concept recompile synthesis decisions

**Decisions:** Seven synthesis decisions applied during Network Security Design recompile (delta: 5 zero-trust articles dated 2026-03-17).

1. Zero Trust hardening checklist restructured into per-service tables with Risk, User impact, Implementation cost columns
2. Zero Trust Assessment tool reference added as NOTE at top of hardening checklist
3. Eight new checklist items added: App GW WAF (request body inspection, HTTP DDoS, rate limiting, JS challenge); Front Door WAF (same + CAPTCHA); DDoS Protection (metrics, logging); Firewall (diagnostic logging)
4. NAT Gateway vs Firewall SNAT port comparison added — 64,512 vs 2,496 ports per IP `[VERIFY]`
5. IDPS and TLS inspection details enriched — IDPS covers all traffic directions; TLS inspection requires CA cert in Key Vault
6. Existing structural sections unchanged — no contradictions from delta articles
7. Source article count updated 7 → 12

**Conflicts:** Two minor — App GW WAF JS challenge risk level (Medium vs implied High); HTTP DDoS rule set as third tier of DDoS defense.

**Gaps for human review:** Zero Trust Assessment tool full scope unknown; App GW WAF JS challenge GA vs Preview status `[VERIFY]`; CAPTCHA on App GW WAF unclear; NAT Gateway SNAT port figure `[VERIFY]`.

**Source:** `.squad/decisions/inbox/atlas-network-security-design.md`

---

_Last updated: 2026-04-10 | Merged by: Scribe_
