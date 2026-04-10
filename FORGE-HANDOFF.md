# Forge handoff — azure-networking-kb re-index

**Date:** 2026-04-10  
**From:** Azure Networking content squad  
**To:** Forge / Networking DB team  
**Repo:** `github.com/duongau/azure-networking-kb`

---

## What happened

The Azure Networking KB had a major build-out session. The wiki went from partial coverage to fully built. You need to pull and re-index.

## Action required

```powershell
cd "C:\GitHub\azure-networking-kb"
git pull   # current HEAD: 506d4a6
```

Then re-embed all new/updated files in `wiki/`. Use the `rag-embeddings` skill for incremental update — it will only re-embed what changed.

---

## What's new since your last index (commits 228a141 → 9464044)

### New files (37 total)

**wiki/sources/** — 23 new source summary pages (one per service):
- application-gateway-docs.md, bastion-docs.md, ddos-protection-docs.md, dns-docs.md
- expressroute-docs.md, firewall-docs.md, firewall-manager-docs.md, frontdoor-docs.md
- internet-peering-docs.md, load-balancer-docs.md, nat-gateway-docs.md
- network-function-manager-docs.md, network-watcher-docs.md, networking-docs.md
- peering-service-docs.md, private-link-docs.md, route-server-docs.md
- traffic-manager-docs.md, virtual-network-docs.md, virtual-network-manager-docs.md
- virtual-wan-docs.md, vpn-gateway-docs.md, web-application-firewall-docs.md

**wiki/concepts/** — 4 new concept pages:
- dns-zones-and-records.md
- flow-logs.md
- service-endpoints.md
- vnet-encryption.md

**wiki/comparisons/** — 3 new comparison pages:
- front-door-vs-traffic-manager.md
- ddos-ip-vs-network-protection.md
- private-dns-resolver-vs-custom-dns.md

**wiki/limits-and-skus/** — 2 new reference pages:
- retirement-tracker.md ← high-value; tracks all Azure Networking retirements by date
- verify-queue.md ← 752 unverified claims across 53 files

**wiki/patterns/** — 4 new deployment pattern pages:
- multi-region-front-door.md
- zero-trust-app-delivery.md
- avnm-enterprise-scale.md
- private-aks-networking.md

**wiki/ingest-tracker.md** — per-service sync/compile status table

### Updated files

**wiki/services/web-application-firewall.md** — full recompile from 77 fresh articles (474 lines)
- Previous version was compiled from 2020-era articles
- Now includes: WAF Copilot integration, JavaScript challenge, CRS 3.2 updates, Sentinel integration, new bot protection, geomatch custom rules

---

## Current KB state (for your records)

| Category | Count |
|---|---|
| Services | 23 |
| Concepts | 17 |
| Comparisons | 10 |
| Patterns | 8 |
| Decision guides | 4 |
| Limits/tracking references | 4 |
| Source summaries | 23 |
| **Total wiki pages** | **~89** |

---

## Notes

- The `raw/articles/web-application-firewall/` directory was also refreshed (77 articles re-synced from azure-docs-pr). If your RAG DB indexes raw articles directly, re-embed those too.
- `raw/manifest.json` is updated — 1,554 articles, all with `wiki_page` mappings.
- The `wiki/limits-and-skus/verify-queue.md` page lists values that haven't been verified against live Azure docs. Don't use those specific numbers as authoritative in RAG responses without flagging uncertainty.
