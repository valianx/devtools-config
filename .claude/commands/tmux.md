Orchestrate multiple Claude Code instances in parallel using tmux sessions via WSL. Use when you need to run independent tasks simultaneously (e.g., backend + frontend, multiple workers). This is a standalone utility — does NOT route through the orchestrator.

Analyze the input: $ARGUMENTS

---

## Prerequisites

- tmux runs inside WSL. All tmux commands MUST be prefixed with `wsl tmux`
- Example: `wsl tmux list-sessions` instead of `tmux list-sessions`

---

## Parse Arguments

Format: `<action> [session_name] [payload]`

If no arguments provided, show usage help (see bottom of this file).

---

## Actions

### `list` — List active sessions

```bash
wsl tmux list-sessions 2>/dev/null || echo "No active tmux sessions"
```

Display results as a formatted table.

### `start <session_name>` — Create session with Claude Code

1. Check if session exists:
   ```bash
   wsl tmux has-session -t {session_name} 2>/dev/null && echo "EXISTS" || echo "NEW"
   ```
2. If EXISTS → report "Session '{session_name}' already active" and read its current output
3. If NEW → create and launch:
   ```bash
   wsl tmux new-session -d -s {session_name} && wsl tmux send-keys -t {session_name}:0 "claude" C-m
   ```
4. Wait 3 seconds for Claude to initialize
5. Read output to confirm Claude started

### `send <session_name> <command>` — Send text command

1. Verify session exists (if not, auto-start it)
2. Send the command:
   ```bash
   wsl tmux send-keys -t {session_name}:0 "{command}" C-m
   ```
3. Confirm what was sent

### `read <session_name> [lines]` — Read session output

1. Default lines = 50 if not specified
2. Capture output:
   ```bash
   wsl tmux capture-pane -t {session_name}:0 -p -S -{lines}
   ```
3. Display the captured output. Strip empty leading/trailing lines for clarity.

### `keys <session_name> <keys>` — Send special keys

1. Verify session exists
2. Send keys:
   ```bash
   wsl tmux send-keys -t {session_name}:0 {keys}
   ```
3. Common keys reference: `C-c` (Ctrl+C), `C-m` (Enter), `C-d` (EOF), `Escape`

### `stop <session_name>` — Kill session

1. Kill the session:
   ```bash
   wsl tmux kill-session -t {session_name}
   ```
2. Confirm: "Session '{session_name}' terminated"

### `stop-all` — Kill all sessions

1. Kill the tmux server:
   ```bash
   wsl tmux kill-server 2>/dev/null
   ```
2. Confirm: "All tmux sessions terminated"

---

## Usage Help

If no arguments or invalid action, show:

```
Usage: /tmux <action> [session_name] [payload]

Actions:
  list                          List all active tmux sessions
  start <name>                  Create session and launch Claude Code
  send <name> <command>         Send a text command to a session
  read <name> [lines=50]        Read terminal output from a session
  keys <name> <keys>            Send special keys (C-c, Escape, etc.)
  stop <name>                   Kill a session
  stop-all                      Kill all tmux sessions

Examples:
  /tmux start backend_worker
  /tmux send backend_worker "implement the REST API for /users"
  /tmux read backend_worker 100
  /tmux keys backend_worker C-c
  /tmux list
  /tmux stop backend_worker
```

---

## Important

- Session names must NOT contain spaces (use underscores)
- Always use `read` to check worker progress before sending new commands
- Use `keys C-c` to interrupt a stuck session
- Each session runs its own independent Claude Code instance with its own context
- This skill does NOT route through the orchestrator
