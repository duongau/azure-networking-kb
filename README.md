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

The output (`wiki/`) is plain markdown — readable in any editor, searchable with grep, and committable to git.

---

## Current status

> **Coverage: 22 / 23 services compiled** as of 2026-04-10. See [`wiki/index.md`](wiki/index.md) for the full index.

| Service | Raw articles | Wiki page | Status |
|---|---|---|---|
| Azure Virtual Network | 128 | `wiki/services/virtual-network.md` | ✅ compiled |
| ExpressRoute | 92 | `wiki/services/expressroute.md` | ✅ compiled |
| VPN Gateway | 107 | `wiki/services/vpn-gateway.md` | ✅ compiled |
| Azure Firewall | 86 | `wiki/services/azure-firewall.md` | ✅ compiled |
| Application Gateway | 175 | `wiki/services/application-gateway.md` | ✅ compiled |
| Azure Load Balancer | 94 | `wiki/services/load-balancer.md` | ✅ compiled |
| NAT Gateway | 27 | `wiki/services/nat-gateway.md` | ✅ compiled |
| Azure Bastion | 41 | `wiki/services/bastion.md` | ✅ compiled |
| Private Link | 48 | `wiki/services/private-link.md` | ✅ compiled |
| DDoS Protection | 32 | `wiki/services/ddos-protection.md` | ✅ compiled |
| Azure DNS | 69 | `wiki/services/dns.md` | ✅ compiled |
| Network Watcher | 64 | `wiki/services/network-watcher.md` | ✅ compiled |
| Azure Front Door | 102 | `wiki/services/front-door.md` | ✅ compiled |
| Traffic Manager | 45 | `wiki/services/traffic-manager.md` | ✅ compiled |
| Virtual WAN | 133 | `wiki/services/virtual-wan.md` | ✅ compiled |
| Azure Route Server | 21 | `wiki/services/route-server.md` | ✅ compiled |
| Web Application Firewall | 77 | `wiki/services/web-application-firewall.md` | ✅ compiled |
| Azure Firewall Manager | 27 | `wiki/services/firewall-manager.md` | ✅ compiled |
| Virtual Network Manager | 52 | `wiki/services/virtual-network-manager.md` | ✅ compiled |
| Internet Peering | 23 | `wiki/services/internet-peering.md` | ✅ compiled |
| Peering Service | 9 | `wiki/services/peering-service.md` | ✅ compiled |
| Network Function Manager | 8 | `wiki/services/network-function-manager.md` | ✅ compiled |
| Networking (cross-service) | 77 | — | 🔲 not started |

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
│   ├── manifest.json        # Tracks ingested articles + last-synced dates
│   └── articles/            # Source articles copied from azure-docs-pr (23 services)
├── wiki/
│   ├── index.md             # Master index — start here
│   ├── services/            # Per-service compiled summaries
│   ├── concepts/            # Cross-cutting concepts (routing, hybrid, security, etc.)
│   ├── decisions/           # Decision guides (which service to use when?)
│   └── limits-and-skus/     # SKU comparisons and service limits reference
├── scripts/
│   └── sync-raw.ps1         # Sync networking articles from azure-docs-pr
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

- To add new source articles: run `sync-raw.ps1 -Services @('service-name')`
- To trigger a wiki recompile: ask Atlas via Copilot CLI
- To report a wiki issue: open a GitHub issue with label `wiki-gap` or `wiki-stale`
- To run a health check: `Lore, run a full wiki health check and write findings to wiki/health-report.md`
