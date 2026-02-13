Analyze the input: $ARGUMENTS

Follow these rules based on the input type:

## If the input is a GitHub issue number (#123, 123) or URL:

1. Read the issue:
   ```
   gh issue view {number} --json number,title,body,labels,assignees,milestone,projectItems
   ```
2. Use the issue data as the task for the `dt-orchestrator` agent
3. The orchestrator will handle the full development lifecycle and update the issue when done

## If the input is a text description (not a number or URL):

1. Create a new GitHub issue:
   ```
   gh issue create --title "{short title from description}" --body "{full description}"
   ```
2. Confirm the created issue number with the user
3. Use the new issue as the task for the `dt-orchestrator` agent
4. The orchestrator will handle the full development lifecycle and update the issue when done

## If no input is provided:

Ask the user: "Provide a GitHub issue number (#123) or a task description to create a new issue."

## Important:

- Always invoke the `dt-orchestrator` agent to handle the task — do NOT execute the development pipeline yourself
- The orchestrator manages the full team: dt-architect → dt-implementer → dt-tester → dt-qa → dt-delivery
- Pass the GitHub issue number to the orchestrator so it can update the issue at the end
