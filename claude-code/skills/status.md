Show the current state of all pipelines in session-docs. This is a standalone utility — does NOT route through the orchestrator.

Analyze the input: $ARGUMENTS

---

## What to scan

1. Use Glob to find all `session-docs/*/00-state.md` files
2. For each found, read the file and extract:
   - Feature name (from folder name)
   - Current phase
   - Status (in_progress, waiting, iterating, complete)
   - Iteration count
   - Last completed phase
   - Next action
   - Last updated timestamp
3. Also check for `session-docs/batch-progress.md` — if found, read and include batch status

---

## Display format

### If pipelines found

```
Pipeline Status
===============

| Feature | Phase | Status | Iter | Last Updated | Next Action |
|---------|-------|--------|------|-------------|-------------|
| auth-module | 2-implement | in_progress | 0/3 | 2026-03-08 14:30 | implementer working |
| payments | complete | complete | 1/3 | 2026-03-07 18:00 | none |

Batch: {batch name} — {N}/{total} tasks complete (if batch-progress.md exists)
```

Highlight:
- `iterating` status in bold — needs attention
- `complete` status as done
- Stale pipelines (last updated > 24h ago) — mark as "stale?"

### If no pipelines found

```
No active pipelines in session-docs/.
```

---

## Actions (optional arguments)

- **No args or `list`** — show the table above
- **`<feature-name>`** — show detailed state for one feature: read full `00-state.md` including hot context and recovery instructions
- **`clean`** — list completed pipelines and ask user which to delete

---

## Important

- This skill does NOT route through the orchestrator
- Read-only — never modifies session-docs
- Works even if no `.gitignore` or CLAUDE.md exists
- If `00-state.md` is missing but session-docs folder exists, report the folder as "no state file (legacy?)"
