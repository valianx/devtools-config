# MEMORY.md - Long-term Memory

## Skills activos — leer antes de cualquier tarea

| Situación | Skill a cargar |
|---|---|
| Mario pide cualquier tarea de código/dev | `~/.openclaw/workspace/skills/prompt-crafter/SKILL.md` |
| Necesito usar tmux en WSL | `~/.openclaw/workspace/skills/tmux-wsl/SKILL.md` |
| Necesito transcribir audio | `~/.openclaw/workspace/skills/openai-whisper-api/SKILL.md` |

---

## Reglas permanentes

### 1. prompt-crafter es obligatorio
- Usar **siempre** que Mario pida trabajo de desarrollo/código
- Flujo: entender → clarificar → elegir skill Claude Code → craftar prompt → aprobación de Mario → enviar via tmux
- **Nunca enviar prompt a Claude Code sin aprobación explícita**

### 2. Siempre usar el orchestrator
- Todo trabajo de desarrollo pasa por el orchestrator de Claude Code
- Nunca enviar instrucciones directas sin pasar por un skill (/issue, /plan, /design, etc.)
- prompt-crafter elige el skill apropiado automáticamente

### 3. tmux siempre con prefijo `wsl tmux`
- Aplica a todos los flujos: listar, crear, enviar, leer, matar sesiones
- Proyectos Zippy → `claude --dangerously-skip-permissions`
- Código externo / PRs de terceros → `claude` normal (con permisos)

### 4. Claude Code notifica via hooks
- Cuando Claude Code **termina**, envía POST a `localhost:18789/claude-events` con header `X-Event-Type: work-completed` y el campo `last_assistant_message` con el resumen
- Cuando Claude Code **necesita input** (pregunta o permiso), envía POST con `X-Event-Type: user-input-required` y el campo `message` con lo que necesita
- Cuando Claude Code **falla**, envía POST con `X-Event-Type: error-occurred` y los campos `tool_name` y `error`
- Al recibir estos eventos, **solo enviar a Mario lo relevante**: el resumen, la pregunta, o el error. No enviar datos crudos, IDs de sesión, paths internos, ni metadatos del sistema

### 5. No ser proactivo
- Solo responder cuando Mario pregunta directamente
- No enviar salidas de tmux sin que las pida
- Las notificaciones de hooks son la excepción: reenviar a Mario de forma resumida

---

## Preferencias de Mario

- Idioma: español, tono casual
- Dar contexto de los comandos antes de ejecutarlos
- Sin cron ni automatizaciones que generen mensajes
- Prefiere prompts detallados sobre genéricos

---

## Proyectos conocidos

| Proyecto | Path | Stack |
|---|---|---|
| Zippy: transactions | `/mnt/c/Users/mario/zippy/transactions` | NestJS + OTEL + PostgreSQL particionado |
| Zippy: notifications | `/mnt/c/Users/mario/zippy/notifications` | NestJS + GCP PubSub |
| Zippy: template | `/mnt/c/Users/mario/zippy/nest-template` | NestJS base template |
| devtools-local-config | `/mnt/c/Users/mario/projects/devtools-local-config` | Config de dev environment + sistema de agentes AI |

---

## Infraestructura compartida

- **ChromaDB (knowledge graph):** DB en `/mnt/c/Users/mario/.claude/chromadb/`, compartida entre Windows y WSL. Búsqueda semántica cross-proyecto
- **Agentes y skills:** source en `devtools-local-config/AI development/`, desplegados en `~/.claude/agents/` y `~/.claude/commands/`
- **Config backup:** `devtools-local-config/openclaw/` — respaldo de config de OpenClaw, skills, hooks, y este archivo
