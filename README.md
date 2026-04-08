# Azure Networking Knowledge Base

> An AI-compiled, human-readable knowledge base for Azure Networking — built on Karpathy's LLM-KB architecture. No vector DB. No embeddings. Just structured markdown maintained by a squad of AI agents.

[![Squad](https://img.shields.io/badge/powered%20by-squad-blueviolet)](https://github.com/duongau/squad)

---

## What is this?

This repo is a **living knowledge base** for Azure Networking content teams. Two AI agents compile and maintain it:

| Agent | Role |
|---|---|
| **Atlas** | Compiler — reads raw Azure docs articles and compiles them into structured wiki pages |
| **Lore** | Librarian — health-checks the wiki for dead links, stale content, and coverage gaps |

The output (`wiki/`) is plain markdown — readable in any editor, searchable with grep, and committable to git.

---

## Current status

| Service | Raw articles synced | Wiki page | Status |
|---|---|---|---|
| nat-gateway | 27 ✅ | `wiki/services/nat-gateway.md` | ✅ compiled |
| virtual-network | 128 ✅ | `wiki/services/virtual-network.md` | 🔲 stub |
| dns | 73 ✅ | `wiki/services/dns.md` | 🔲 stub |
| vpn-gateway | 122 ✅ | `wiki/services/vpn-gateway.md` | 🔲 stub |
| expressroute | — | `wiki/services/expressroute.md` | 🔲 stub |
| firewall | — | `wiki/services/azure-firewall.md` | ⚠️ hold (freshness review in-flight) |
| application-gateway | — | `wiki/services/application-gateway.md` | 🔲 stub |
| load-balancer | — | `wiki/services/load-balancer.md` | 🔲 stub |
| bastion | — | `wiki/services/bastion.md` | 🔲 stub |
| private-link | — | `wiki/services/private-link.md` | 🔲 stub |
| ddos-protection | — | `wiki/services/ddos-protection.md` | 🔲 stub |
| network-watcher | — | `wiki/services/network-watcher.md` | ⚠️ hold (orphaned RAG chunks — needs re-index) |

---

## Resuming work (Copilot CLI)

This project is maintained using **GitHub Copilot CLI** with the `Content Developer` agent. To resume:

### 1. Open Copilot CLI in the KB repo or v4 writing project

```powershell
cd "C:\GitHub\azure-networking-kb"
# Launch Copilot CLI with Content Developer agent
```

### 2. Tell Copilot CLI what to do next

Copy-paste this to resume right where we left off:

```
Resume the Azure Networking KB project. The KB repo is at C:\GitHub\azure-networking-kb and the RAG server is running at C:\GitHub\Azure Networking DB. We've already compiled nat-gateway. Next priority is compiling wiki/services/virtual-network.md from raw/articles/virtual-network/ (128 articles). Then dns, then vpn-gateway. After that, sync the remaining 9 services and update the Networking Writer charter in C:\GitHub\Azure Networking Design\v4-modular-reference to reference wiki/ instead of source-design-guide.md.
```

### 3. Sync more raw articles if needed

```powershell
cd "C:\GitHub\azure-networking-kb"
.\scripts\sync-raw.ps1 -Services @('expressroute', 'load-balancer', 'bastion', 'private-link', 'ddos-protection', 'application-gateway', 'networking')
# Note: skip firewall and network-watcher until their issues are resolved
```

### Connected systems

| System | Location | Notes |
|---|---|---|
| **RAG server** | `C:\GitHub\Azure Networking DB\` | 8,452 chunks, 1,985 docs. API key configured in `C:\Users\duau\.copilot\mcp-config.json` |
| **v4 writing pipeline** | `C:\GitHub\Azure Networking Design\v4-modular-reference\` | Squad project that consumes this KB |
| **azure-docs-pr** | `C:\GitHub\azure-docs-pr\` | Source of truth for raw articles |
| **Squad framework** | `https://github.com/duongau/squad` | Agent engine used in both projects |

---

## Quick start (for colleagues)

### 1. Clone and install squad

```bash
git clone https://github.com/duongau/azure-networking-kb
cd azure-networking-kb
npm install -g @bradygaster/squad-cli
squad init
```

### 2. Open in VS Code with Copilot

Open the folder in VS Code and select the **Squad** agent in Copilot Chat.

### 3. Compile the wiki

Ask Atlas (the squad lead) to compile:

```
Atlas, compile all services in raw/articles/networking/ into wiki/services/
```

### 4. Run a health check

```
Lore, run a full wiki health check and write findings to wiki/health-report.md
```

---

## Repo structure

```
azure-networking-kb/
├── raw/
│   ├── manifest.json        # Tracks ingested articles + last-synced dates
│   └── articles/            # Source articles from azure-docs-pr
├── wiki/
│   ├── index.md             # Master index — start here
│   ├── services/            # Per-service compiled summaries
│   ├── concepts/            # Cross-cutting concepts (routing, hybrid, security)
│   ├── decisions/           # Decision guides (which service to use when?)
│   └── limits-and-skus/     # SKU comparisons and service limits
├── scripts/
│   └── sync-raw.ps1         # Sync networking articles from azure-docs-pr
└── .squad/                  # Squad agent charters and state
```

---

## How it connects to article writing

This KB feeds the **v4 Azure Networking Design Guide** writing pipeline. The Networking Writer squad agent reads `wiki/services/` and `wiki/decisions/` before drafting articles — replacing the manual `source-design-guide.md`.

```
wiki/ (this repo)
    │
    ▼
Networking Writer agent → drafts v4 design guide articles
```

---

## Contributing

- To add new source articles: drop them in `raw/articles/` and update `raw/manifest.json`
- To trigger a wiki recompile: ask Atlas via the squad shell
- To report a wiki issue: open a GitHub issue with label `wiki-gap` or `wiki-stale`
