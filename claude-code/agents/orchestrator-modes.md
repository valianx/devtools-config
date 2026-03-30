---
name: orchestrator-modes
description: Reference file for orchestrator direct modes (diagram, likec4, d2, review). Read on-demand by the orchestrator — not a standalone agent.
model: opus
color: cyan
---

# Orchestrator — Direct Mode Reference

This file is read on-demand by the orchestrator when executing a direct mode. It is NOT part of the orchestrator's system prompt.

---

## Diagram Mode (Excalidraw)

When invoked with `Direct Mode Task: diagram`:

### Step 1 — Architect analyzes codebase context

Invoke `architect` in **research mode** via Task tool with:
- The diagram request (what to visualize)
- Feature name for session-docs
- Instruction: "Analyze the codebase/system to extract the components, relationships, data flows, and boundaries needed to create a diagram. Focus on: what exists, how pieces connect, and what the visual structure should emphasize. Produce a structured analysis in `session-docs/{feature}/00-research.md` — do NOT produce a diagram."

Gate: if `status: failed` → report to user and stop.

### Step 2 — Invoke diagrammer

Invoke `diagrammer` via Task tool with:
- Feature name
- Path to architect's analysis: `session-docs/{feature}/00-research.md`
- Path to skill: `.claude/skills/excalidraw-diagram/`
- Output path: `session-docs/{feature}/diagram.excalidraw`
- **Expected sections:** list the major sections from the architect's analysis

### Step 2.5 — Validate diagrammer output (MANDATORY)

After the diagrammer returns `status: success`, **read the `.excalidraw` file** and check:

1. **Has arrows** — count elements with `"type": "arrow"`. If 0 → REJECT.
2. **Element count reasonable** — comprehensive diagram should have 80+ elements.
3. **Key components present** — scan text elements for key terms from the analysis.

**If validation fails:** re-invoke diagrammer with specific feedback. Max 2 re-invocations.

### Step 3 — Report to user

Present output file path, summary, and renderer setup instructions if needed:
```bash
cd .claude/skills/excalidraw-diagram/references
uv sync
uv run playwright install chromium
```

---

## LikeC4 Diagram Mode

When invoked with `Direct Mode Task: likec4-diagram`:

### Step 1 — Architect analyzes codebase context

Invoke `architect` in **research mode** via Task tool with:
- The diagram request (what to visualize)
- Feature name for session-docs
- Instruction: "Analyze the codebase/system to extract the components, relationships, data flows, and boundaries needed to create a LikeC4 architecture diagram. Focus on: entry points, services, databases, queues, external dependencies, and actors. Produce a structured analysis in `session-docs/{feature}/00-research.md` — do NOT produce a diagram."

Gate: if `status: failed` → report to user and stop.

### Step 2 — Invoke likec4-diagrammer

Invoke `likec4-diagrammer` via Task tool with:
- Feature name
- Path to architect's analysis: `session-docs/{feature}/00-research.md`
- Path to skill: `.claude/skills/likec4-diagram/`
- Output path: `session-docs/{feature}/diagram.c4`

Gate: if `status: failed` → report to user. If `status: blocked` (CLI not installed) → relay install instructions: `npm install -g likec4` or `npx likec4`.

### Step 3 — Report to user

Present output file path, view names, and how to render:
- Preview: `npx likec4 start`
- Export: `npx likec4 export png`

---

## D2 Diagram Mode

When invoked with `Direct Mode Task: d2-diagram`:

### Step 1 — Architect analyzes codebase context

Invoke `architect` in **research mode** via Task tool with:
- The diagram request
- Feature name for session-docs
- Instruction: "Analyze the codebase/system to extract the components, relationships, data flows, and boundaries needed to create a D2 diagram. Produce a structured analysis in `session-docs/{feature}/00-research.md` — do NOT produce a diagram."

Gate: if `status: failed` → report to user and stop.

### Step 2 — Invoke d2-diagrammer

Invoke `d2-diagrammer` via Task tool with:
- Feature name
- Path to architect's analysis: `session-docs/{feature}/00-research.md`
- Path to skill: `.claude/skills/d2-diagram/`
- Output path: `session-docs/{feature}/diagram.d2`

Gate: if `status: failed` → report to user. If `status: blocked` (d2 not installed) → relay install instructions.

### Step 3 — Report to user

Present source file path, SVG output path, and re-render options:
- Dark theme: `d2 --theme 300 diagram.d2 dark.svg`
- Hand-drawn: `d2 --sketch diagram.d2 sketch.svg`
- Better routing: `d2 --layout elk diagram.d2 elk.svg`

---

## Review Mode

When invoked with `Direct Mode Task: review`:

The `/review-pr` skill handles ALL Bash (fetching PR metadata, git diff, etc.) and passes everything inline. The orchestrator and reviewer do ZERO Bash.

### Step 1 — Receive pre-fetched data

The skill already passed all data inline. Extract:
- PR number, title, body, author, base/head branches, additions/deletions, URL
- Linked issue (number, title, body, labels) or "none"
- Changed files list
- Full diff (may be truncated if >3000 lines)

Zero Bash in this step.

### Step 2 — Invoke reviewer

Invoke `reviewer` in **data-provided mode** via Task tool, passing ALL data inline:

```
mode: data-provided
PR: #{number}
Title: {title}
Author: {author}
Base: {base}
Head: {head}
Additions: +{N}
Deletions: -{N}
URL: {url}
Body: {body}
Linked Issue: #{issue_number} or "none"
Issue Title: {title} or "N/A"
Issue Body: {body} or "N/A"
Issue Labels: {labels} or "N/A"
Changed Files:
{file list}
Full Diff:
{diff}
```

### Step 3 — Build draft

Take `review_body` from the reviewer's status block and write it to `.claude/pr-review-draft.md`.

**Validation:** If `review_body` is empty, re-invoke reviewer once. If still empty, return `status: failed`.

Read `.claude/pr-review-draft.md` back to confirm it was written correctly.

Return to the skill:
```
Review draft written to .claude/pr-review-draft.md
Decision: {APPROVE or CHANGES_REQUESTED}
```

The skill handles user approval and publishing.
