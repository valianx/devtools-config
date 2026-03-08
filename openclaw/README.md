# OpenClaw Config Backup

Respaldo de la configuración de OpenClaw para el entorno de Mario-PC (WSL2 en Windows).
Permite restaurar el agente Val desde cero en un equipo nuevo o tras un reset.

---

## Estructura del directorio de configuración

OpenClaw guarda su configuración en `~/.openclaw/` (que en WSL apunta a `C:\Users\mario\.openclaw\`).

Los archivos clave que se deben respaldar/restaurar son:

```
~/.openclaw/
├── openclaw.json          # Configuración principal
├── exec-approvals.json    # Allowlist de comandos exec
├── node.json              # Identidad del nodo local
├── cron/jobs.json         # Jobs cron programados
└── workspace/             # Workspace del agente (ver abajo)
    ├── AGENTS.md
    ├── SOUL.md
    ├── IDENTITY.md
    ├── USER.md
    ├── TOOLS.md
    ├── HEARTBEAT.md
    ├── MEMORY.md
    ├── memory/            # Notas diarias del agente
    └── skills/            # Skills personalizadas
```

---

## Archivos de configuración

### `openclaw.json` — Configuración principal

Archivo central de OpenClaw. Controla todos los subsistemas.

#### Secciones importantes:

**`agents.defaults`**
- `model.primary`: modelo de IA principal → `anthropic/claude-sonnet-4-6`
- `workspace`: ruta al workspace del agente
- `compaction.mode`: estrategia de compactación de contexto (`safeguard`)
- `maxConcurrent`: máximo de agentes concurrentes (4)

**`auth.profiles`**
Perfiles de autenticación por proveedor. Actualmente configurados:
- `anthropic:openclaw` — proveedor principal (Claude)
- `groq:default` — proveedor secundario (audio/Whisper)

> Las API keys se manejan por separado (ver sección **Variables de entorno**).

**`tools.exec`**
- `security: "full"` — sin restricciones de ejecución
- `ask: "off"` — no pide aprobación para comandos
- `safeBins`: lista de binarios permitidos sin aprobación

**`tools.elevated.allowFrom.telegram`**
Lista de IDs de Telegram autorizados para comandos elevados.
- Variable: `TELEGRAM_ALLOWED_USER_ID`

**`messages.tts`**
Configuración de Text-to-Speech:
- Provider: ElevenLabs
- `voiceId`: `XrExE9yKIg1WjnnlVkGX` (voz Matilda)
- `modelId`: `eleven_multilingual_v2`
- API key → Variable: `ELEVENLABS_API_KEY`

**`channels.telegram`**
- `botToken` → Variable: `TELEGRAM_BOT_TOKEN`
- `allowFrom`: lista de IDs de Telegram permitidos
- `dmPolicy: "allowlist"` — solo acepta mensajes de IDs autorizados

**`gateway`**
- Puerto: `18789`
- Modo: `local` (solo loopback, sin exposición externa)
- `auth.token` → Variable: `OPENCLAW_GATEWAY_TOKEN`

---

### `exec-approvals.json` — Allowlist de exec

Controla qué binarios puede ejecutar el agente sin aprobación adicional.

Tiene `security: "full"` como default global, lo que significa que el agente puede ejecutar cualquier comando sin pedir confirmación.

El `socket.token` es generado automáticamente; no es necesario preservarlo entre máquinas.

---

### `node.json` — Identidad del nodo

```json
{
  "nodeId": "...",
  "displayName": "Mario-PC",
  "gateway": { "host": "127.0.0.1", "port": 18789 }
}
```

El `nodeId` puede regenerarse en una nueva instalación.

---

### `cron/jobs.json` — Jobs cron

Actualmente sin jobs activos. Si se agregan, se respaldan aquí.

---

## Workspace del agente (`~/.openclaw/workspace/`)

Este directorio **es la memoria y personalidad del agente**. Es un repositorio git propio.

| Archivo | Descripción |
|---|---|
| `SOUL.md` | Personalidad y valores del agente |
| `IDENTITY.md` | Nombre, idioma, vibe |
| `USER.md` | Info sobre Mario (el usuario) |
| `AGENTS.md` | Instrucciones de comportamiento por sesión |
| `TOOLS.md` | Notas locales de herramientas y entorno |
| `HEARTBEAT.md` | Tareas periódicas para heartbeats |
| `MEMORY.md` | Memoria long-term del agente |
| `memory/` | Notas diarias (`YYYY-MM-DD.md`) |
| `skills/` | Skills personalizadas instaladas localmente |

---

## Skills personalizadas

Están en `~/.openclaw/workspace/skills/` y respaldadas en este repo bajo `skills/`:

- **`tmux-wsl`** — Orquestación de sesiones tmux en WSL2 (variante del skill tmux estándar)
- **`openai-whisper-api`** — Transcripción de audio vía OpenAI Whisper API

Para restaurarlas:
```bash
cp -r skills/ ~/.openclaw/workspace/skills/
```

---

## Variables de entorno / Secrets

Las API keys y tokens **nunca se guardan en texto plano en este repo**. Se documentan aquí como referencia:

| Variable | Descripción | Dónde se usa |
|---|---|---|
| `ANTHROPIC_API_KEY` | API key de Anthropic (Claude) | `openclaw.json` → `auth.profiles.anthropic:openclaw` |
| `GROQ_API_KEY` | API key de Groq (Whisper) | `openclaw.json` → `auth.profiles.groq:default` |
| `ELEVENLABS_API_KEY` | API key de ElevenLabs (TTS) | `openclaw.json` → `messages.tts.elevenlabs.apiKey` |
| `TELEGRAM_BOT_TOKEN` | Token del bot de Telegram | `openclaw.json` → `channels.telegram.botToken` |
| `TELEGRAM_ALLOWED_USER_ID` | ID de Telegram autorizado (Mario) | `openclaw.json` → `channels.telegram.allowFrom` y `tools.elevated.allowFrom.telegram` |
| `OPENCLAW_GATEWAY_TOKEN` | Token de autenticación del gateway local | `openclaw.json` → `gateway.auth.token` |

---

## Cómo restaurar

### 1. Instalar OpenClaw

```bash
npm install -g openclaw
```

### 2. Copiar archivos de configuración

```bash
# Configuración principal
cp openclaw.json ~/.openclaw/openclaw.json

# Exec approvals
cp exec-approvals.json ~/.openclaw/exec-approvals.json

# Cron jobs (si los hay)
cp cron/jobs.json ~/.openclaw/cron/jobs.json
```

### 3. Restaurar las API keys

Editar `~/.openclaw/openclaw.json` y reemplazar los valores `<REDACTED>` con las keys reales:

- `auth.profiles.anthropic:openclaw.apiKey` → `ANTHROPIC_API_KEY`
- `auth.profiles.groq:default.apiKey` → `GROQ_API_KEY`
- `messages.tts.elevenlabs.apiKey` → `ELEVENLABS_API_KEY`
- `channels.telegram.botToken` → `TELEGRAM_BOT_TOKEN`
- `gateway.auth.token` → `OPENCLAW_GATEWAY_TOKEN`

### 4. Restaurar el workspace del agente

```bash
cd ~/.openclaw/workspace
git clone <repo-del-workspace> .
# o copiar los archivos manualmente
```

### 5. Iniciar OpenClaw

```bash
openclaw gateway start
```

---

## Notas de entorno

- **OS**: WSL2 en Windows 11 (Mario-PC)
- **Path de config en Windows**: `C:\Users\mario\.openclaw\`
- **Path en WSL**: `~/.openclaw/` (symlink al mismo lugar)
- **Node.js**: v22.22.0 (via fnm)
- **Modelo principal**: `anthropic/claude-sonnet-4-6`
- **Agente**: Val 🐾
