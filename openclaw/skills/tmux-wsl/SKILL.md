---
name: tmux-wsl
description: Orchestrate tmux sessions in WSL. Use instead of the default tmux skill when running on Mario-PC (WSL2). All tmux commands MUST be prefixed with `wsl tmux`. Handles Claude Code sessions, parallel workers, and session lifecycle.
---

# tmux en WSL - Mario-PC

Todas las operaciones de tmux en este entorno corren dentro de WSL2.  
**REGLA PRINCIPAL: siempre usar `wsl tmux` en lugar de `tmux` directamente.**

## Prerequisitos

- tmux corre dentro de WSL. Todos los comandos deben ser `wsl tmux ...`
- Incorrecto: `tmux list-sessions`
- Correcto: `wsl tmux list-sessions`

---

## Acciones estándar

### `list` — Listar sesiones activas

```bash
wsl tmux list-sessions 2>/dev/null || echo "No active tmux sessions"
```

### `start <session_name>` — Crear sesión con Claude Code

1. Verificar si existe:
   ```bash
   wsl tmux has-session -t {session_name} 2>/dev/null && echo "EXISTS" || echo "NEW"
   ```
2. Si EXISTS → reportar y leer output actual
3. Si NEW → crear y lanzar:
   ```bash
   wsl tmux new-session -d -s {session_name} && wsl tmux send-keys -t {session_name}:0 "claude --dangerously-skip-permissions" C-m
   ```
4. Esperar 3 segundos e leer output para confirmar inicio

### `send <session_name> <command>` — Enviar comando de texto

1. Verificar que la sesión existe (si no, auto-iniciarla)
2. Enviar:
   ```bash
   wsl tmux send-keys -t {session_name}:0 "{command}" C-m
   ```

### `read <session_name> [lines=50]` — Leer output

```bash
wsl tmux capture-pane -t {session_name}:0 -p -S -{lines}
```

Limpiar líneas vacías al inicio/fin antes de mostrar.

### `keys <session_name> <keys>` — Enviar teclas especiales

```bash
wsl tmux send-keys -t {session_name}:0 {keys}
```

Teclas comunes: `C-c` (Ctrl+C), `C-m` (Enter), `C-d` (EOF), `Escape`

### `stop <session_name>` — Matar sesión

```bash
wsl tmux kill-session -t {session_name}
```

### `stop-all` — Matar todas las sesiones

```bash
wsl tmux kill-server 2>/dev/null
```

---

## Sesiones conocidas (Zippy)

| Sesión         | Proyecto                                      |
|----------------|-----------------------------------------------|
| `transactions` | NestJS + OTEL + PostgreSQL particionado       |
| `notifications`| Servicio notificaciones con GCP PubSub        |

---

## Notas importantes

- Nombres de sesión sin espacios (usar guiones bajos)
- Para proyectos Zippy internos → `claude --dangerously-skip-permissions`
- Para código externo / PRs de terceros → `claude` (sin flag)
- Siempre hacer `read` antes de enviar nuevos comandos (verificar estado)
- Este skill es independiente del `orchestrator`
