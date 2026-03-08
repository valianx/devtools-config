# AI Development

Sistema de agentes especializados para Claude Code. Un equipo de desarrollo autónomo coordinado por un orchestrator central que gestiona el ciclo completo: desde la issue hasta el PR.

## Estructura

```
AI development/
├── agents/                  # Definiciones de agentes (system prompts)
│   ├── orchestrator.md      # Hub central — coordina todo el equipo
│   ├── architect.md         # Diseño, investigación, planning, auditoría
│   ├── implementer.md       # Código de producción
│   ├── tester.md            # Tests con factory mocks
│   ├── qa.md                # Validación contra AC / definición de AC
│   ├── security.md          # Auditoría de seguridad (OWASP, CWE, ASVS)
│   ├── delivery.md          # Branch, changelog, version, commit, PR
│   ├── reviewer.md          # Review de PRs en GitHub
│   ├── init.md              # Bootstrap de CLAUDE.md en cualquier repo
│   ├── diagrammer.md        # Diagramas Excalidraw con render-validate loop
│   └── agent-builder.md     # Crea y mejora agentes y skills
│
├── skills/                  # Entry points (slash commands)
│   ├── issue.md             # /issue — full pipeline desde GitHub issue o texto
│   ├── plan.md              # /plan — planning + breakdown de tareas
│   ├── design.md            # /design — solo arquitectura
│   ├── research.md          # /research — investigación de tecnologías
│   ├── test.md              # /test — tests standalone
│   ├── validate.md          # /validate — validación contra AC
│   ├── deliver.md           # /deliver — delivery standalone
│   ├── define-ac.md         # /define-ac — definir criterios de aceptación
│   ├── security.md          # /security — auditoría de seguridad
│   ├── review-pr.md         # /review-pr — review de PR
│   ├── diagram.md           # /diagram — diagrama Excalidraw
│   ├── init.md              # /init — bootstrap del repo
│   ├── spike.md             # /spike — exploración rápida sin pipeline
│   ├── audit.md             # /audit — auditoría de arquitectura
│   ├── resume.md            # /resume — retomar pipeline interrumpido
│   ├── status.md            # /status — estado de pipelines (standalone)
│   ├── memory.md            # /memory — gestión de Knowledge Graph (standalone)
│   ├── lint.md              # /lint — health check de agentes (standalone)
│   ├── tmux.md              # /tmux — sesiones paralelas (standalone)
│   └── excalidraw-diagram/  # Skill compleja con templates y renderer
│       ├── SKILL.md
│       └── references/
│
└── diagram.excalidraw       # Diagrama visual del sistema completo
```

## Cómo funciona

```
Usuario ──> /skill ──> Orchestrator ──> Agente(s) ──> session-docs ──> Resultado
```

Todas las skills (excepto `/lint`, `/tmux`, `/status`, `/memory`) rutean al **orchestrator**, que decide qué agente(s) invocar.

---

## Agentes

| Agente | Modelo | Rol | Escribe código |
|--------|--------|-----|:--------------:|
| **orchestrator** | opus | Hub central, coordina todo el equipo | No |
| **architect** | opus | Diseña arquitectura, investiga, planifica, audita | No |
| **implementer** | opus | Escribe código de producción | Sí |
| **tester** | opus | Crea y ejecuta tests (factory mocks) | Sí (tests) |
| **qa** | opus | Valida contra AC o define AC standalone | No |
| **security** | opus | Audita seguridad (OWASP, CWE, ASVS) | No |
| **delivery** | opus | Documenta, versiona, branch, commit, PR | No |
| **reviewer** | opus | Revisa PRs en GitHub | No |
| **init** | opus | Bootstrap de CLAUDE.md en cualquier repo | No |
| **diagrammer** | opus | Genera diagramas Excalidraw | No |
| **agent-builder** | opus | Crea y mejora agentes y skills | Sí |

### Modos del architect

| Modo | Trigger | Output |
|------|---------|--------|
| **design** (default) | Phase 1 del pipeline o `/design` | `01-architecture.md` |
| **research** | `/research` o investigación previa a diagram | `00-research.md` |
| **planning** | `/plan` — breakdown de tareas | `01-planning.md` |
| **audit** | `/audit` — salud arquitectónica | `00-audit.md` |

### Modos del qa

| Modo | Trigger | Output |
|------|---------|--------|
| **validate** | Phase 3 del pipeline o `/validate` | `04-validation.md` |
| **define-ac** | `/define-ac` standalone | `00-acceptance-criteria.md` |

---

## Skills (Entry Points)

### Rutean al orchestrator (15 skills)

```
/issue <#N | texto>        Full pipeline o batch de issues
/plan <#N | texto>         Planning + opcionalmente ejecutar cada tarea
/design <#N | texto>       Solo arquitectura (intake + specify + design)
/research <topic>          Investigación de tecnologías/approaches
/test <feature>            Solo tests sobre implementación existente
/validate <feature>        Validación contra AC existentes
/deliver <feature>         Delivery: branch, docs, changelog, version, PR
/define-ac <#N | texto>    Definir criterios de aceptación
/security <feature>        Auditoría de seguridad
/review-pr <#N>            Review de PR con aprobación del usuario
/diagram <descripción>     Diagrama Excalidraw (architect + diagrammer)
/init                      Bootstrap del repo
/spike <descripción>       Exploración rápida sin pipeline completo
/audit [target]            Auditoría de arquitectura (health check)
/resume [feature]          Retomar pipeline interrumpido
```

### Standalone (4 skills — NO rutean al orchestrator)

```
/status [feature]          Estado de pipelines activos en session-docs
/memory <action>           Gestionar Knowledge Graph (search, list, prune, consolidate)
/lint                      Health check de agentes y skills
/tmux <action>             Sesiones tmux paralelas
```

---

## Flujo 1 — Pipeline Principal (`/issue`)

El flujo completo desde una issue de GitHub o texto libre hasta un PR listo para review.

```
0a Intake ──> 0b Specify ──> 1 Design ──> 2 Implement ──> 3 Verify ──> 4 Delivery ──> 5 GitHub
                                               ↑              │
                                               └── fail ──────┘  (max 3 iteraciones)

                                          Phase 3 — Verify (paralelo):
                                          ├── tester
                                          ├── qa (validate)
                                          └── security* (*solo si security-sensitive)
```

### Phase 0a — Intake (orchestrator)

```
Input (issue/texto) ──> Duplicate check ──> Knowledge Graph query ──> Classify ──> Bootstrap check
                             │                    │                      │               │
                        ¿00-state.md         Busca entities         type/complexity   ¿CLAUDE.md?
                         ya existe?           relacionadas          /security-sens.   ¿CHANGELOG?
                             │                    │                      │            ¿.gitignore?
                        Sí → avisar           Pasa como               classify         │
                        al usuario            Hot Context                          No → init agent
```

1. **Duplicate check** — busca `session-docs/{feature}/00-state.md` activo. Si existe, sugiere `/resume`
2. **Knowledge Graph** — consulta Memory MCP por proyecto/tecnología. Resultados van a Hot Context
3. **Clasificación:**
   - Tipo: `feature` | `fix` | `refactor` | `hotfix` | `enhancement` | `research` | `spike`
   - Complejidad: `simple` (skip design) | `standard` | `complex` (extended review)
   - Security-sensitive: `true` si toca auth, secrets, APIs, DB queries, CORS/CSP, o es `complex`
4. **Bootstrap** — verifica CLAUDE.md, CHANGELOG.md, .gitignore. Si falta algo → invoca `init`
5. **GitHub** — mueve issue a "In Progress" en el project board

**Skip rules:**
- `spike` → salta al Spike Flow
- Batch de issues → salta a Multi-Task Orchestration

### Phase 0b — Specify (orchestrator)

```
Investigate codebase ──> Build spec ──> Resolve ambiguities ──> Update GitHub issue ──> Write 00-task-intake.md
      │                      │                  │                       │
  Glob/Grep/Read        User Stories        Pregunta al              gh issue edit
  archivos afectados    AC Given/When/Then  usuario si hay           con formato SDD
  patrones existentes   Scope in/out        [NEEDS CLARIFICATION]
  APIs, dependencias    Codebase context
```

- **Full SPECIFY** (`needs-specify: true`): construye AC desde cero, actualiza la issue
- **Light SPECIFY** (`needs-specify: false`): verifica AC existentes, agrega contexto técnico
- **Skip** para `hotfix` y `simple`

**Formato SDD (Spec-Driven Development):**
```
## User Story
As a {role}, I want {action}, so that {benefit}.

## Acceptance Criteria
- [ ] AC-1: Given {context}, When {action}, Then {result}

## Scope
Included: ... | Excluded: ...

## Technical Context
Files, Patterns, Constraints, Dependencies
```

### Phase 1 — Design (architect)

```
Orchestrator ──> architect (design mode) ──> 01-architecture.md
                      │
                 Lee 00-task-intake.md
                 Investiga codebase via context7
                 Produce propuesta con:
                 - Decisiones de arquitectura
                 - Security/performance/accessibility assessment
                 - Archivos a crear/modificar
```

- **Gate:** status block del architect. Success → Phase 2. Failed → lee `01-architecture.md` para diagnosticar
- **Skip** para `hotfix`/`simple`

### Phase 2 — Implementation (implementer)

```
Orchestrator ──> implementer ──> código de producción ──> 02-implementation.md
                     │
                Lee 01-architecture.md
                Lee 00-task-intake.md (AC)
                Investiga docs via context7
                Escribe código + build/lint internal loop
```

- **Gate:** status block. Success → Phase 3. Failed → lee `02-implementation.md`
- El implementer tiene su propio loop interno para fix de build/lint

### Phase 3 — Verify (tester + qa + security en paralelo)

```
Orchestrator ─┬──> tester ────────> 03-testing.md
              ├──> qa (validate) ──> 04-validation.md
              └──> security* ─────> 04-security.md     (*solo si security-sensitive)
                        │
                   Todos en paralelo
                   Todos leen 02-implementation.md
                   Tester mapea cada AC a tests
```

**Gate:** todos deben devolver `status: success`

**Si alguno falla → Iteration Loop:**

```
              ┌──────────────────────────────────────────────┐
              │                                              │
Verify FAIL ──┤  Case A: Tests/AC fallan                     │
              │    → implementer arregla → re-verify TODO    │
              │                                              │
              │  Case B: Gap de arquitectura                 │
              │    → architect revisa → implementer arregla  │
              │    → re-verify TODO                          │
              │                                              │
              │  Case C: AC incorrectos                      │
              │    → orchestrator ajusta spec → re-verify    │
              │                                              │
              │  Case D: Solo security falla                 │
              │    → implementer arregla → re-verify SOLO    │
              │      security (tester+qa ya pasaron)         │
              └──────────────────────────────────────────────┘
              Max 3 iteraciones. Si se excede → approach alternativo o escalar al usuario.
```

**Security gate:**
- Critical/High → bloquean delivery (deben iterarse)
- Medium/Low/Info → warnings en el reporte, NO bloquean

### Phase 4 — Delivery (delivery agent)

```
Orchestrator ──> delivery ──> branch + CHANGELOG + version bump + CLAUDE.md memory + commit + PR
                    │
               Lee session-docs completo
               Extrae knowledge → actualiza CLAUDE.md (4 secciones de memoria)
               Actualiza README.md si aplica
               Crea feature branch (nunca commitea a main)
               Escribe 05-delivery.md
```

- **No itera** — si falla (push rejected, etc.), reporta al usuario

### Phase 5 — GitHub Update (orchestrator)

```
Orchestrator ──> gh issue comment (resultados detallados, cada AC con pass/fail)
             ──> gh project item-edit (mover a "In Review")
             ──> NO cierra la issue (queda para review humano)
```

- **No itera** — si falla, reporta pero considera la tarea completa

### Knowledge Save (post-pipeline)

```
Orchestrator ──> Memory MCP
                    │
               1. Extrae 1-3 insights reutilizables
               2. Dedup check (search_nodes ANTES de create)
               3. create_entities solo si no hay match
               4. Auto-consolidate si >100 entities
```

- Solo en pipelines productivos: full, plan, design, research, test, security
- NO en: review, init, define-ac, deliver, diagram, validate

---

## Flujo 2 — Planning (`/plan`)

Análisis de un problema grande y descomposición en tareas implementables.

```
/plan <input>
  │
  ├─ mode: plan (solo análisis)
  │    Intake ──> Specify ──> architect (planning mode) ──> 01-planning.md
  │                                                              │
  │                                                     Task breakdown con AC
  │                                                     Cada tarea ≤ 1 día
  │                                                     Min 2, max 20 AC por tarea
  │                                                              │
  │    Orchestrator valida sizing (>20 AC → re-split, max 1 retry)
  │                                                              │
  │    gh issue create por cada tarea (formato SDD) ──> STOP
  │
  └─ mode: plan-and-execute
       (mismo que arriba) ──> batch-progress.md ──> Pipeline completo por cada tarea
```

**Sizing rules del architect:**
- Tarea demasiado grande si: necesita su propia propuesta de arquitectura, toca >3-4 áreas, >5 AC, o describe un feature end-to-end
- Tarea demasiado pequeña si: cambio de 1 línea sin AC, o solo existe como dependencia
- Split strategies: por layer, por behavior, por componente, por dependencia

---

## Flujo 3 — Research (`/research`)

Investigación de tecnologías, comparación de alternativas, evaluación de migraciones.

```
/research <topic>
  │
  Intake (classify as research)
  │
  architect (research mode) ──> 00-research.md
  │
  Presenta reporte al usuario
  │
  Pregunta: ¿implementar recomendación, descartar, o investigar más?
```

- NO produce propuesta de arquitectura
- Produce reporte neutral, basado en evidencia, con opciones y recomendación
- Fases 2-5 no se ejecutan

---

## Flujo 4 — Design (`/design`)

Solo diseño de arquitectura, sin implementación.

```
/design <input>
  │
  Intake ──> Specify ──> architect (design mode) ──> 01-architecture.md
  │
  Presenta propuesta al usuario
```

- Ejecuta Intake + Specify + Phase 1
- Se detiene después del design (no implementa)

---

## Flujo 5 — Spike (`/spike`)

Exploración rápida de una hipótesis técnica sin ceremonia de pipeline.

```
/spike <descripción>
  │
  Intake (classify as spike, complexity: simple)
  │
  Minimal 00-task-intake.md (solo: descripción, qué probar, criterio de éxito)
  │
  implementer ("spike mode" — sin tests, código exploratorio)
  │
  Presenta resultados + opciones:
  ├── 1. Formalizar → gh issue create con hallazgos como contexto técnico
  ├── 2. Descartar → git checkout (confirma con usuario)
  └── 3. Investigar más → otro spike o /research
```

- Skip Design, Testing, Validation, Delivery, GitHub
- El implementer documenta hallazgos en `02-implementation.md`

---

## Flujo 6 — Audit (`/audit`)

Evaluación de salud arquitectónica de un módulo o proyecto.

```
/audit [target]
  │
  architect (audit mode)
  │
  Deep scan: estructura, dependencias, patrones, duplicación, dead code, layer violations
  │
  00-audit.md con findings:
  ├── Critical (arreglar pronto)
  ├── Warning (deuda técnica acumulándose)
  └── Info (oportunidades de mejora)
```

- NO produce propuesta de arquitectura ni task breakdown
- Diagnostica y recomienda, el equipo decide qué actuar

---

## Flujo 7 — Security (`/security`)

Auditoría de seguridad contra OWASP Top 10 2025, CWE Top 25, ASVS 5.0.

```
/security [target]
  │
  security agent
  │
  Evalúa: inyección, auth flaws, secrets hardcoded, config insegura, CORS/CSP
  │
  04-security.md con findings priorizados:
  ├── Critical / High (bloquean delivery en pipeline)
  ├── Medium / Low (warnings)
  └── Info (mejoras)
```

- Como standalone: auditoría completa del target
- En pipeline (Phase 3): focalizado en archivos cambiados

---

## Flujo 8 — Review (`/review-pr`)

Review de pull requests en GitHub con aprobación humana.

```
/review-pr <#N>
  │
  Skill hace TODO el Bash:
  ├── gh pr view (metadata)
  ├── gh pr diff (cambios)
  ├── Detecta linked issue
  └── Pasa todo inline al orchestrator
  │
  Orchestrator ──> reviewer (data-provided mode, ZERO Bash)
  │
  Reviewer analiza y devuelve review_body + decision (APPROVE/CHANGES_REQUESTED)
  │
  Orchestrator escribe draft a .claude/pr-review-draft.md
  │
  Skill muestra draft al usuario ──> aprobación ──> publica review en GitHub
```

- El reviewer NUNCA ejecuta Bash — recibe todo como datos inline
- El usuario SIEMPRE aprueba antes de publicar

---

## Flujo 9 — Diagram (`/diagram`)

Generación de diagramas Excalidraw con render-validate loop.

```
/diagram <descripción>
  │
  Orchestrator Step 1:
  architect (research mode) ──> 00-research.md (análisis de qué diagramar)
  │
  Orchestrator Step 2:
  diagrammer ──> Lee análisis + SKILL.md + references
              ──> Phase 0: Design plan (visual patterns, sections)
              ──> Phase 1: JSON section-by-section
              ──> Phase 1.5: Structural validation gate
              ──>    arrows > 0? ✓
              ──>    all sections present? ✓
              ──>    element count proportional? ✓
              ──>    key components exist? ✓
              ──> Phase 2: Render-validate loop (max 5 rounds)
              ──>    render PNG → view → audit → fix → re-render
              ──> Phase 3: Quality checklist
              ──> diagram.excalidraw
  │
  Orchestrator Step 2.5:
  Validates output (arrows > 0, element count, key components)
  Si falla → re-invoca diagrammer con feedback (max 2 retries)
  │
  Presenta resultado al usuario
```

---

## Flujo 10 — Deliver (`/deliver`)

Delivery standalone de una implementación existente.

```
/deliver <feature>
  │
  delivery agent
  │
  Lee session-docs completo
  Crea feature branch
  Actualiza CHANGELOG.md
  Bump de versión (semver)
  Extrae knowledge → CLAUDE.md + docs/knowledge.md
  Commitea y pushea
  Crea PR
```

- Prerequisito: debe existir implementación + validación previa

---

## Flujo 11 — Resume (`/resume`)

Retoma un pipeline interrumpido desde el último checkpoint.

```
/resume [feature]
  │
  ├── Feature especificado:
  │     Lee 00-state.md ──> valida estado ──> pasa recovery context al orchestrator
  │
  └── Sin input:
        Escanea session-docs/*/00-state.md
        ├── 0 incompletos → "No hay pipelines interrumpidos"
        ├── 1 incompleto → auto-select
        └── N incompletos → pregunta al usuario cuál retomar
  │
  Orchestrator recibe:
  ├── Phase actual
  ├── Status e iteración
  ├── Hot Context
  ├── Recovery Instructions
  └── Agent Results previos
  │
  Continúa desde el último checkpoint
```

---

## Flujo 12 — Init (`/init`)

Bootstrap de CLAUDE.md en cualquier repositorio.

```
/init
  │
  init agent
  │
  Detecta stack (framework, lenguaje, test runner, linter, package manager)
  Genera CLAUDE.md con golden commands y secciones de memoria vacías
  Crea CHANGELOG.md si no existe
  Verifica .gitignore tiene /session-docs
```

---

## Flujo 13 — Test (`/test`)

Tests standalone sobre código existente.

```
/test <feature>
  │
  tester agent
  │
  Lee 02-implementation.md + AC de 00-task-intake.md
  AC Coverage Mapping: cada AC → al menos 1 test
  Factory mocks (nunca mocks manuales)
  Escribe 03-testing.md con tabla de AC Coverage
```

---

## Flujo 14 — Validate (`/validate`)

Validación standalone contra AC existentes.

```
/validate <feature>
  │
  qa agent (validate mode)
  │
  Lee 00-task-intake.md (AC) + 02-implementation.md (código)
  Valida cada AC individualmente (pass/fail con evidencia)
  Escribe 04-validation.md
```

---

## Flujo 15 — Define AC (`/define-ac`)

Genera criterios de aceptación desde cero para una feature.

```
/define-ac <input>
  │
  qa agent (define-ac mode)
  │
  Investiga codebase
  Genera AC en formato Given/When/Then
  Escribe 00-acceptance-criteria.md
```

---

## Flujos Standalone (no orchestrator)

### `/status` — Estado de pipelines

```
Escanea session-docs/*/00-state.md
Muestra tabla: feature, phase, status, iter, last updated, next action
Acciones: list (default), <feature> (detallado), clean (eliminar completos)
```

### `/memory` — Knowledge Graph

```
search <query>       Busca entities por texto
list [type]          Lista entities (filter: pattern/error/constraint/decision/tool-gotcha)
show <entity>        Detalle completo de una entity
stats                Estadísticas del graph
prune                Encuentra candidatos para eliminar (stale, duplicados)
consolidate          Merge de entities similares
```

### `/lint` — Health check

```
Valida sincronización de agentes y skills entre:
- Fuente (AI development/) ↔ proyecto (.claude/) ↔ global (~/.claude/)
```

### `/tmux` — Sesiones paralelas

```
Detecta runtime (Windows/WSL/Linux)
Gestiona sesiones tmux para múltiples Claude Code en paralelo
```

---

## Flujos Especiales del Pipeline

### Hotfix (expedido)

```
Intake → skip Design → Implement → Test (critical paths) → Validate (abreviado) → Delivery
```

### Security-sensitive (extendido)

```
Design obligatorio con análisis de seguridad
→ Phase 3 lanza security en paralelo con tester+qa
→ Critical/High bloquean delivery
→ Medium/Low/Info son warnings
```

### Database changes

```
Design incluye migration strategy
→ Implementation incluye migration files
→ Validation verifica safety y rollback
→ Delivery documenta rollback procedure
```

### Multi-Task (batch)

```
/issue #1 #2 #3
→ batch-progress.md trackea: | # | Task | Status | Feature Folder | Notes |
→ Cada task en su propia session-docs/{feature}/
→ Estados: PENDING → SPECIFYING → DESIGN → IMPLEMENTING → VERIFYING → DELIVERING → DONE
```

---

## Session-Docs (Shared Board)

Canal de comunicación entre agentes. Cada feature tiene su carpeta en `session-docs/{feature-name}/`.

```
00-state.md              ← orchestrator (checkpoint: phase, iteration, hot context, recovery)
00-execution-log.md      ← todos los agentes (append start/end con timestamp)
00-task-intake.md        ← orchestrator (spec completa con AC)
00-init.md               ← init (reporte de bootstrap: stack, commands, archivos creados)
00-research.md           ← architect (research mode)
00-audit.md              ← architect (audit mode)
00-acceptance-criteria.md ← qa (define-ac mode, standalone)
01-architecture.md       ← architect (design mode)
01-planning.md           ← architect (planning mode)
02-implementation.md     ← implementer
03-testing.md            ← tester
04-validation.md         ← qa (validate mode)
04-security.md           ← security
04-review.md             ← reviewer (findings, decisión, resumen)
05-delivery.md           ← delivery
05-diagram.md            ← diagrammer (summary)
diagram.excalidraw       ← diagrammer (output)
```

Siempre en `.gitignore` (`/session-docs`).

---

## Sistema de Memoria (3 Capas)

```
┌────────────────────────────────────────────────────────────────┐
│  Capa 1: Knowledge Graph MCP (cross-project)                   │
│  Archivo: ~/.claude/knowledge.json                             │
│  Quién escribe: orchestrator (post-pipeline)                   │
│  Quién lee: orchestrator (Phase 0a)                            │
│  Gestión: /memory (search, prune, consolidate)                 │
│  Reglas: max 3 entities/pipeline, dedup obligatorio,           │
│          auto-consolidate a >100 entities                      │
│  Tipos: pattern | error | constraint | decision | tool-gotcha  │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  Capa 2: CLAUDE.md (per-project)                               │
│  Quién escribe: delivery agent                                 │
│  Quién lee: todos los agentes                                  │
│  Secciones: Architecture Decisions, Patterns & Conventions,    │
│             Known Constraints, Testing Conventions              │
│  Reglas: max ~20 entries/sección, consolidar a >15             │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  Capa 3: docs/knowledge.md (per-project)                       │
│  Quién escribe: delivery agent                                 │
│  Quién lee: agentes                                            │
│  Formato: bullets planos [decision], [patrón], [stack]         │
│  Reglas: max ~30 entries                                       │
└────────────────────────────────────────────────────────────────┘
```

---

## Context Efficiency

| Mecanismo | Qué hace |
|-----------|----------|
| **Return Protocol** | Agentes devuelven status block compacto. Orchestrator NO re-lee session-docs en happy path |
| **Phase Checkpointing** | `00-state.md` actualizado antes de cada fase con phase, iteration, hot context, recovery |
| **Hot Context** | Insights cross-cutting descubiertos durante el pipeline, pasados a cada agente |
| **Lazy Reading** | Orchestrator solo lee session-docs en paths de error |
| **Recovery** | Tras auto-compact: leer `00-state.md` → seguir Recovery Instructions |
| **Execution Log** | `00-execution-log.md` — todos los agentes append start/end con timestamp |

---

## Comunicación

### Orchestrator → Usuario (en cada transición de fase)

```
✓ Phase {N}/{total} — {Phase Name} — completed
  Agent: {agent} | Output: {session-doc file}
  {1-line summary}
→ Next: Phase {N+1} — {what happens next}
```

### Orchestrator → Agentes (en cada invocación)

- Feature name
- Task type y scope
- Summary del agente previo (del status block, NO del session-doc)
- Hot Context items relevantes
- Qué se espera del agente
- Si iterando: qué falló y qué necesita cambiar

---

## Principios de Diseño

- **Orchestrator es el hub** — nunca invocar agentes directamente
- **Spec-Driven Development (SDD)** — toda issue lleva User Story + AC Given/When/Then + Scope
- **Iteración mandatoria** — verify falla → arreglar → re-verify (nunca skip, max 3)
- **Context efficiency** — status blocks compactos, lazy reading, phase checkpointing
- **Graceful degradation** — si context7, Memory MCP, o `gh` no están disponibles, continuar sin ellos
- **Security gate** — Critical/High bloquean, Medium/Low/Info son warnings
- **Feature branches** — delivery siempre crea branch, nunca commitea a main
- **Dedup en Knowledge Graph** — search_nodes antes de create_entities, siempre

---

## Instalación

Los agentes y skills se despliegan en dos ubicaciones:

```
# Agentes → ~/.claude/agents/
# Skills  → ~/.claude/commands/ (global) + .claude/commands/ (por proyecto)
# Excalidraw skill → ~/.claude/skills/excalidraw-diagram/ + .claude/skills/excalidraw-diagram/
```

Para validar que todo está sincronizado: `/lint`
