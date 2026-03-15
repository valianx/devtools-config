Resume an interrupted pipeline from where it left off. Routes through the orchestrator with full recovery context.

Analyze the input: $ARGUMENTS

---

## Mode 1 — Feature name provided

1. Check that `session-docs/{feature}/00-state.md` exists
2. If not found, tell the user: "No pipeline state found for '{feature}'. Use `/status` to see active pipelines."
3. Read `session-docs/{feature}/00-state.md` in full
4. Read `session-docs/{feature}/00-execution-log.md` if it exists (for timing context)
5. Validate the state:
   - If `status: complete` → tell user: "Pipeline '{feature}' already completed. Nothing to resume."
   - If phase and next_action are present → proceed
   - If state file is corrupted or missing key fields → tell user: "State file is incomplete. Showing what's there:" and display the raw content
6. Pass recovery context to the `orchestrator` agent:
   ```
   Resume Pipeline:
   - Feature: {feature-name}
   - Current Phase: {phase from state}
   - Status: {status}
   - Iteration: {N}/3
   - Last Completed: {last_completed}
   - Next Action: {next_action from state}
   - Hot Context: {hot context items from state}
   - Recovery Instructions: {recovery instructions from state}
   - Agent Results So Far:
     {agent results table from state}
   ```

---

## Mode 2 — No input provided

1. Scan `session-docs/*/00-state.md` for incomplete pipelines (status != complete)
2. If none found → tell user: "No interrupted pipelines found."
3. If exactly one found → auto-select it and proceed as Mode 1
4. If multiple found → show list and ask user:
   ```
   Interrupted pipelines found:
   1. {feature-a} — Phase 2 (implement), last updated 2026-03-08 14:30
   2. {feature-b} — Phase 3 (verify, iter 2/3), last updated 2026-03-07 18:00

   Which one do you want to resume? (number or name)
   ```

---

## Error Handling

- If session-docs folder doesn't exist → "No session-docs found in this project."
- If state file exists but is empty → "State file is empty. The pipeline may not have started properly."
- If the orchestrator fails to resume → it will report the issue. The skill does not retry.

---

## Important

- **You read state. The orchestrator does NOT** — it receives the recovery context from you.
- Always invoke the `orchestrator` agent — do NOT execute any pipeline yourself
- The orchestrator uses the Recovery Instructions to know exactly what to do next
- This skill is the explicit version of what the orchestrator does implicitly after context compaction
