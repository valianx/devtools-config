Validate the health of agents and skills in this dev-team system. Run all 3 checks below **in sequence**, then show the consolidated report.

**IMPORTANT:** This skill runs directly — do NOT invoke the `dev-orchestrator` agent or any other agent. Execute all checks yourself using the tools available to you (Bash, Glob, Read, Grep).

---

## Check 1 — agnix (config linting)

1. Run: `agnix --strict .`
2. Capture stdout and stderr
3. Classify output lines:
   - Lines containing `error` → errors
   - Lines containing `warn` → warnings
   - Lines containing `info` → infos
4. Result:
   - **PASS** if 0 errors and 0 warnings
   - **WARN** if 0 errors but warnings exist
   - **FAIL** if any errors exist → suggest running `agnix --fix .`

---

## Check 2 — Sync between project and global

Compare files in **both directions** between these pairs:

| Project path | Global path |
|---|---|
| `agents/` | `~/.claude/agents/` |
| `.claude/commands/` | `~/.claude/commands/` |

For each pair:
1. Use Glob to list all `.md` files in both directories
2. For files present in both: use Read to compare contents. If they differ, report as **different**
3. For files only in project: report as **missing from global**
4. For files only in global: report as **extra in global** (not necessarily an error — could be other projects)

Result:
- **PASS** if all project files exist in global with identical content
- **WARN** if there are extras in global but project files are synced
- **FAIL** if any project file is missing from global or has different content

---

## Check 3 — Agent structure validation

For each `.md` file in `agents/`:

1. **Skip** `dev-orchestrator.md` (it has a different structure as the hub agent)
2. For all other agent files, check that these **mandatory sections** exist (as `## Section Name` headings):
   - `## Core Philosophy`
   - `## Session Context Protocol`
   - `## Session Documentation`
   - `## Execution Log Protocol`
   - `## Return Protocol`
3. Report which sections are missing from which agents

Result:
- **PASS** if all worker agents have all mandatory sections
- **WARN** — not used for this check
- **FAIL** if any agent is missing any mandatory section

---

## Output Format

Present the consolidated report using this exact format:

```
====================================
  /lint — Agent & Skill Health Check
====================================

--- Check 1: agnix config linting ---
Status: {PASS|WARN|FAIL}
{details: error/warning/info counts, or "All clean"}
{if FAIL: "Run `agnix --fix .` to auto-fix errors"}

--- Check 2: Project ↔ Global sync ---
Status: {PASS|WARN|FAIL}
Agents:  {N synced} / {N total} | {details of mismatches}
Skills:  {N synced} / {N total} | {details of mismatches}

--- Check 3: Agent structure ---
Status: {PASS|WARN|FAIL}
{for each agent with issues: "  {agent}: missing {section1}, {section2}"}
{if PASS: "All worker agents have required sections"}

====================================
  Result: {X} / 3 checks passed
====================================
```

Use these status icons in the output:
- PASS → `[PASS]`
- WARN → `[WARN]`
- FAIL → `[FAIL]`

Count only PASS as "passed" in the final summary. WARN and FAIL do not count as passed.
