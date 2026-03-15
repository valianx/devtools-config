# Secrets y Variables de Entorno

Lista unificada de todas las API keys, tokens y secrets necesarios para restaurar el entorno completo.

**Nunca se guardan en texto plano en este repo.** Los valores `<REDACTED>` en los archivos de config deben reemplazarse manualmente.

---

## OpenClaw (`~/.openclaw/openclaw.json`)

| Variable | Descripcion | Donde va en openclaw.json |
|---|---|---|
| `ANTHROPIC_API_KEY` | API key de Anthropic (Claude) | `auth.profiles.anthropic:openclaw.apiKey` |
| `GROQ_API_KEY` | API key de Groq (Whisper audio) | `auth.profiles.groq:default.apiKey` |
| `ELEVENLABS_API_KEY` | API key de ElevenLabs (TTS, voz Matilda) | `messages.tts.elevenlabs.apiKey` |
| `TELEGRAM_BOT_TOKEN` | Token del bot de Telegram | `channels.telegram.botToken` |
| `TELEGRAM_ALLOWED_USER_ID` | ID de Telegram autorizado (Mario) | `channels.telegram.allowFrom` y `tools.elevated.allowFrom.telegram` |
| `OPENCLAW_GATEWAY_TOKEN` | Token de auth del gateway local | `gateway.auth.token` |

## Claude Code (variables de entorno del sistema)

| Variable | Descripcion | Donde se usa |
|---|---|---|
| `ANTHROPIC_API_KEY` | API key de Anthropic | Claude Code CLI |
| `OPENCLAW_GATEWAY_TOKEN` | Token de auth del gateway local | Hook scripts (`notify-openclaw.sh`, `notify-openclaw-progress.sh`) |

> Los hook scripts leen `OPENCLAW_GATEWAY_TOKEN` del entorno. Claude Code usa `ANTHROPIC_API_KEY` del entorno.

---

## Proceso de restauracion

1. Obtener las keys de tu password manager
2. Editar `~/.openclaw/openclaw.json` — reemplazar los 6 valores `<REDACTED>`
3. Configurar variables de entorno:
   ```bash
   # Windows: agregar como variables de entorno del sistema
   # Linux/WSL: agregar a ~/.bashrc
   export ANTHROPIC_API_KEY="sk-ant-..."
   export OPENCLAW_GATEWAY_TOKEN="..."
   ```
