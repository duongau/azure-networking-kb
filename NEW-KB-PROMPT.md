# Prompt: Bootstrap a new LLM Knowledge Base

Use this prompt with GitHub Copilot CLI (or any capable agent) to build a new KB in the same style as `azure-networking-kb`. Replace all `{PLACEHOLDER}` values before using.

---

## The prompt

```
I want to build a new LLM knowledge base in the style of azure-networking-kb.

**Domain:** {e.g. Microsoft Writing Style Guide, Contributor Guide, Azure Well-Architected Framework}
**Source material location:** {e.g. C:\GitHub\MicrosoftDocs\contributor-guide\, or a URL to scrape}
**Output repo:** {e.g. C:\GitHub\style-guide-kb\}
**Squad name:** {e.g. style-kb-squad}

## What I want built

A repo with this structure:
```
{repo-name}/
├── raw/
│   ├── manifest.json        # Tracks all ingested source articles
│   └── articles/            # Source material organized by topic area
├── wiki/
│   ├── index.md             # Master index — start here
│   ├── log.md               # Chronological operations log
│   ├── health-report.md     # Latest health check output
│   ├── services/            # OR topics/ — one compiled page per major topic area
│   ├── concepts/            # Cross-cutting concept pages
│   ├── comparisons/         # Decision matrices (when to use X vs Y)
│   ├── patterns/            # How-to pattern pages with examples
│   ├── decisions/           # Decision guides (which approach to use when)
│   ├── limits-and-skus/     # Reference tables (rules, limits, checklists)
│   └── sources/             # Per-topic source summaries
├── scripts/
│   ├── sync-raw.ps1         # Sync source articles into raw/
│   └── check-kb-freshness.ps1  # Detect stale wiki pages
├── .squad/
│   ├── team.md              # Squad roster
│   ├── decisions.md         # Consolidated team decision log
│   ├── routing.md           # Which agent handles what
│   ├── decisions/inbox/     # Unmerged agent decision logs
│   └── agents/
│       ├── atlas/charter.md # Compiler agent instructions
│       ├── lore/charter.md  # Health-check agent instructions
│       └── scribe/charter.md # Memory manager agent instructions
└── README.md
```

## Squad to create

### Atlas ({domain} Compiler)
- Reads raw source articles from `raw/articles/`
- Compiles them into structured wiki pages
- Style: dense, table-heavy, prefers structure over prose
- Tags `[VERIFY]` on any claim that should be confirmed against the live source
- Tags `[CONFLICT]` when sources contradict each other and logs to `.squad/decisions/inbox/`
- Follows this wiki page format for every topic page:
  - What it is (2-3 sentences)
  - Key rules / principles (table)
  - When to use it / when not to
  - Examples (good vs bad where applicable)
  - Related pages (with backlinks)
  - Source articles

### Lore ({domain} Librarian)
- Runs health checks on `wiki/` on demand
- Checks: dead links, stale compiled dates (>6 months), missing backlinks, coverage gaps
- Writes findings to `wiki/health-report.md` with severity (🔴 Blocker / 🟡 Warning / 🟢 Info)
- Never edits wiki pages — only reports

### Scribe (Memory Manager)
- Merges `.squad/decisions/inbox/*.md` into `.squad/decisions.md`
- Runs on demand, not on a schedule
- Silent — no output unless asked

## First session tasks

1. **Create the repo structure** — all folders and placeholder files
2. **Write all squad charters** — adapted for this domain (not Azure Networking)
3. **Write sync-raw.ps1** — adapted to copy/scrape source material into raw/articles/
4. **Write check-kb-freshness.ps1** — compare source file dates vs wiki compiled dates
5. **Build raw/manifest.json** — scan source material and build the manifest
6. **Identify the topic areas** — what are the major sections? (equivalent to "services" in azure-networking-kb)
7. **Have Atlas compile the first 3-5 topic pages** as a quality check before doing all of them
8. **Write wiki/index.md** with the full topic list and status
9. **Write README.md** with current coverage and how to use the KB

## Quality bar

Every compiled page should be BETTER than reading the source articles directly. It should:
- Synthesize across multiple source articles (not just copy-paste)
- Surface rules/principles in scannable tables
- Call out gotchas and exceptions explicitly
- Link to related pages
- Flag anything unverified with [VERIFY]

## What I DON'T want

- Summaries that just restate the source article headings
- Empty sections (use "Not applicable" or remove the section)
- Invented content — only compile from what's in raw/
- A static snapshot — the KB should be maintainable and updatable

---

Start by reading the source material at {source location} and proposing the topic structure (the equivalent of "services" in azure-networking-kb). Show me a proposed index before compiling anything.
```

---

## Tips for specific domains

### Microsoft Writing Style Guide / Contributor Guide
- **Source:** `C:\GitHub\MicrosoftDocs\docs-help-pr\` (already synced locally via contributor-guide-rag)
- **Topic areas:** article types, metadata, markdown conventions, platform features, Acrolinx, TOC/navigation, accessibility, voice/tone
- **Comparisons to build:** how-to vs tutorial vs concept vs quickstart; ms.topic values; include vs snippet vs code block
- **Patterns to build:** standard article templates for each article type
- **Limits pages:** required metadata fields, character limits, Acrolinx score thresholds

### Azure Well-Architected Framework
- **Source:** `C:\GitHub\azure-docs-pr\well-architected\`
- **Topic areas:** reliability, security, cost optimization, operational excellence, performance efficiency
- **Comparisons:** WAF pillars vs CAF landing zones; reliability tiers
- **Patterns:** WAF review checklist patterns per workload type

### Content team onboarding
- **Source:** your team wiki, onboarding docs, style guides
- **Topic areas:** tools setup, workflows, PR process, writing standards, publishing pipeline
- **Goal:** new team member can answer 90% of questions from the KB without asking anyone
