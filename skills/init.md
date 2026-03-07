Pass to the `dev-orchestrator` agent:
```
Direct Mode Task:
- Mode: init
```

---

## Important

- Always invoke the `dev-orchestrator` agent — do NOT invoke agents directly
- The orchestrator will route to the `init` agent
- The init agent detects the project type, tech stack, and generates/updates CLAUDE.md
- Also creates CHANGELOG.md if missing and ensures session-docs is in .gitignore
