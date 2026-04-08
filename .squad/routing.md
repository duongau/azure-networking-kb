# Routing

## Who handles what

| Task type | Agent |
|---|---|
| Compile raw articles into wiki pages | Atlas |
| Update existing wiki pages from new raw content | Atlas |
| Rebuild wiki/index.md | Atlas |
| Health check (links, freshness, gaps) | Lore |
| Write health-report.md | Lore |
| Flag stale wiki pages | Lore |
| Log decisions | Scribe |
| Triage incoming issues | Atlas (squad lead) |

## Escalation

If Atlas finds conflicting information across raw articles, it flags with `[CONFLICT]` and logs to `.squad/decisions/inbox/atlas-conflict-{slug}.md`. Lore does not resolve conflicts — it flags them. Resolution requires human review.
