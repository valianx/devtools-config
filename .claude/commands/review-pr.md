Analyze the input: $ARGUMENTS

---

## Mode 1 — PR number or URL provided

### Phase 1 — Gather (all Bash happens here, in the main context)

1. Extract the PR number from the input (e.g., `#45`, `45`, or full URL)

2. Fetch PR metadata (1 Bash call):
   ```
   gh pr view {number} --json number,title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,url,files
   ```

3. Detect linked issue: search PR body for patterns like `Closes #N`, `Fixes #N`, `Resolves #N`
   - If found: fetch issue data (1 Bash call): `gh issue view {N} --json number,title,body,labels`
   - If not found: linked issue = "none"

4. Fetch branches (1 Bash call):
   ```
   git fetch origin {baseRefName} {headRefName}
   ```

5. Get the diff and file list (1 Bash call — combine both):
   ```
   git diff origin/{baseRefName}...origin/{headRefName}
   ```
   Save the full diff output. If it exceeds ~3000 lines, keep only the first 2000 lines and append a note: `\n[DIFF TRUNCATED — {total} lines total, showing first 2000. Use Read tool for full file context.]`

6. Get changed file list (1 Bash call):
   ```
   git diff --name-only origin/{baseRefName}...origin/{headRefName}
   ```

### Phase 2 — Review (zero Bash, delegated to orchestrator)

7. Pass ALL gathered data to the `dev-orchestrator` agent:
   ```
   Direct Mode Task:
   - Mode: review
   - PR: #{number}
   - Title: {title}
   - Author: {author.login}
   - Base: {baseRefName}
   - Head: {headRefName}
   - Additions: +{additions}
   - Deletions: -{deletions}
   - Changed Files Count: {changedFiles count}
   - URL: {url}
   - Body: {body}
   - Linked Issue: #{issue_number} or "none"
   - Issue Title: {issue_title} or "N/A"
   - Issue Body: {issue_body} or "N/A"
   - Issue Labels: {labels} or "N/A"
   - Changed Files List:
     {file list from step 6}
   - Full Diff:
     {diff output from step 5}
   ```

8. The orchestrator invokes the reviewer with all data inline (zero Bash in sub-agent), builds the draft, and writes it to `.claude/pr-review-draft.md`. The orchestrator returns with the decision (APPROVE or CHANGES_REQUESTED).

### Phase 3 — Publish (Bash in main context)

9. **Verify the draft exists.** Check that `.claude/pr-review-draft.md` was created and is not empty. If it's missing or empty:
   - Tell the user: "El orchestrator no generó el borrador de revisión. Reintentando..."
   - Re-invoke the orchestrator with the same data (go back to step 7)
   - If it fails a second time, report the error and stop

10. Read `.claude/pr-review-draft.md` and display the full review draft to the user.

11. Ask the user: "Borrador de revisión listo. Aprueba para publicar, o dime qué cambiar."

12. Based on user response:
    - **User approves**: publish using the decision from the orchestrator (user can override):
      ```
      gh pr review {number} --approve -F .claude/pr-review-draft.md
      ```
      or:
      ```
      gh pr review {number} --request-changes -F .claude/pr-review-draft.md
      ```
    - **User requests edits**: modify the draft per feedback, show again, repeat until approved.

13. **Verify the review was posted.** After `gh pr review`, check the exit code. If it failed, report the error to the user with the exact error message.

14. Cleanup: delete `.claude/pr-review-draft.md` after successful publishing.

---

## Mode 2 — No input provided

Ask the user: "Proporciona un número de PR o URL para revisar. Ejemplo: `#45`, `45`, o `https://github.com/owner/repo/pull/45`."

---

## Important

- Always invoke the `dev-orchestrator` agent — do NOT invoke agents directly
- The orchestrator coordinates: reviewer (analysis with pre-fetched data) → draft → return to skill
- ALL Bash commands run in this skill (main context) — the orchestrator and reviewer do ZERO Bash
- The user approves the review before publishing (Phase 3)
