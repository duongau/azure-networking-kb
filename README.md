# Azure Networking Knowledge Base

> An AI-compiled, human-readable knowledge base for Azure Networking — built on Karpathy's LLM-KB architecture. No vector DB. No embeddings. Just structured markdown maintained by a squad of AI agents.

[![Squad](https://img.shields.io/badge/powered%20by-squad-blueviolet)](https://github.com/duongau/squad)

---

## What is this?

This repo is a **living knowledge base** for Azure Networking content teams. AI agents compile and maintain it:

| Agent | Role |
|---|---|
| **Atlas** | Compiler — reads raw Azure docs articles and compiles them into structured wiki pages |
| **Lore** | Librarian — health-checks the wiki for dead links, stale content, and coverage gaps |
| **Scribe** | Memory manager — merges Atlas decision logs from `.squad/decisions/inbox/` into `.squad/decisions.md` |

The output (`wiki/`) is plain markdown — readable in any editor, searchable with grep, and committable to git.

---

## Current status

> **Coverage: 23 / 23 services · 17 concepts · 10 comparisons · 8 patterns · 4 decision guides · 4 limits/tracking references · 23 source summaries** as of 2026-04-10. See [`wiki/index.md`](wiki/index.md) for the full index.

| Category | Count | Location |
|---|---|---|
| Service pages | 23 | `wiki/services/` |
| Concept pages | 17 | `wiki/concepts/` |
| Comparison pages | 10 | `wiki/comparisons/` |
| Deployment patterns | 8 | `wiki/patterns/` |
| Decision guides | 4 | `wiki/decisions/` |
| Limits & tracking references | 4 | `wiki/limits-and-skus/` |
| Source summaries | 23 | `wiki/sources/` |

<details>
<summary>Services (23/23)</summary>

| Service | Raw articles | Wiki page |
|---|---|---|
| Azure Virtual Network | 128 | `wiki/services/virtual-network.md` |
| ExpressRoute | 92 | `wiki/services/expressroute.md` |
| VPN Gateway | 107 | `wiki/services/vpn-gateway.md` |
| Azure Firewall | 86 | `wiki/services/azure-firewall.md` |
| Application Gateway | 175 | `wiki/services/application-gateway.md` |
| Azure Load Balancer | 94 | `wiki/services/load-balancer.md` |
| NAT Gateway | 27 | `wiki/services/nat-gateway.md` |
| Azure Bastion | 41 | `wiki/services/bastion.md` |
| Private Link | 48 | `wiki/services/private-link.md` |
| DDoS Protection | 32 | `wiki/services/ddos-protection.md` |
| Azure DNS | 69 | `wiki/services/dns.md` |
| Network Watcher | 64 | `wiki/services/network-watcher.md` |
| Azure Front Door | 102 | `wiki/services/front-door.md` |
| Traffic Manager | 45 | `wiki/services/traffic-manager.md` |
| Virtual WAN | 133 | `wiki/services/virtual-wan.md` |
| Azure Route Server | 21 | `wiki/services/route-server.md` |
| Web Application Firewall | 77 | `wiki/services/web-application-firewall.md` |
| Azure Firewall Manager | 27 | `wiki/services/firewall-manager.md` |
| Virtual Network Manager | 52 | `wiki/services/virtual-network-manager.md` |
| Internet Peering | 23 | `wiki/services/internet-peering.md` |
| Peering Service | 9 | `wiki/services/peering-service.md` |
| Network Function Manager | 8 | `wiki/services/network-function-manager.md` |
| Networking (cross-service) | 60 | `wiki/concepts/azure-networking-fundamentals.md` |

</details>

<details>
<summary>Concepts (17), Comparisons (10), Patterns (8), Decision guides (4), Limits (4)</summary>

**Concepts:** Azure Networking Fundamentals · Hub-spoke topology · Hybrid connectivity · IP addressing · Network security design · Routing · Private access to PaaS · Monitoring · SNAT · BGP and dynamic routing · User-defined routes · Network Security Groups · VNet peering · DNS zones and records · Flow logs · Service endpoints · VNet encryption

**Comparisons:** Load balancing options · VPN Gateway vs ExpressRoute · Azure Firewall vs NSG · Azure Firewall SKU comparison · Virtual WAN vs hub-spoke · Private Endpoint vs Service Endpoint · App Gateway vs Front Door · Front Door vs Traffic Manager · DDoS IP vs Network Protection · Private DNS Resolver vs custom DNS

**Patterns:** Hub-spoke with Firewall · NAT Gateway in hub-spoke · Hybrid DNS resolution · ExpressRoute resiliency · Multi-region active-active with Front Door · Zero Trust application delivery · Enterprise-scale hub-spoke with AVNM · Private AKS cluster networking

**Decision guides:** Connectivity options · Load balancing · Firewall & security · Private access

**Limits & tracking:** SKU comparison · Service limits quick reference · Retirement and deprecation tracker · [VERIFY] queue

</details>

---

## Resuming work (Copilot CLI)

This project is maintained using **GitHub Copilot CLI** with the `Content Developer` agent and Atlas sub-agent.

```powershell
cd "C:\GitHub\azure-networking-kb"
# Then say: "hey squad where did we leave off with this?"
```

### Sync raw articles from azure-docs-pr

```powershell
cd "C:\GitHub\azure-networking-kb"
.\scripts\sync-raw.ps1
# Syncs all 23 configured services from C:\GitHub\azure-docs-pr
# To add a new service: .\scripts\sync-raw.ps1 -Services @('new-service-name')
```

### Check for stale wiki pages

```powershell
cd "C:\GitHub\azure-networking-kb"
.\scripts\check-kb-freshness.ps1              # full report across all services
.\scripts\check-kb-freshness.ps1 -StaleOnly   # only services where source is newer than compiled wiki
.\scripts\check-kb-freshness.ps1 -Threshold 30  # only flag if source is >30 days newer
```

### Connected systems

| System | Location | Notes |
|---|---|---|
| **RAG server** | `C:\GitHub\Azure Networking DB\` | Vector DB for semantic search over compiled KB |
| **v4 writing pipeline** | `C:\GitHub\Azure Networking Design\v4-modular-reference\` | Consumes this KB for article drafting |
| **azure-docs-pr** | `C:\GitHub\azure-docs-pr\` | Source of truth for raw articles |

---

## Repo structure

```
azure-networking-kb/
├── raw/
│   ├── manifest.json        # Tracks 1,554 ingested articles + wiki_page mappings
│   └── articles/            # Source articles copied from azure-docs-pr (23 services)
├── wiki/
│   ├── index.md             # Master index — start here
│   ├── log.md               # Chronological operations log
│   ├── ingest-tracker.md    # Per-service sync/compile status
│   ├── health-report.md     # Latest Lore health check output
│   ├── services/            # 23 per-service compiled pages
│   ├── concepts/            # 17 cross-cutting concept pages
│   ├── comparisons/         # 10 side-by-side decision matrices
│   ├── patterns/            # 8 deployment pattern pages with architecture diagrams
│   ├── decisions/           # 4 decision guides (which service to use when?)
│   ├── limits-and-skus/     # 4 reference pages (SKUs, limits, retirements, verify queue)
│   └── sources/             # 23 per-service source summaries (article counts, coverage gaps)
├── scripts/
│   ├── sync-raw.ps1             # Sync networking articles from azure-docs-pr
│   └── check-kb-freshness.ps1   # Staleness detection: compare source ms.date vs wiki compiled date
├── .squad/
│   ├── team.md              # Squad roster
│   ├── decisions.md         # Consolidated team decision log (maintained by Scribe)
│   ├── routing.md           # Agent routing rules
│   └── agents/              # Per-agent charters (Atlas, Lore, Scribe)
├── FORGE-HANDOFF.md         # Re-index instructions for the Networking DB team
└── NEW-KB-PROMPT.md         # Bootstrap prompt for spinning up a new KB squad
```

---

## How it connects to article writing

This KB feeds the **v4 Azure Networking Design Guide** writing pipeline. The Networking Writer squad agent reads `wiki/services/` and `wiki/decisions/` before drafting articles.

```
azure-docs-pr  ──►  raw/articles/  ──►  Atlas  ──►  wiki/services/
                    (sync-raw.ps1)                        │
                                                          ▼
                                          Networking Writer → v4 design guide articles
```

---

## Contributing

| Task | How |
|---|---|
| Add new source articles | `.\scripts\sync-raw.ps1 -Services @('service-name')` |
| Recompile a wiki page | Ask Atlas via Copilot CLI: `"Atlas, recompile {service}"` |
| Run a health check | `"Lore, run a full wiki health check"` |
| Merge decision inbox | `"Scribe, merge the decisions inbox"` |
| Report an issue | Open a GitHub issue with label `wiki-gap` or `wiki-stale` |
