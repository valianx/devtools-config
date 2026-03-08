---
name: prompt-crafter
description: Craft high-quality prompts for Claude Code before sending them via tmux. Use when the user wants to do dev work via Claude Code and you need to clarify requirements, scope, and produce a structured prompt ready for the orchestrator.
---

# Prompt Crafter — Val's Claude Code Interface

Skill para preparar prompts de alta calidad antes de enviarlos a Claude Code.
El objetivo es transformar una petición casual del usuario en un prompt estructurado, claro y completo que el orchestrator de Claude Code pueda ejecutar sin ambigüedad.

---

## Cuándo usar este skill

Usar cuando Mario quiera que Claude Code haga algo: implementar, arreglar, investigar, testear, revisar, diseñar, o cualquier tarea de desarrollo. Antes de abrir tmux y enviar cualquier cosa, pasar por este skill.

No usar para tareas que Val puede hacer directamente (buscar info en internet, responder preguntas, leer archivos, etc.).

---

## Flujo completo

### Fase 1 — Entender la petición

Leer lo que pidió Mario. Identificar:
- ¿Qué tipo de tarea es? (implementación, bugfix, investigación, diseño, tests, review, seguridad, diagrama, etc.)
- ¿Qué proyecto/repo está involucrado?
- ¿Hay suficiente contexto para craftar el prompt, o hay ambigüedad importante?

Si la petición es clara y suficientemente específica, se puede ir directo a Fase 3.
Si hay ambigüedad que afecte el resultado, ir a Fase 2.

### Fase 2 — Conversación de clarificación (solo si es necesario)

Hacer preguntas cortas y directas. No más de 3-4 preguntas por ronda. Priorizar por impacto:

**Preguntas clave según tipo de tarea:**

Para **implementación/bugfix:**
- ¿En qué repo/proyecto? ¿Qué ruta o módulo?
- ¿Cuál es el comportamiento esperado vs el actual?
- ¿Hay restricciones técnicas a respetar (tecnología, patrones, compatibilidad)?
- ¿Qué NO debe tocar?

Para **investigación/research:**
- ¿Qué decisión técnica se quiere tomar con esta info?
- ¿Qué opciones ya se descartaron y por qué?
- ¿Hay constraints de licencia, performance, tamaño de bundle?

Para **diseño de arquitectura:**
- ¿Qué problema de negocio resuelve?
- ¿Qué escala/volumen se espera?
- ¿Qué ya existe que se debe respetar o integrar?

Para **tests:**
- ¿Unit, integration, e2e?
- ¿Hay un target de coverage?
- ¿Qué ya tiene tests y qué no?

Para **review de PR:**
- ¿Número de PR o URL?
- ¿Hay foco especial (seguridad, performance, breaking changes)?

Para **cualquier tarea:**
- ¿Hay deadline o urgencia?
- ¿Qué no debe cambiar bajo ningún concepto?

Continuar la conversación hasta tener suficiente claridad. No avanzar a Fase 3 con ambigüedad que afecte el resultado.

### Fase 3 — Elegir el skill de Claude Code

Seleccionar el skill más apropiado según la tarea:

| Skill | Cuándo usarlo |
|-------|---------------|
| `/issue` | Implementar una feature o bugfix completo (pasa por el pipeline completo: spec → diseño → código → tests → delivery) |
| `/plan` | Planificar un conjunto de trabajo sin implementar todavía. Produce issues con AC |
| `/design` | Diseñar arquitectura de un sistema o feature (solo diseño, sin código) |
| `/research` | Investigar tecnologías, librerías, patrones, comparativas |
| `/test` | Escribir o completar tests para código ya existente |
| `/validate` | Validar una implementación contra criterios de aceptación |
| `/define-ac` | Definir criterios de aceptación para una feature antes de implementarla |
| `/security` | Auditoría de seguridad (OWASP, auth, APIs, queries, CORS) |
| `/review-pr` | Revisar un Pull Request (necesita número de PR) |
| `/deliver` | Hacer el delivery de algo ya implementado (branch, commit, versión) |
| `/diagram` | Generar un diagrama Excalidraw de arquitectura, flujo o sistema |
| `/init` | Bootstrap de un repo nuevo en el sistema de agentes |

**Regla general:** para trabajo de implementación completo, siempre preferir `/issue` sobre prompts más simples — el pipeline completo produce mejor resultado.

### Fase 4 — Craftar el prompt

Construir el prompt estructurado. Adaptar el nivel de detalle al skill elegido:

**Template base:**
```
/{skill} {título-corto-de-la-tarea}

## Contexto
{qué existe hoy, cuál es el estado actual}

## Tarea
{qué hay que hacer, explicado claramente}

## Scope
**Incluido:** {qué debe hacer el agente}
**Excluido:** {qué NO debe tocar}

## Criterios de aceptación
- [ ] AC-1: Given {contexto}, When {acción}, Then {resultado esperado}
- [ ] AC-2: ...

## Contexto técnico
- **Repo/path:** {ruta del proyecto}
- **Tecnología:** {stack relevante}
- **Patrones existentes:** {patrones a seguir}
- **Dependencias relevantes:** {libs, servicios, configs}
- **Constraints:** {limitaciones técnicas o de negocio}

## Formato de salida esperado
{qué debe producir el agente al terminar}
```

**Reglas de crafting:**
- El título debe ser accionable (verbo + objeto): "Agregar rate limiting al endpoint /auth/login", no "Rate limiting"
- El contexto siempre en pasado/presente (qué hay hoy), la tarea siempre en infinitivo (qué hacer)
- Los AC siempre en formato Given/When/Then con checkbox. Mínimo 2, máximo 10
- El scope excluido es tan importante como el incluido — siempre poner al menos una línea
- Si Mario mencionó archivos o rutas específicas, incluirlos en Contexto técnico
- No poner información que no se tenga — mejor omitir una sección que inventarla

**Adaptaciones por tipo de tarea:**

Para `/research`: reemplazar AC por "Preguntas a responder" y agregar "Decisión a tomar" al final.

Para `/design`: agregar sección "Restricciones de diseño" y "Alternativas ya descartadas".

Para `/review-pr`: incluir número de PR y foco del review (seguridad, lógica, performance, etc.).

Para `/diagram`: describir qué sistema/flujo representar y qué componentes incluir.

Para `/plan`: incluir sección "Issues esperadas" con una lista preliminar de qué trabajo existe.

### Fase 5 — Mostrar al usuario y pedir aprobación

Mostrar el prompt completo en un bloque de código. Preguntar:

> "¿Así está bien el prompt o quieres ajustar algo antes de enviarlo a Claude Code?"

Esperar respuesta. Si Mario pide cambios, aplicarlos y mostrar el prompt actualizado. No enviar nada sin aprobación explícita.

### Fase 6 — Enviar a Claude Code via tmux

Una vez aprobado:

1. Usar el skill `tmux-wsl` para verificar si ya existe una sesión activa para ese proyecto
2. Si no existe, crear la sesión con el nombre del proyecto (sin espacios, usar guiones bajos)
3. Hacer `read` antes de enviar para confirmar que Claude Code está listo (espera input)
4. Enviar el prompt con `send`
5. Confirmarle a Mario que el prompt fue enviado y en qué sesión tmux está corriendo

**Nombre de sesión:** usar el nombre del repo o proyecto. Ejemplos: `transactions`, `notifications`, `devtools`. Si no se sabe el nombre del proyecto, preguntar antes de crear la sesión.

**Estado de Claude Code listo:** el output debe mostrar el prompt `>` de Claude Code esperando input. Si muestra otra cosa (está ejecutando algo, hay un error), reportarle a Mario antes de enviar.

---

## Reglas generales

- Siempre hablar en español con Mario, tono casual
- Nunca enviar un prompt sin que Mario lo haya aprobado explícitamente
- Si la tarea es muy grande o ambigua, recomendar `/plan` primero en lugar de `/issue`
- Si hay dudas sobre seguridad (auth, secrets, APIs públicas, queries con input de usuario), mencionar que el pipeline incluirá una auditoría de seguridad automáticamente
- El prompt debe ser autosuficiente: Claude Code no tiene contexto de la conversación de Telegram, todo lo relevante debe estar en el prompt
- Preferir prompts más detallados sobre prompts cortos — Claude Code rinde mejor con contexto completo

---

## Ejemplo completo

**Mario dice:** "oye Val tengo un bug, el login no funciona cuando el email tiene mayúsculas"

**Val responde** (sin preguntas, es suficientemente claro):
> Listo, armé el prompt:

```
/issue Fix: login falla con emails que tienen mayúsculas

## Contexto
El endpoint de autenticación rechaza credenciales válidas cuando el email
del usuario contiene letras mayúsculas (ej: Mario@empresa.com vs mario@empresa.com).

## Tarea
Normalizar el email a minúsculas antes de la comparación en el flujo de autenticación.

## Scope
**Incluido:** normalización del email en login, validación en registro si aplica
**Excluido:** cambios en el schema de BD, migración de datos existentes, otros endpoints

## Criterios de aceptación
- [ ] AC-1: Given un usuario registrado como mario@empresa.com, When hace login con Mario@empresa.com, Then el login es exitoso
- [ ] AC-2: Given el endpoint POST /auth/login, When recibe email con mayúsculas, Then normaliza a minúsculas antes de buscar en BD
- [ ] AC-3: Given el flujo completo, When el email se normaliza, Then el token JWT se emite correctamente

## Contexto técnico
- **Repo/path:** /home/mario/projects/transactions
- **Tecnología:** NestJS
- **Patrones existentes:** seguir el patrón de validación existente en el módulo auth
- **Constraints:** no romper sesiones activas existentes
```

> ¿Así está bien o quieres cambiar algo?
