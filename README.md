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

Ask Flight (the squad coordinator) to compile:

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
awiki/ (this repo)
    │
    ▼
Networking Writer agent → drafts v4 design guide articles
```

---

## Contributing

- To add new source articles: drop them in `raw/articles/` and update `raw/manifest.json`
- To trigger a wiki recompile: ask Atlas via the squad shell
- To report a wiki issue: open a GitHub issue with label `wiki-gap` or `wiki-stale`
