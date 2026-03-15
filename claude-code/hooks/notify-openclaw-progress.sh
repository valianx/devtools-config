#!/bin/bash
# notify-openclaw-progress.sh — Hook para PostToolUse/PreToolUse → OpenClaw
# Solo reenvía si hay un pipeline activo del orchestrator en session-docs/

OPENCLAW_URL="http://localhost:18789/hooks/wake"
OPENCLAW_TOKEN="${OPENCLAW_GATEWAY_TOKEN:?Set OPENCLAW_GATEWAY_TOKEN env var}"

# Leer payload de Claude Code desde stdin
PAYLOAD=$(cat)

# Extraer cwd del payload
CWD=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null)

# Verificar si hay un pipeline activo (session-docs con estado != complete)
ACTIVE_PIPELINE=false
if [ -d "$CWD/session-docs" ]; then
  for state_file in "$CWD"/session-docs/*/00-state.md; do
    [ -f "$state_file" ] || continue
    if ! grep -q "status: complete" "$state_file" 2>/dev/null; then
      ACTIVE_PIPELINE=true
      break
    fi
  done
fi

# Si no hay pipeline activo, salir silenciosamente
if [ "$ACTIVE_PIPELINE" = false ]; then
  exit 0
fi

# Extraer campos del payload
EVENT_TYPE=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('hook_event_name',''))" 2>/dev/null)
TOOL_NAME=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
SESSION_ID=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
PROJECT=$(basename "$CWD")
SESSION_SHORT="${SESSION_ID:0:6}"

# Construir mensaje según el tipo de evento y herramienta
MESSAGE=""

if [ "$EVENT_TYPE" = "Stop" ]; then
  LAST_MSG=$(echo "$PAYLOAD" | python -c "
import json,sys
d=json.load(sys.stdin)
msg=d.get('last_assistant_message','')
print(msg[:300])
" 2>/dev/null)
  MESSAGE="✅ ${PROJECT} [${SESSION_SHORT}] Claude terminó"
  [ -n "$LAST_MSG" ] && MESSAGE="${MESSAGE}
${LAST_MSG}"

elif [ "$EVENT_TYPE" = "PostToolUse" ]; then
  case "$TOOL_NAME" in
    Write|Edit)
      FILE_PATH=$(echo "$PAYLOAD" | python -c "
import json,sys,os
d=json.load(sys.stdin)
fp=d.get('tool_input',{}).get('file_path','')
print(os.path.basename(fp))
" 2>/dev/null)
      MESSAGE="📝 ${PROJECT} [${SESSION_SHORT}] Modificó: ${FILE_PATH}"
      ;;
    Bash)
      COMMAND=$(echo "$PAYLOAD" | python -c "
import json,sys
d=json.load(sys.stdin)
cmd=d.get('tool_input',{}).get('command','')
print(cmd[:80])
" 2>/dev/null)
      EXIT_CODE=$(echo "$PAYLOAD" | python -c "
import json,sys
d=json.load(sys.stdin)
r=d.get('tool_result',{})
print(r.get('exit_code', r.get('exitCode', 0)))
" 2>/dev/null)
      # Solo notificar si falló o es un comando relevante
      if [ "$EXIT_CODE" != "0" ]; then
        MESSAGE="❌ ${PROJECT} [${SESSION_SHORT}] Falló (exit ${EXIT_CODE}): ${COMMAND}"
      elif echo "$COMMAND" | grep -qiE 'test|deploy|push|install|build|npm run|npx jest|pytest'; then
        MESSAGE="⚙️ ${PROJECT} [${SESSION_SHORT}] Ejecutó: ${COMMAND}"
      fi
      ;;
  esac

elif [ "$EVENT_TYPE" = "PreToolUse" ]; then
  if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$PAYLOAD" | python -c "
import json,sys
d=json.load(sys.stdin)
cmd=d.get('tool_input',{}).get('command','')
print(cmd[:80])
" 2>/dev/null)
    # Solo notificar si es un comando peligroso
    if echo "$COMMAND" | grep -qiE 'rm -rf|drop |push --force|reset --hard|--no-verify'; then
      MESSAGE="⚠️ ${PROJECT} [${SESSION_SHORT}] Comando peligroso: ${COMMAND}"
    fi
  fi
fi

# Si no hay mensaje (evento filtrado), salir
[ -z "$MESSAGE" ] && exit 0

# Enviar a OpenClaw
curl -s -X POST "$OPENCLAW_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENCLAW_TOKEN" \
  -d "$(python -c "
import json, sys
print(json.dumps({
  'text': sys.argv[1],
  'mode': 'now'
}))
" "$MESSAGE")" \
  > /dev/null 2>&1

exit 0
