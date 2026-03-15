# HEARTBEAT.md

## Claude Code Event Forwarding

When you receive events on `/claude-events`, process them based on `X-Event-Type` and send a **concise summary** to Telegram. Never forward raw JSON.

### Event Types and How to Summarize

| X-Event-Type | What happened | Telegram message format |
|---|---|---|
| `work-completed` | Claude Code finished a task | `✅ Claude terminó: {last_assistant_message summary, max 2 lines}` |
| `user-input-required` | Claude needs user input (permission or question) | `⏳ Claude necesita tu input: {notification type}` |
| `error-occurred` | A tool failed | `❌ Error en {tool_name}: {first line of error}` |
| `file-modified` | A file was written or edited | `📝 Modificó: {file_path basename}` |
| `command-executed` | A shell command ran | `⚙️ Ejecutó: {command, truncated to 80 chars}` — only notify if exit_code != 0 OR command contains `test\|deploy\|push\|install\|build` |
| `pre-command` | A shell command is about to run | **Do NOT notify** — only log. Exception: notify if command contains `rm -rf\|drop\|push --force\|reset --hard` → `⚠️ Comando peligroso: {command}` |

### Rules

1. **Batch file modifications**: if multiple `file-modified` events arrive within 3 seconds, batch them into one message: `📝 Modificó {N} archivos: {basename1}, {basename2}...`
2. **Suppress noise**: do NOT send Telegram messages for `Read`, `Glob`, `Grep` tools — those are just lookups
3. **Successful commands are silent by default**: only notify for failed commands OR commands matching the keywords above (test, deploy, push, install, build)
4. **Pre-command is log-only** unless it matches a destructive pattern
5. **Keep messages short**: max 280 characters per Telegram message. Truncate paths and commands as needed
6. **Session context**: include session_id (first 6 chars) if you're tracking multiple Claude Code sessions
