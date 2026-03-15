# Plan de Migracion: PC-dependent → VPS-independent

> Objetivo: poder viajar sin depender de la PC de casa. Todo corre en un VPS 24/7.
> Estado: PLAN — no se ha ejecutado nada aun.
> Fecha: 2026-03-15

---

## Arquitectura objetivo

```
VPS Ubuntu (siempre on, $5-12/mes)
├── OpenClaw/Val (systemd)          ← migrado desde WSL2
│   ├── Telegram ↔ usuario
│   └── Dispatcher: lanza Claude Code via tmux
├── ChromaDB MCP (SSE, puerto 8421) ← fuente de verdad unica
│   └── bind 0.0.0.0 (accesible via Tailscale)
├── Claude Code                     ← sesiones remotas
│   ├── Agentes + Skills (setup.sh)
│   └── tmux sessions persistentes
├── code-server (puerto 8080)       ← VS Code en browser
│   └── expuesto via Cloudflare tunnel
└── Tailscale (red privada)         ← conecta todo

PC Windows (opcional, cuando este en casa)
├── Claude Code (local, mas rapido)
├── ChromaDB MCP → SSE al VPS (100.x.x.x:8421)
└── Hooks → POST al VPS (100.x.x.x:18789)

iPad / Celular (cuando viaje)
├── Telegram → Val → despacha tareas
├── code-server → browser
└── Termius → SSH + tmux
```

### Flujos de uso

| Escenario | Como trabajo |
|---|---|
| **En casa** | Claude Code local, hooks reportan al VPS, ChromaDB del VPS |
| **Viajando (laptop)** | SSH al VPS, Claude Code en tmux, o code-server en browser |
| **Viajando (iPad/cel)** | Telegram a Val: "corre /issue #42", Val despacha en el VPS |
| **Dormido/AFK** | Val puede ejecutar tareas programadas en el VPS autonomamente |

---

## Tareas

### Fase 1 — Preparar el VPS (infraestructura base)

> Prerequisito: contratar VPS Ubuntu 22.04+, 2-4GB RAM, 40GB+ disco.
> Providers recomendados: Hetzner ($4.5/mes), DigitalOcean ($6/mes), Contabo ($6/mes).

**Task 1.1 — Seguridad y paquetes base**
- Ejecutar el checklist existente en `vps/README.md` (seguridad, UFW, SSH hardening)
- Instalar paquetes: `git curl wget tmux build-essential python3 python3-pip`
- Instalar uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Archivos: `vps/README.md` (ya existe)

**Task 1.2 — Tailscale**
- Instalar Tailscale en el VPS
- `sudo tailscale up` → anotar IP (100.x.x.x)
- Instalar Tailscale en la PC Windows (si no esta)
- Verificar ping bidireccional: PC ↔ VPS via IP Tailscale
- Configurar UFW para permitir trafico Tailscale:
  ```bash
  sudo ufw allow in on tailscale0
  ```
- Archivos: `vps/README.md` (actualizar con paso de UFW para tailscale)

**Task 1.3 — Node.js + Claude Code**
- Instalar nvm + Node LTS
- `npm install -g @anthropic-ai/claude-code`
- Configurar `ANTHROPIC_API_KEY` en `~/.bashrc`
- Verificar: `claude --version`
- Archivos: `vps/README.md` (ya documentado)

**Task 1.4 — Desplegar agentes y skills**
- Clonar `devtools-config` en el VPS
- Ejecutar `./scripts/setup.sh` (ya detecta Linux nativo)
- Verificar: `claude` → `/lint`
- Archivos: `scripts/setup.sh` (sin cambios necesarios)

**Task 1.5 — code-server + Cloudflare tunnel**
- Instalar code-server, configurar password
- Instalar cloudflared, crear tunnel, exponer `code.tudominio.com`
- Verificar acceso desde browser
- Archivos: `vps/README.md` (ya documentado)

### Fase 2 — Migrar ChromaDB al VPS

**Task 2.1 — ChromaDB MCP en el VPS**
- El `setup.sh` ya instala ChromaDB MCP
- Cambiar bind de `127.0.0.1` a `0.0.0.0` para aceptar conexiones via Tailscale
- Registrar como servicio systemd (persistente):
  ```ini
  [Unit]
  Description=ChromaDB MCP SSE Server
  After=network.target

  [Service]
  Type=simple
  User=mario
  Environment=CHROMADB_PATH=/home/mario/.claude/chromadb
  Environment=CHROMADB_HOST=0.0.0.0
  Environment=CHROMADB_PORT=8421
  ExecStart=/home/mario/.local/bin/uv run --directory /home/mario/.claude/chromadb-mcp python server.py --mode sse
  Restart=always
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  ```
- UFW: solo Tailscale puede acceder al puerto 8421 (ya cubierto por `allow in on tailscale0`)
- Archivos a modificar:
  - `scripts/chromadb-mcp/manage-server.sh` — agregar opcion de generar/instalar systemd unit
  - `scripts/chromadb-mcp/server.py` — verificar que acepta `CHROMADB_HOST` env var
  - Nuevo: `vps/systemd/chromadb-mcp.service`

**Task 2.2 — Migrar datos de ChromaDB**
- Exportar `~/.claude/chromadb/` de Windows
- Copiar al VPS via scp: `scp -r ~/.claude/chromadb/ vps:~/.claude/chromadb/`
- Verificar integridad: `claude` → `/memory stats`
- Archivos: no se necesitan cambios de codigo

**Task 2.3 — PC local conecta a ChromaDB del VPS**
- Cambiar el MCP registration local de ChromaDB:
  ```bash
  claude mcp remove memory --scope user
  claude mcp add --transport sse --scope user memory "http://100.x.x.x:8421/sse"
  ```
- Actualizar `setup.sh` para detectar si hay un VPS configurado:
  - Nueva env var: `CHROMADB_REMOTE_URL` (si existe, registrar SSE remoto en vez de local)
  - Si no existe, comportamiento actual (servidor local)
- Archivos a modificar:
  - `scripts/setup.sh` — agregar logica de `CHROMADB_REMOTE_URL`

### Fase 3 — Migrar OpenClaw al VPS

**Task 3.1 — Instalar OpenClaw en el VPS**
- Instalar OpenClaw segun docs oficiales
- Copiar configuracion: `openclaw/openclaw.json` (sanitizado) al VPS
- Configurar credenciales (Telegram bot token, gateway token)
- Registrar como systemd service (ya existe unit en `openclaw/`):
  ```bash
  sudo cp openclaw-gateway.service /etc/systemd/system/
  sudo systemctl enable --now openclaw-gateway
  ```
- Verificar: enviar mensaje en Telegram, Val debe responder
- Archivos: `openclaw/` (sin cambios de codigo, solo deployment)

**Task 3.2 — Desactivar OpenClaw en WSL2**
- `wsl -- sudo systemctl disable --now openclaw-gateway`
- Desactivar Task Scheduler "OpenClaw Gateway" (ya no necesita WSL auto-start)
- Opcional: mantener WSL para desarrollo local pero sin OpenClaw
- Archivos: no se necesitan cambios

### Fase 4 — Parametrizar hooks

**Task 4.1 — Hooks con endpoint configurable**
- Cambiar ambos scripts de hook para usar `$OPENCLAW_HOST` en vez de `localhost`:
  ```bash
  # Antes
  ENDPOINT="http://localhost:18789/hooks/wake"

  # Despues
  OPENCLAW_HOST="${OPENCLAW_HOST:-localhost}"
  OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"
  ENDPOINT="http://${OPENCLAW_HOST}:${OPENCLAW_PORT}/hooks/wake"
  ```
- Configurar en `~/.bashrc` de la PC local:
  ```bash
  export OPENCLAW_HOST="100.x.x.x"  # IP Tailscale del VPS
  ```
- En el VPS, los hooks apuntan a localhost (OpenClaw corre ahi mismo)
- Archivos a modificar:
  - `claude-code/hooks/notify-openclaw.sh`
  - `claude-code/hooks/notify-openclaw-progress.sh`

**Task 4.2 — Sync hooks al destino**
- Re-desplegar hooks: `cp claude-code/hooks/*.sh ~/.claude/hooks/`
- Verificar: ejecutar Claude Code, ver que las notificaciones llegan a Telegram
- Archivos: no se necesitan cambios adicionales

### Fase 5 — Dispatcher (Telegram → Claude Code en VPS)

**Task 5.1 — Val como dispatcher de tareas**
- Enseñar a Val a lanzar sesiones de Claude Code via tmux:
  ```bash
  # Val ejecuta esto cuando recibe "corre /issue #42 en repo X"
  tmux new-session -d -s "task-42" \
    "cd /home/mario/projects/repo-x && claude --dangerously-skip-permissions -p '/issue #42'"
  ```
- Val monitorea la sesion tmux y reporta resultado a Telegram
- Val puede listar sesiones activas: `tmux list-sessions`
- Archivos a crear/modificar:
  - Nuevo skill o config en OpenClaw para el dispatcher
  - Documentar comandos que Val acepta: "corre X", "estado", "cancela X"

**Task 5.2 — Monitoreo de sesiones**
- Val puede hacer `tmux capture-pane` para ver el estado de una sesion
- Reportar progreso periodico a Telegram (los hooks ya lo hacen, pero Val podria resumir)
- Si una sesion termina, Val envia el resultado final
- Archivos: config de OpenClaw (no este repo)

### Fase 6 — Documentacion y cleanup

**Task 6.1 — Actualizar vps/README.md**
- Reescribir como guia paso a paso de la migracion completa
- Incluir: systemd units, UFW rules, Tailscale setup, ChromaDB, OpenClaw
- Agregar seccion de troubleshooting
- Archivos: `vps/README.md`

**Task 6.2 — Actualizar setup.sh**
- Agregar modo VPS: `./scripts/setup.sh --vps`
  - Instala systemd units para ChromaDB y OpenClaw
  - Configura bind addresses para Tailscale
  - No instala hooks de notificacion (OpenClaw es local en el VPS)
- Archivos: `scripts/setup.sh`

**Task 6.3 — Actualizar README principal**
- Agregar seccion sobre el modo VPS
- Documentar los 3 modos de uso: local, VPS, hibrido
- Archivos: `README.md`

---

## Orden de ejecucion

```
Fase 1 (infra base)      ████████████████░░░░░░░░░░░░  1-2 horas
  1.1 Seguridad
  1.2 Tailscale           ← punto de no retorno: el VPS existe y es accesible
  1.3 Node + Claude Code
  1.4 Agentes + Skills
  1.5 code-server

Fase 2 (ChromaDB)         ░░░░████████████░░░░░░░░░░░░  30 min
  2.1 Server en VPS
  2.2 Migrar datos
  2.3 PC conecta al VPS   ← a partir de aca, memoria unificada

Fase 3 (OpenClaw)          ░░░░░░░░████████░░░░░░░░░░░░  30 min
  3.1 Instalar en VPS
  3.2 Desactivar en WSL   ← a partir de aca, PC ya no necesita estar encendida

Fase 4 (hooks)             ░░░░░░░░░░░░████░░░░░░░░░░░░  15 min
  4.1 Parametrizar
  4.2 Sync + verificar    ← a partir de aca, hooks locales van al VPS

Fase 5 (dispatcher)        ░░░░░░░░░░░░░░░░████████░░░░  1-2 horas
  5.1 Val como dispatcher
  5.2 Monitoreo           ← a partir de aca, puedes despachar desde Telegram

Fase 6 (docs)              ░░░░░░░░░░░░░░░░░░░░░░██████  30 min
  6.1-6.3 Documentacion
```

**Tiempo estimado total: 4-6 horas** (asumiendo VPS ya contratado).

Despues de la Fase 3, ya puedes viajar. Las Fases 4-6 son mejoras que puedes hacer desde el VPS mismo.

---

## Specs del VPS recomendado

| Requisito | Minimo | Recomendado |
|---|---|---|
| RAM | 2 GB | 4 GB |
| CPU | 1 vCPU | 2 vCPU |
| Disco | 20 GB SSD | 40 GB SSD |
| OS | Ubuntu 22.04 | Ubuntu 24.04 |
| Ubicacion | Cualquiera | Cercano a ti (latencia SSH) |

**Uso de recursos estimado:**
- OpenClaw: ~100 MB RAM, idle casi siempre
- ChromaDB MCP: ~200 MB RAM (embeddings en memoria)
- Claude Code: ~150 MB RAM por sesion (Node.js)
- code-server: ~300 MB RAM
- **Total en uso tipico: ~750 MB — 1 GB**

**Providers con buena relacion precio/performance:**
- **Hetzner Cloud** — CX22 (2 vCPU, 4GB, 40GB): €4.35/mes (~$4.75)
- **DigitalOcean** — Basic (1 vCPU, 2GB, 50GB): $6/mes
- **Contabo** — VPS S (4 vCPU, 8GB, 50GB): $6.50/mes (overprovisioned pero barato)

---

## Riesgos y mitigaciones

| Riesgo | Impacto | Mitigacion |
|---|---|---|
| VPS cae | Sin acceso a OpenClaw ni ChromaDB | Provider con buen SLA; backup semanal de ChromaDB a PC |
| Tailscale cae | PC no puede conectar al VPS | code-server sigue accesible via Cloudflare (ruta alternativa) |
| Latencia ChromaDB via Tailscale | Agentes mas lentos desde PC local | ChromaDB es read-heavy al inicio; ~50ms no es perceptible |
| API key de Anthropic en el VPS | Superficie de ataque extra | SSH key-only, UFW strict, Tailscale aislado, no root |
| Disco del VPS se llena | ChromaDB + logs crecen | Monitorear con cron; ChromaDB prune mensual via `/memory prune` |

---

## Archivos que necesitan cambios

| Archivo | Cambio | Fase |
|---|---|---|
| `claude-code/hooks/notify-openclaw.sh` | `$OPENCLAW_HOST` en vez de `localhost` | 4 |
| `claude-code/hooks/notify-openclaw-progress.sh` | `$OPENCLAW_HOST` en vez de `localhost` | 4 |
| `scripts/setup.sh` | Logica de `CHROMADB_REMOTE_URL` + modo `--vps` | 2, 6 |
| `scripts/chromadb-mcp/manage-server.sh` | Opcion de systemd unit | 2 |
| `vps/README.md` | Reescribir como guia de migracion | 6 |
| `README.md` | Seccion de modo VPS | 6 |
| Nuevo: `vps/systemd/chromadb-mcp.service` | Unit file de systemd | 2 |
| Nuevo: `vps/systemd/openclaw-gateway.service` | Unit file de systemd (copia) | 3 |
