#!/bin/bash
# notify-openclaw.sh — Hook Stop de Claude Code → OpenClaw (Telegram)

OPENCLAW_URL="http://localhost:18789/hooks/wake"
OPENCLAW_TOKEN="${OPENCLAW_GATEWAY_TOKEN:?Set OPENCLAW_GATEWAY_TOKEN env var}"

# Leer payload de Claude Code desde stdin
PAYLOAD=$(cat)

# Extraer campos directamente del payload (ya vienen en el JSON)
SESSION_ID=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
LAST_MSG=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('last_assistant_message','')[:500])" 2>/dev/null)
CWD=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null)

# Construir mensaje
SESSION_SHORT="${SESSION_ID:0:8}"
PROJECT=$(basename "$CWD")

if [ -n "$LAST_MSG" ]; then
  MESSAGE="🤖 Claude Code terminó
📁 ${PROJECT} (${SESSION_SHORT}...)

${LAST_MSG}"
else
  MESSAGE="🤖 Claude Code terminó
📁 ${PROJECT} (${SESSION_SHORT}...)"
fi

# Enviar a OpenClaw como wake event
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
