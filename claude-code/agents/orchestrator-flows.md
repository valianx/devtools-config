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

## Parallel Dispatch Flow (plan-and-execute with multiple tasks)

When `plan-and-execute` produces multiple tasks, dispatch them efficiently using dependency analysis and worktrees.

### Step 1 — Build dependency graph

Read `01-planning.md` and extract:
- Task list with IDs
- Dependencies between tasks (Task B depends on Task A)

### Step 2 — Topological sort into rounds

Group tasks into rounds where all tasks in a round are independent of each other:
- **Round 1:** tasks with no dependencies (foundational)
- **Round 2:** tasks whose dependencies are all in Round 1
- **Round N:** tasks whose dependencies are all in Rounds < N

### Step 3 — Execute rounds sequentially

For each round:

**If 1 task in round:** run it in the current session (normal pipeline).

**If 2+ tasks in round:**

1. **Determine base branch:**
   - Round 1 → branch from `main`
   - Round N → branch from the completed branch of the dependency in Round N-1

2. **Launch parallel instances:**
   ```bash
   claude --worktree {task-name} --tmux --dangerously-skip-permissions -p "/issue #{number}"
   ```
   One command per task in the round.

3. **Monitor progress:**
   - Check `session-docs/{feature}/00-state.md` in each worktree
   - Wait for all instances in the round to complete before starting next round

4. **Collect results:**
   - Read status from each worktree's session-docs
   - Log results in `batch-progress.md`

### Step 4 — Report consolidated results

After all rounds complete:
```
Parallel execution complete:
- Rounds: {N}
- Tasks: {total} ({parallel} in parallel, {sequential} sequential)
- PRs created: {list with URLs}
- Branches: {list}
- Failures: {list or "none"}
```

### Step 5 — Cleanup

```bash
git worktree remove {worktree-path}  # per worktree
```

### Branching strategy

Tasks in later rounds depend on code from earlier rounds. Use **branch-from-parent**:
- Round 1 tasks branch from `main`
- Round 2 tasks branch from Round 1's feature branch (not main)
- When Round 1's PR merges, Round 2's PRs auto-rebase cleanly

This mirrors how human teams work with dependent features.

### Batch Progress Tracking

Track state in `session-docs/batch-progress.md`:

```markdown
# Batch Progress
| # | Task | Round | Status | Branch | PR |
|---|------|-------|--------|--------|----|
| 1 | {title} | 1 | DONE | feature/101-x | #101 |
| 2 | {title} | 2 | RUNNING | feature/102-y | — |
| 3 | {title} | 2 | RUNNING | feature/103-z | — |
```

**Status values:** `PENDING → RUNNING → DONE → FAILED`

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
