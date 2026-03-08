# devtools-config

Configuraciones y herramientas para mi ambiente de desarrollo local.

## Setup

```bash
git clone <repo>
cd devtools-config
./setup.sh
```

Instala todo: Claude Code, agentes, skills, MCP servers (Memory + context7), ChromaDB, y el renderer de Excalidraw.

Prerequisites: `node`, `npm`, `python`, `git`. Opcional: `uv` (para excalidraw renderer).

## Estructura

```
devtools-config/
├── AI development/      # Sistema de agentes AI para Claude Code
├── presentation/        # Presentaciones (HTML)
├── windows-terminal/    # Configuracion de Windows Terminal
└── setup.sh             # Setup automatizado del ambiente
```

## AI Development

Sistema de 11 agentes especializados coordinados por un orchestrator central. 19 slash commands como entry points. Pipeline completo: issue → diseño → implementacion → testing → delivery → PR.

Ver [`AI development/README.md`](AI%20development/README.md) para documentacion completa.

## Presentaciones

- `dev-team-agents.html` — Demo del sistema de agentes
- `intro-ai-devs.html` — Intro AI para developers

## Windows Terminal

Configuracion personalizada de Windows Terminal (`settings.json`).
