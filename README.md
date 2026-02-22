# devtools-config

Sistema de agentes especializados para desarrollo de software con Claude Code. Un equipo de agentes coordinados por un orchestrator central que maneja el ciclo completo: desde la planificacion hasta el delivery.

## Estructura del repo

```
agents/                  # Definiciones de agentes
.claude/commands/        # Skills (slash commands)
presentation/            # Presentaciones
windows-terminal/        # Configuracion de Windows Terminal
```

## Agentes

| Agente | Archivo | Rol |
|--------|---------|-----|
| `dev-orchestrator` | `dev-orchestrator.md` | Hub central, coordina todo el equipo |
| `architect` | `architect.md` | Arquitectura, investigacion y planificacion |
| `implementer` | `implementer.md` | Escribe codigo de produccion |
| `tester` | `tester.md` | Crea y ejecuta tests |
| `qa` | `qa.md` | Valida implementaciones y define criterios de aceptacion |
| `delivery` | `delivery.md` | Documenta, versiona, crea branch y commitea |
| `reviewer` | `reviewer.md` | Revisa PRs en GitHub |
| `init` | `init.md` | Bootstrap de CLAUDE.md en cualquier repo |

## Skills

Todos los skills rutean al orchestrator. Se invocan como `/skill` en Claude Code.

| Skill | Descripcion |
|-------|-------------|
| `/issue` | Recibe issue de GitHub o texto, ejecuta pipeline completo |
| `/plan` | Planificacion y breakdown de tareas |
| `/research` | Investigacion de tecnologias y librerias |
| `/design` | Diseno de arquitectura |
| `/init` | Bootstrap del repo |
| `/test` | Tests standalone |
| `/validate` | Validacion contra criterios de aceptacion |
| `/define-ac` | Define criterios de aceptacion |
| `/deliver` | Delivery standalone |
| `/review-pr` | Revisa un PR en GitHub |

## Pipeline

```
Specify (AC) -> Design -> Implement -> Verify (test + validate) -> Delivery
```

El orchestrator coordina las fases y maneja iteraciones cuando la verificacion falla (max 3 loops).

## Uso

El orchestrator es siempre el punto de entrada. Nunca se invocan agentes directamente.

```
/issue #123          # Ejecuta pipeline completo para un issue
/plan feature-name   # Planifica y descompone en tareas
/research topic      # Investiga una tecnologia
```

Los agentes se sincronizan en dos ubicaciones:
- **Proyecto:** `agents/`
- **Global:** `~/.claude/agents/`
