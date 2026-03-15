# devtools-config

Configuraciones y herramientas para mi ambiente de desarrollo local. El objetivo es documentar el flujo de trabajo completo y poder restaurarlo en cualquier sistema.

## Setup

```bash
git clone <repo>
cd devtools-config
./scripts/setup.sh
```

Instala todo: Claude Code (agentes, skills, MCP servers, hooks), ChromaDB, y el renderer de Excalidraw.

Prerequisites: `node`, `npm`, `python`, `git`. Opcional: `uv` (para excalidraw renderer).

## Estructura

```
devtools-config/
├── claude-code/         # Claude Code: agentes, skills, hooks, settings
├── openclaw/            # OpenClaw: agente Val (Telegram, WSL2 service)
├── scripts/             # Scripts de setup y utilidades
├── vps/                 # Setup de VPS (Ubuntu, Claude Code remoto)
├── presentation/        # Presentaciones (HTML)
└── windows-terminal/    # Configuracion de Windows Terminal
```

## Claude Code

11 agentes especializados + 19 slash commands + hooks de integración con OpenClaw. Pipeline completo: issue → diseño → implementacion → testing → delivery → PR.

Ver [`claude-code/README.md`](claude-code/README.md) para documentacion completa.

## OpenClaw

Agente Val — corre como servicio systemd en WSL2, se comunica via Telegram. Auto-start al login de Windows via Task Scheduler + VBS (sin consola visible).

Ver [`openclaw/README.md`](openclaw/README.md) para configuracion completa.

## Secrets

Lista unificada de todas las API keys y tokens necesarios para restaurar el entorno. Ver [`SECRETS.md`](SECRETS.md).

## Presentaciones

- `dev-team-agents.html` — Demo del sistema de agentes
- `intro-ai-devs.html` — Intro AI para developers

## Windows Terminal

Configuracion personalizada de Windows Terminal (`settings.json`).
