# devtools-config

Configuraciones de herramientas de desarrollo, sistema de agentes AI, y recursos de presentacion.

## Estructura

```
devtools-config/
├── AI development/          # Sistema de agentes para Claude Code
│   ├── agents/              # 11 agentes especializados
│   ├── skills/              # 19 slash commands (entry points)
│   ├── diagram.excalidraw   # Diagrama visual del sistema
│   └── README.md            # Documentacion completa de flujos
│
├── presentation/            # Presentaciones
│   ├── dev-team-agents.html # Demo del sistema de agentes
│   └── intro-ai-devs.html   # Intro AI para developers
│
├── windows-terminal/        # Configuracion de Windows Terminal
│   └── settings.json
│
└── .claude/                 # Configuracion activa de Claude Code
    ├── commands/            # Skills desplegadas (slash commands)
    └── skills/              # Skills complejas (excalidraw-diagram)
```

## AI Development

Sistema de agentes coordinados por un orchestrator central. Ciclo completo: issue → pipeline → PR.

### Agentes

| Agente | Rol |
|--------|-----|
| **orchestrator** | Hub central — coordina todo el equipo |
| **architect** | Arquitectura, investigacion, planning, auditoria |
| **implementer** | Codigo de produccion |
| **tester** | Tests con factory mocks |
| **qa** | Validacion contra AC / define AC |
| **security** | Auditoria de seguridad (OWASP, CWE, ASVS) |
| **delivery** | Branch, changelog, version, commit, PR |
| **reviewer** | Review de PRs en GitHub |
| **init** | Bootstrap de CLAUDE.md |
| **diagrammer** | Diagramas Excalidraw |
| **agent-builder** | Crea y mejora agentes y skills |

### Skills

| Skill | Tipo | Descripcion |
|-------|------|-------------|
| `/issue` | pipeline | Full pipeline desde GitHub issue o texto |
| `/plan` | pipeline | Planning + breakdown de tareas |
| `/design` | direct | Solo arquitectura |
| `/research` | direct | Investigacion de tecnologias |
| `/test` | direct | Tests standalone |
| `/validate` | direct | Validacion contra AC |
| `/deliver` | direct | Delivery: branch, docs, version, PR |
| `/define-ac` | direct | Definir criterios de aceptacion |
| `/security` | direct | Auditoria de seguridad |
| `/review-pr` | direct | Review de PR |
| `/diagram` | direct | Diagrama Excalidraw |
| `/init` | direct | Bootstrap del repo |
| `/spike` | direct | Exploracion rapida sin pipeline |
| `/audit` | direct | Auditoria de arquitectura |
| `/resume` | direct | Retomar pipeline interrumpido |
| `/status` | standalone | Estado de pipelines activos |
| `/memory` | standalone | Gestionar Knowledge Graph |
| `/lint` | standalone | Health check de agentes y skills |
| `/tmux` | standalone | Sesiones tmux paralelas |

### Pipeline

```
Intake → Specify → Design → Implement → Verify → Delivery → GitHub
                                           ↑         │
                                           └── fix ──┘  (max 3)

Verify (paralelo): tester + qa + security*  (*si security-sensitive)
```

Ver `AI development/README.md` para documentacion completa de los 15 flujos.

## Despliegue

```
AI development/agents/  →  ~/.claude/agents/          (global)
AI development/skills/  →  ~/.claude/commands/         (global)
                        →  .claude/commands/            (proyecto)
```

Validar sincronizacion: `/lint`

## Uso

El orchestrator es el punto de entrada. Nunca invocar agentes directamente.

```
/issue #123              # Pipeline completo para un issue
/plan feature-name       # Planifica y descompone en tareas
/research topic          # Investiga una tecnologia
/spike "probar X con Y"  # Exploracion rapida
/audit src/              # Auditoria de arquitectura
/status                  # Ver pipelines activos
```
