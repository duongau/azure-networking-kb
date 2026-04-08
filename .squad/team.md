# Azure Networking KB — Squad Roster

| Name | Role | Charter |
|---|---|---|
| **Atlas** ⭐ | **Squad lead** + Compiler — ingests raw/ and writes wiki/ | [charter](agents/atlas/charter.md) |
| Lore | Librarian — health-checks wiki/ | [charter](agents/lore/charter.md) |
| Scribe | Silent memory manager — logs decisions | [charter](agents/scribe/charter.md) |

## Squad purpose

This squad maintains the Azure Networking LLM Knowledge Base. It does not write Azure documentation. It compiles, organizes, and validates structured knowledge from existing Azure docs so that content teams can use it as a source of truth.

## External systems this squad depends on

### RAG database (`azure-networking-rag` MCP server)
- **Location:** `C:\GitHub\Azure Networking DB\`
- **MCP server:** `C:\GitHub\Azure Networking DB\mcp-server\server.py`
- **What it is:** 8,452 chunks across 1,985 docs, 36 services — a vector search index over all Azure Networking articles
- **Atlas uses it:** to cross-check and enrich wiki compilations before writing
- **Lore uses it:** to detect RAG drift (wiki compiled date vs RAG last-indexed date)

### Scheduled sync (`AzureNetworkingRAGSync`)
- **What it is:** Windows Scheduled Task that runs `incremental_update.py` twice daily
- **Schedule:** 10:30am and 3:30pm PST (30 min after Microsoft Learn publish windows)
- **Script:** `C:\GitHub\Azure Networking DB\scripts\Setup-ScheduledSync.ps1 -RunNow`
- **Log:** `C:\GitHub\Azure Networking DB\vectorstore\sync_log.txt`
- **What it does:** Detects changed `.md` files in azure-docs-pr via git diff, re-embeds only changed chunks
- **Squad implication:** After each sync run, newly updated articles may trigger a wiki recompile request to Atlas

### Raw article sync (`scripts/sync-raw.ps1`)
- **What it is:** PowerShell script that copies articles from azure-docs-pr into `raw/articles/`
- **Run manually** before asking Atlas to compile a service
- **Squad implication:** `raw/manifest.json` tracks what's been synced and when
