# KB → RAG DB Re-Embedding Protocol

**For:** Azure Networking KB squad (Atlas, Lore)
**From:** Azure Networking DB (Forge)
**Date:** 2026-04-10

---

## The problem

When Atlas compiles new or updated wiki pages, the KB vectorstore in the DB repo goes stale. The `search_kb` MCP tool returns outdated results until the KB is re-embedded.

## When to trigger a re-embed

After **any** of these events:
1. Atlas compiles new wiki pages (new services, new comparisons, etc.)
2. Atlas rewrites existing wiki pages (updated content, new sections)
3. Bulk wiki restructure (pages renamed, merged, or split)

**Not needed for:** health report updates, index.md badge changes, raw/ syncs that don't result in wiki changes.

## How to trigger it

### Option A: Write a FORGE-HANDOFF.md (current process)

Create or update `FORGE-HANDOFF.md` in the KB repo root with:

```markdown
# Forge handoff — KB re-embed needed

**Date:** {today}
**Trigger:** {what changed — e.g., "Atlas compiled 5 new service pages"}
**Commit range:** {old_sha} → {new_sha}

## Changed wiki files
- wiki/services/{file}.md (new)
- wiki/comparisons/{file}.md (updated)
- ...
```

Forge (the DB squad) picks this up and runs the re-embed pipeline.

### Option B: Direct script call (if you have access to the DB repo)

```powershell
cd "C:\GitHub\Azure Networking DB"

# 1. Pull latest KB wiki content
cd "C:\GitHub\azure-networking-kb"
git pull

# 2. Re-run the KB embedding pipeline
cd "C:\GitHub\Azure Networking DB"
python scripts/generate_embeddings.py --source kb
```

> **Note:** This requires `AZURE_OPENAI_API_KEY` and `AZURE_OPENAI_ENDPOINT` environment variables. The embedding cache handles dedup — unchanged pages won't re-embed.

## What the DB repo does with it

1. Harvests `wiki/` folder from `azure-networking-kb`
2. Chunks each wiki page (heading-based, same pipeline as public docs)
3. Embeds new/changed chunks via Azure OpenAI `text-embedding-3-large`
4. Rebuilds the `azure_networking_kb` LanceDB table (currently 450 chunks)
5. The `search_kb` MCP tool immediately serves updated results

## Architecture reference

```
azure-networking-kb repo          Azure Networking DB repo
┌─────────────────────┐          ┌────────────────────────────┐
│ raw/ (source docs)  │          │ vectorstore/               │
│   ↓ Atlas compiles  │          │   azure_networking_docs    │
│ wiki/ (compiled KB) │───re-embed──→ azure_networking_kb     │
│   ↓ Lore checks     │          │                            │
│ health-report.md    │          │ mcp-server/server.py       │
└─────────────────────┘          │   search_networking_docs() │
                                 │   search_kb()  ← NEW      │
                                 └────────────────────────────┘
```

## Lore's role

Lore should add a check to the health report:
- Compare the last KB re-embed date (from `vectorstore/embeddings_checkpoint.json`) against the latest wiki page compiled dates
- If any wiki page was compiled **after** the last re-embed → flag as 🟡 Warning: "KB vectorstore stale — re-embed needed"

## Current stats

| | |
|---|---|
| KB table | `azure_networking_kb` — 450 chunks |
| Categories | kb-services, kb-concepts, kb-comparisons, kb-decisions, kb-patterns, kb-limits-and-skus, kb-sources |
| Embedding model | text-embedding-3-large (3072 dims) |
| MCP tool | `search_kb` (v1.8.0) |
