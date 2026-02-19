Analyze the input: $ARGUMENTS

Follow these rules based on the input type:

## If the input is a GitHub issue number (#123, 123) or URL:

1. Extract the issue number (from `#123`, `123`, or URL)
2. Read the issue and its project board info:
   ```
   gh issue view {number} --json number,title,body,labels,assignees,milestone,projectItems
   ```
3. Pass ALL the issue data to the `dt-orchestrator` agent in this format:
   ```
   GitHub Issue Task:
   - Issue: #{number}
   - URL: {repo_url}/issues/{number}
   - Title: {title}
   - Labels: {labels}
   - Milestone: {milestone or "None"}
   - Description: {body}
   ```

## If the input is a text description (not a number or URL):

1. Create a new GitHub issue:
   ```
   gh issue create --title "{short title from description}" --body "{full description}"
   ```
2. Read the created issue to get the full data:
   ```
   gh issue view {number} --json number,title,body,labels,assignees,milestone,projectItems
   ```
3. Confirm the created issue number with the user
4. Pass the issue data to the `dt-orchestrator` agent using the same format above

## If no input is provided:

Ask the user: "Provide a GitHub issue number (#123) or a task description to create a new issue."

## Important:

- **You read/create the issue.** The orchestrator does NOT read issues — it receives the data from you.
- Always invoke the `dt-orchestrator` agent to handle the task — do NOT execute the development pipeline yourself
- The orchestrator manages the full team: dt-architect → dt-implementer → dt-tester → dt-qa → dt-delivery
- The orchestrator will handle project board updates (move to "In Progress", comment, move to "In Review") using the issue number you provide
