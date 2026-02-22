Analyze the input: $ARGUMENTS

---

## Mode 1 — PR number or URL provided

1. Extract the PR number from the input (e.g., `#45`, `45`, or full URL)
2. Fetch PR metadata:
   ```
   gh pr view {number} --json number,title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,url,files
   ```
3. Detect linked issue: search PR body for patterns like `Closes #N`, `Fixes #N`, `Resolves #N`
   - If found: fetch issue data: `gh issue view {N} --json number,title,body,labels`
   - If not found: linked issue = "none"
4. Pass enriched data to the `dev-orchestrator` agent:
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
   - Changed Files: {changedFiles count}
   - URL: {url}
   - Body: {body}
   - Linked Issue: #{issue_number} or "none"
   - Issue Title: {issue_title} or "N/A"
   - Issue Body: {issue_body} or "N/A"
   - Issue Labels: {labels} or "N/A"
   ```

## Mode 2 — No input provided

Ask the user: "Provide a PR number or URL to review. Example: `#45`, `45`, or `https://github.com/owner/repo/pull/45`."

---

## Important

- Always invoke the `dev-orchestrator` agent — do NOT invoke agents directly
- The orchestrator coordinates: architect (AC generation) → reviewer + QA (parallel analysis) → consolidate → user approval → publish
- The user can edit the review before publishing
