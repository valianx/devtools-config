---
name: ref-special-flows
description: Reference file for orchestrator special flows (research, spike, plan, parallel dispatch, refactor, simple). Read on-demand by the orchestrator — not a standalone agent.
model: opus
color: cyan
---

# Orchestrator — Special Flows Reference

This file is read on-demand by the orchestrator when executing a special flow. It is NOT part of the orchestrator's system prompt.

---

## Research Flow

When the user asks to investigate, compare technologies, evaluate a migration, or study an approach:

1. **Intake** — classify as `research`
2. **MANDATORY — Query KG** — call `search_nodes` with 1-2 semantic queries. Write `00-knowledge-context.md` if results found. If ChromaDB MCP fails, log "KG: unavailable" and continue.
3. **Invoke `architect` in research mode** — explicitly instruct: "This is a research task, produce `00-research.md`"
4. **Skip Phases 2-5** (no implementation, testing, validation, or delivery)
5. **Present** the research report to the user
6. **Ask** the user how to proceed (implement, discard, or investigate further)

---

## Spike Flow

When the user wants to quickly test a technical hypothesis without full pipeline ceremony:

1. **Intake** — classify as `spike`, complexity always `simple`
2. **MANDATORY — Query KG** — call `search_nodes` with 1-2 semantic queries. Write `00-knowledge-context.md` if results found.
3. **Skip Design** — no architecture proposal needed
4. **Write minimal `00-task-intake.md`** — just: description, what to test, success criteria
5. **Invoke `implementer`** with: "This is a spike — write exploratory code to test: {description}. No tests needed. Focus on proving whether {hypothesis} works. Document what you found in `02-implementation.md`."
6. **Skip Phases 3-5** (no testing, validation, delivery, or GitHub update)
7. **Present results** to the user:
   ```
   Spike complete: {summary}

   Options:
   1. Formalize as feature → I'll create an issue with findings as technical context
   2. Discard → I'll revert the changes (git checkout)
   3. Investigate further → I'll run another spike or a /research
   ```
8. **Act on user's choice:**
   - Formalize: create GitHub issue via `gh issue create` using **SDD template** — include spike findings in Technical Context. Ask: "Issue created. Run full pipeline now?"
   - Discard: `git checkout -- .` to revert (confirm with user first). Clean up session-docs.
   - Investigate: continue as directed.

---

## Plan Flow

Two modes: `plan` (analysis only) and `plan-and-execute` (analysis + full pipeline per task).

### Planning phase (both modes)

1. **Intake** — classify as `plan` or `plan-and-execute`. Do NOT move GitHub issues to "In Progress" yet.
2. **MANDATORY — Query KG** — call `search_nodes` with 2-3 semantic queries. Write `00-knowledge-context.md` if results found.
3. **Specify** — full SPECIFY as normal (codebase investigation, AC, scope). Update GitHub issue if `needs-specify: true`.
4. **Design (planning mode)** — invoke `architect` in planning mode. Architect produces task breakdown in `01-planning.md`.
5. **Validate sizing** — read `01-planning.md`. If any task has >20 AC or looks like a full feature, re-invoke architect to split. Max 1 retry.
6. **Create tasks** — check `gh auth status`:
   - **gh available:** create one GitHub issue per task via `gh issue create` using **SDD issue template**. Labels from repo (`gh label list`), assignee `@me`, project board if exists. Comment on parent issue.
   - **gh unavailable:** write each task as markdown in `session-docs/{feature-name}/tasks/`.
7. **Report** created tasks to user.

**Mode: `plan`** → STOP after reporting.

**Mode: `plan-and-execute`** → proceed to Parallel Dispatch (see below).

---

## Parallel Dispatch Flow (DEFAULT for 2+ tasks)

Parallel dispatch is defined in the orchestrator's **Multi-Task Orchestration** section. It is the **default behavior** whenever the orchestrator has 2+ tasks, regardless of entry point.

**Entry points that lead here:**
- `/plan plan-and-execute` → architect produces task breakdown → dispatch
- `/issue #1 #2 #3` → multiple issues → dispatch
- User requests batch/parallel work → orchestrator runs Specify + Design (planning mode) → dispatch
- Orchestrator identifies broad scope needing breakdown → auto plan-and-execute → dispatch

When multiple tasks exist:
1. The orchestrator reads `01-planning.md` for dependency info (if available) or analyzes dependencies itself
2. Follows the **Multi-Task Orchestration** flow (dependency analysis → rounds → hooks + inotifywait → event-driven monitoring)
3. Each worktree runs a full pipeline via `/issue #{number}`

### Branching strategy

Tasks in later rounds depend on code from earlier rounds. Use **branch-from-parent**:
- Round 1 tasks branch from `main`
- Round 2 tasks branch from Round 1's feature branch (not main)
- When Round 1's PR merges, Round 2's PRs auto-rebase cleanly

This mirrors how human teams work with dependent features.

---

## Hotfix Flow

Same full pipeline as any other development task (Specify → Design → Implement → Verify → Delivery). The only difference: Design can be shorter (focus on the fix, not full architecture). Iteration still applies if tests fail.

---

## Security-Sensitive Flow (extended)

1. Design is mandatory with extended security analysis
2. Phase 3 launches `security` agent in parallel with tester+qa (automatic — triggered by `security-sensitive: true`)
3. Critical/High findings block delivery → iterate with implementer (Case D)
4. Medium/Low/Info findings are warnings in delivery report, do NOT block
5. If any security risk unresolved after max iterations → document in `04-security.md` and proceed

---

## Database Changes Flow

1. Design must include migration strategy
2. Implementation must include migration files
3. Validation must verify migration safety and rollback
4. Delivery must document rollback procedure

---

## Refactor Flow

When `type: refactor`:

1. **Specify** — ACs focus on `VERIFY:` format (same API, same behavior, improved structure)
2. **Design** — architect focuses on target structure, not new features
3. **Implement** — implementer receives: "This is a refactor. Do NOT change behavior. Existing tests are your contract. Only change structure/organization."
4. **Verify** — tester runs **existing tests first** before writing new ones. If existing tests fail → the refactor broke something. New tests only for structural improvements (e.g., new module boundaries).
5. **Delivery** — as normal

The key difference: existing passing tests are the safety net. If they break, the refactor is wrong.

---

## User-Initiated Simple Mode

**Only the user can request simple mode.** The orchestrator NEVER auto-classifies as simple.

When the user explicitly says "simple", "just implement", "skip design", "no tests needed", or equivalent:

1. **Acknowledge** the skip: "Skipping {phase} as requested."
2. **Skip only what was requested:**
   - "skip design" → skip Phase 1 (Design), proceed from Specify → Implement
   - "skip tests" → skip tester in Phase 3, still run qa
   - "just implement" → skip Design + Verify, proceed from Specify → Implement → Delivery
   - "simple" → skip Design, still run Verify (tests + qa)
3. **Never skip Specify (Phase 0b)** — the spec is always needed, even for simple tasks
4. **Never skip Delivery (Phase 4)** — every change needs a branch, commit, and PR
5. **Log the skip** in `00-state.md` under Hot Context: "User requested skip: {what was skipped}"
