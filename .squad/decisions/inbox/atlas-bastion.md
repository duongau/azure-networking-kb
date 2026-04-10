# Atlas Decision Log — Azure Bastion Recompile

**Date:** 2026-04-10
**Compiler:** Atlas
**Previous compile:** 2025-01-30
**Delta articles read:** 1 (whats-new.md, entries post 2025-01-30)

---

## Synthesis decisions

1. **AKS private cluster connectivity added.** August 2025 Public Preview. Bastion tunneling command connects to AKS private clusters without requiring a VPN or jump host. Added to Key capabilities table and "When to use it" table. Noted as Public Preview — limitation: N/A per source (no specific limitations listed beyond preview status).

2. **Microsoft Entra ID for RDP (portal) added.** November 2025 Public Preview. The existing wiki already captured Entra ID for RDP via native client; the portal-based RDP Entra ID is new and distinct. Key limitation: cannot be used concurrently with graphical session recording. Updated the existing Entra ID auth row to split SSH and RDP portal entries clearly.

3. **Entra ID RDP row restructured.** The previous wiki had a single row: "Entra ID for SSH (Linux) via portal and native client; Entra ID for RDP via native client only." Split into three rows (SSH GA, RDP portal preview, RDP native) for clarity.

4. **whats-new.md entries before 2025-01-30 confirmed already compiled.** Verified: Graphical session recording GA (Nov 2024), Private Only GA (Nov 2024), Premium SKU GA (June 2024), Entra ID SSH GA (Nov 2024), Developer GA (May 2024), AZ preview (May 2024) — all pre-compile. No content gaps found from those entries.

5. **Source article count updated.** 41 → 43 (added whats-new.md as delta read; added bastion-connect-to-aks-private-cluster.md; added reference to bastion-entra-id-authentication.md).

---

## Conflicts detected

- **None.** Bastion whats-new.md entries are purely additive.

---

## Gaps requiring human input

1. **AKS private cluster connectivity details** — `bastion-connect-to-aks-private-cluster.md` was listed as a delta article but was not provided for reading. Only the `whats-new.md` entry was available. The capability is noted as Public Preview with "N/A" limitations. When this reaches GA, a more detailed entry (required AKS versions, networking requirements, tunneling command syntax) should be compiled from the dedicated article.

2. **Entra ID for RDP portal preview limitations** — `whats-new.md` notes it "cannot be used concurrently with graphical session recording." Are there other limitations (specific OS versions, AAD join requirements, Conditional Access policy requirements)? The dedicated article `bastion-connect-vm-rdp-windows.md#microsoft-entra-id-authentication-preview` was not in delta scope.

3. **Availability Zones region list** — AZ is in Public Preview in "select regions." The region list is in a separate reliability article not in delta scope. Marked [VERIFY] in Service limits table.
```

---

## 📋 DECISIONS LOG 4

**File:** `.squad/decisions/inbox/atlas-network-security-design.md`

```markdown