# Atlas Decision Log — Azure Load Balancer Recompile

**Date:** 2026-04-10
**Compiler:** Atlas
**Previous compile:** 2025-01-30
**Delta articles read:** 1 (whats-new.md, entries post 2025-01-30)

---

## Synthesis decisions

1. **Bandwidth metrics Protocol dimension added to monitoring table.** December 2025 feature: SYN Count, Byte Count, and Packet Count metrics now publish a Protocol dimension (TCP=6, UDP=17). Updated the monitoring table Notes column and the key capabilities Diagnostics row.

2. **Health event logs promoted to GA.** February 2025 (just after previous compile). Already partially referenced in existing wiki (Network Watcher related services bullet). Added explicit entry to Key capabilities table and a new note in the Monitoring metrics section.

3. **`numberOfProbes` known issue added prominently to Health probes section.** This is a current known issue (not a future change): the property is NOT honored today. Placed a warning block in the Health probes section directly, not just in retirements, because it affects any team currently relying on the threshold behavior. Also added to Key operational guidance.

4. **New "Retirements and deprecations" section added.** Consolidates three active retirement timelines: Basic LB (passed), numberOfProbes (2027), NAT rule V1 (2027), and default outbound access (2026). The default outbound access retirement was already noted in the Outbound connectivity priority section; duplicated in the new retirements table for discoverability.

5. **Inbound NAT rule V1 retirement added.** September 30, 2027. Applies to VMs and VMSS. Migration path is to NAT rule V2. Added to retirements table and operational guidance.

6. **Health Status feature (November 2024) added.** This is just before the prior compile date (2025-01-30) but was not in the previous page. Added to Key capabilities table.

7. **Gateway LB IPv6 GA (September 2023) added to Gateway LB specifics table.** Was missing from the IPv6 row in the Gateway LB section.

---

## Conflicts detected

- **None.** The `whats-new.md` entries are additive (new features, retirements). No contradictions with existing compiled content.

---

## Gaps requiring human input

1. **`probeThreshold` property details** — `whats-new.md` directs to API version 2022-05-01+ and the `probeThreshold` property but full behavior details (threshold range, default value) are in the probe how-to articles not read in this delta. Flagged in Health probes section for follow-up.
2. **NAT rule V2 migration guidance** — referenced in retirements table but the migration article (`inbound-nat-rule-v2-migration.md` or similar) was not in delta scope. Link goes to `go.microsoft.com/fwlink/?linkid=2286671`; internal article name unknown.
3. **Default outbound access retirement March 2026** — this date has now passed (current date 2026-04-10). The wiki says "retiring March 31, 2026 for new VNets." This has now taken effect. **Human action needed:** Verify current behavior for new VNets created after March 31, 2026 and update the outbound priority table note from future tense to present tense.
```

---

## 📋 DECISIONS LOG 3

**File:** `.squad/decisions/inbox/atlas-bastion.md`

```markdown