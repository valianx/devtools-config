Analyze the input: $ARGUMENTS

---

## Mode 1 — PR number or URL provided

1. Extract the PR number from the input (e.g., `#45`, `45`, or full URL)
2. Pass to the `dev-orchestrator` agent:
   ```
   Direct Mode Task:
   - Mode: review
   - PR: #{number}
   ```

## Mode 2 — No input provided

Ask the user: "Provide a PR number or URL to review. Example: `#45`, `45`, or `https://github.com/owner/repo/pull/45`."

---

## Important

- Always invoke the `dev-orchestrator` agent — do NOT invoke agents directly
- The orchestrator will route to the `reviewer` agent
- The reviewer analyzes code quality, security, and performance, then approves or requests changes autonomously
