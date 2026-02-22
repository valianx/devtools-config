Analyze the input: $ARGUMENTS

---

## Mode 1 — Single issue number or URL (`#123`, `123`, URL)

1. Extract the issue number
2. Read the issue:
   ```
   gh issue view {number} --json number,title,body,labels,assignees,milestone,projectItems
   ```
3. If the command fails, tell the user: "Issue #{number} not found or `gh` is not configured. Check `gh auth status`."
4. **Assess issue quality** before passing to orchestrator:
   - `needs-specify: true` — if the issue body is empty, has fewer than 3 lines, has no acceptance criteria, or is vague
   - `needs-specify: false` — if the issue already has structured AC (Given/When/Then or checkboxes) and clear scope
5. Pass ALL the issue data to the `dev-orchestrator` agent:
   ```
   GitHub Issue Task:
   - Issue: #{number}
   - URL: {repo_url}/issues/{number}
   - Title: {title}
   - Labels: {labels}
   - Milestone: {milestone or "None"}
   - Description: {body}
   - Needs Specify: {true/false}
   - Quality Notes: {brief reason — e.g., "no AC defined", "body is empty", "has structured AC"}
   ```

---

## Mode 2 — Multiple issues (`#12 #13 #14`, `12, 13, 14`)

1. Extract all issue numbers from the input
2. Read each issue:
   ```
   gh issue view {number} --json number,title,body,labels,assignees,milestone,projectItems
   ```
3. If any issue fails to load, report which ones failed and continue with the rest
4. **Assess each issue's quality** before passing to orchestrator:
   - `needs-specify: true` — if the issue body is empty, has fewer than 3 lines, has no acceptance criteria, or is vague
   - `needs-specify: false` — if the issue already has structured AC (Given/When/Then or checkboxes) and clear scope
5. Pass ALL issues as a batch to the `dev-orchestrator` agent:
   ```
   GitHub Issue Batch (N tasks):

   --- Task 1 ---
   - Issue: #{number}
   - URL: {repo_url}/issues/{number}
   - Title: {title}
   - Labels: {labels}
   - Description: {body}
   - Needs Specify: {true/false}
   - Quality Notes: {brief reason}

   --- Task 2 ---
   - Issue: #{number}
   ...
   ```
   The orchestrator will create `session-docs/batch-progress.md` to track all tasks.

---

## Mode 3 — Text description (not a number or URL)

1. Analyze the description to determine:
   - **Title**: short, imperative summary (max 70 chars)
   - **Label**: classify as one of: `bug`, `enhancement`, `feature`, `refactor`, `docs`, `security`
   - **Body**: structured with the template below

2. Create the issue with auto-label and auto-assign:
   ```
   gh issue create --title "{title}" --label "{label}" --assignee "@me" --body "$(cat <<'EOF'
   ## Description
   {what needs to be done — rewritten clearly from the user's input}

   ## Acceptance Criteria
   - [ ] {criterion 1 — derived from the description}
   - [ ] {criterion 2}
   - [ ] {criterion 3}

   ## Technical Context
   {any technical details, file paths, or constraints mentioned in the input}
   (or "To be defined by architect")
   EOF
   )"
   ```

3. Read the created issue to get the full data:
   ```
   gh issue view {number} --json number,title,body,labels,assignees,milestone,projectItems
   ```
4. Confirm the created issue number with the user
5. Pass the issue data to the `dev-orchestrator` agent using the format from Mode 1

---

## Mode 4 — No input provided

Ask the user: "Provide a GitHub issue number (#123), multiple issues (#12 #13 #14), or a task description to create a new issue."

---

## Error Handling

- If `gh` is not available or not authenticated, tell the user: "GitHub CLI is not configured. Run `gh auth login` to set it up."
- If an issue number doesn't exist, report which one failed and ask if you should continue with the others (batch) or stop (single)
- If issue creation fails (no permission, no remote), report the error clearly — do not swallow it

## Important

- **You read/create issues.** The orchestrator does NOT read issues — it receives the data from you.
- Always invoke the `dev-orchestrator` agent to handle the task — do NOT execute the development pipeline yourself
- The orchestrator manages the full team: architect → implementer → tester → qa → delivery
- The orchestrator will handle project board updates (move to "In Progress", comment, move to "In Review") using the issue number you provide
