# devtools-config

Configuracion portable de mi entorno de desarrollo con IA. Un solo `git clone` + `setup.sh` restaura todo: un equipo de 13 agentes de IA especializados que colaboran para resolver issues, disenar arquitectura, escribir codigo, testear, y entregar PRs — todo coordinado automaticamente.

## Que hace esto?

Este repo contiene la configuracion completa de [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (el CLI de Anthropic) con un sistema de agentes que funciona como un equipo de desarrollo virtual:

```
Tu escribes:   /issue "agregar autenticacion OAuth"
                         |
El sistema:    Analiza → Disena → Implementa → Testea → Valida → Crea branch + PR
                         |              |            |         |
               (architect)  (implementer)   (tester) (qa + security)
```

Cada agente tiene un rol y restricciones claras. No es un solo prompt largo — son 11 agentes con system prompts especializados, coordinados por un orchestrator central que maneja el flujo, los reintentos, y la comunicacion entre ellos.

### Agentes

| Agente | Que hace |
|--------|----------|
| **orchestrator** | Coordina el pipeline completo, decide que agente invocar |
| **architect** | Disena arquitectura, investiga tecnologias, planifica tareas |
| **implementer** | Escribe codigo de produccion siguiendo el diseno |
| **tester** | Crea tests (factory mocks, coverage mapping contra specs) |
| **qa** | Valida que la implementacion cumple los criterios de aceptacion |
| **security** | Audita seguridad (OWASP Top 10, CWE, ASVS) |
| **delivery** | Crea branch, changelog, version bump, commit, PR |
| **reviewer** | Revisa PRs con comentarios detallados |
| **init** | Bootstrap de CLAUDE.md en repos nuevos |
| **diagrammer** | Genera diagramas Excalidraw con render-validate loop |
| **likec4-diagrammer** | Genera diagramas LikeC4 (architecture-as-code) |
| **d2-diagrammer** | Genera diagramas D2 (flowcharts, sequence, ER, architecture) |
| **agent-builder** | Crea y mejora agentes y skills del sistema |

### Comandos disponibles (22 slash commands)

Dentro de Claude Code, escribes `/comando` y el sistema hace el resto:

```
/issue <#N | texto>     Pipeline completo: issue → diseno → codigo → tests → PR
/plan <texto>           Planificacion: analiza y crea issues con criterios de aceptacion
/design <texto>         Solo arquitectura (sin implementar)
/research <topic>       Investigacion de tecnologias con reporte neutral
/test <feature>         Crea tests sobre codigo existente
/validate <feature>     Valida contra criterios de aceptacion
/deliver <feature>      Branch + changelog + version + PR
/define-ac <texto>      Define criterios de aceptacion (Given/When/Then)
/security <feature>     Auditoria de seguridad completa
/review-pr <#N>         Review de PR con aprobacion interactiva
/diagram <descripcion>  Diagrama Excalidraw (analisis + generacion)
/likec4-diagram <desc>  Diagrama LikeC4 (architecture-as-code)
/d2-diagram <desc>      Diagrama D2 (flowcharts, sequence, ER, architecture)
/init                   Bootstrap de CLAUDE.md en el repo actual
/spike <descripcion>    Exploracion rapida sin pipeline completo
/audit [target]         Health check de arquitectura
/resume [feature]       Retoma un pipeline interrumpido
/status [feature]       Estado de pipelines activos
/memory <action>        Gestiona la memoria persistente (Knowledge Graph)
/lint                   Valida que agentes y skills esten sanos
/tmux <action>          Sesiones tmux paralelas
/kg-viewer <action>     Viewer web de la memoria persistente
```

## Setup

```bash
git clone https://github.com/valianx/devtools-config.git
cd devtools-config
./scripts/setup.sh
```

El script detecta el entorno (Windows/WSL/macOS/Linux) y despliega:

- **Agentes** → `~/.claude/agents/` (system prompts)
- **Skills** → `~/.claude/commands/` (slash commands)
- **ChromaDB MCP** → `~/.claude/chromadb-mcp/` (memoria persistente con busqueda semantica)
- **context7 MCP** → documentacion actualizada de librerias
- **Excalidraw renderer** → generacion de diagramas con validacion visual

En Windows con WSL, configura ambos entornos automaticamente (incluyendo ChromaDB compartida).

**Prerequisites:** `node`, `npm`, `python`, `git`. Opcional: `uv` (para el renderer de Excalidraw).

**Verificar instalacion:** abrir Claude Code y ejecutar `/lint`.

## Estructura del repo

```
devtools-config/
├── claude-code/              # Configuracion de Claude Code
│   ├── agents/               #   System prompts de los 13 agentes
│   ├── skills/               #   22 slash commands + diagram skills
│   ├── hooks/                #   Scripts de integracion con OpenClaw
│   └── settings.json         #   Respaldo de settings globales
│
├── scripts/
│   ├── setup.sh              #   Setup centralizado (detecta entorno)
│   └── chromadb-mcp/         #   Servidor MCP para memoria persistente
│
├── openclaw/                 # OpenClaw: agente Telegram (Val)
├── vps/                      # Checklist de setup para VPS remoto
├── presentation/             # Presentaciones HTML del sistema
└── windows-terminal/         # Configuracion de Windows Terminal
```

## Como funciona el pipeline

Cuando ejecutas `/issue`, el orchestrator coordina este flujo:

```
 0a Intake        Clasifica la tarea, consulta memoria, verifica CLAUDE.md
      |
 0b Specify       Investiga el codebase, escribe spec con criterios de aceptacion
      |
  1 Design        architect produce propuesta de arquitectura
      |
  2 Implement     implementer escribe codigo siguiendo el diseno
      |
  3 Verify        tester + qa + security* corren en paralelo (*si aplica)
      |            Si falla → implementer arregla → re-verify (max 3 loops)
      |
  4 Delivery      Branch, changelog, version bump, commit, PR
      |
  5 GitHub        Comenta la issue con resultados, mueve a "In Review"
```

Los agentes se comunican via archivos en `session-docs/` (un tablero compartido). Cada tarea tiene su carpeta con specs, diseno, reporte de tests, validacion, y delivery.

### Ejecucion paralela de tareas

Cuando `/plan-and-execute` produce multiples tareas independientes, el sistema las ejecuta en paralelo usando git worktrees:

```
Round 1:  [Task 1: fundacional]                    ← secuencial
Round 2:  [Task 2: depende de 1]                   ← secuencial
Round 3:  [Task 3] [Task 4] [Task 5]               ← PARALELO (worktrees + tmux)
```

Cada tarea paralela corre en su propia instancia de Claude Code (`claude --worktree --tmux`), con su propio branch y session-docs.

## Memoria persistente

El sistema recuerda decisiones y patrones entre sesiones:

1. **ChromaDB** (cross-project) — busqueda semantica con embeddings locales. El orchestrator lee al inicio y escribe al final de cada pipeline.
2. **CLAUDE.md** (per-project) — el agente delivery extrae conocimiento y lo persiste en el repo.

## OpenClaw (opcional)

Integracion con Telegram via OpenClaw. Claude Code notifica progreso del pipeline a un chat de Telegram en tiempo real. Corre como servicio systemd en WSL2 con auto-start al login de Windows.

Ver [`openclaw/README.md`](openclaw/README.md) para configuracion.

## VPS (opcional)

Checklist para montar el mismo entorno en un VPS Ubuntu con acceso remoto (VS Code via code-server + Cloudflare tunnel + Tailscale).

Ver [`vps/README.md`](vps/README.md) para el setup.

## Documentacion detallada

- [`claude-code/README.md`](claude-code/README.md) — documentacion tecnica completa del sistema de agentes
- [`claude-code/agents/README`](claude-code/agents/README) — roster de agentes, pipeline, flujos especiales
- [`SECRETS.md`](SECRETS.md) — lista de API keys necesarias para restaurar el entorno
