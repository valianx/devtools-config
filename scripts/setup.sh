#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# devtools-config setup
# Instala y configura todo el ambiente de desarrollo AI
# Uso: git clone <repo> && cd devtools-config && ./setup.sh
# =============================================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
AI_DEV="$REPO_DIR/AI development"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
step() { echo -e "\n${GREEN}==>${NC} $1"; }

# =============================================================================
# 1. Verificar prerequisites
# =============================================================================
step "Verificando prerequisites..."

MISSING=()

command -v node  >/dev/null 2>&1 && ok "node $(node -v)"           || MISSING+=("node")
command -v npm   >/dev/null 2>&1 && ok "npm $(npm -v)"             || MISSING+=("npm")
command -v git   >/dev/null 2>&1 && ok "git $(git --version | cut -d' ' -f3)" || MISSING+=("git")

# Python — verificar python o python3
PYTHON=""
if command -v python >/dev/null 2>&1; then
  PYTHON="python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON="python3"
fi

if [ -n "$PYTHON" ]; then
  ok "$PYTHON $($PYTHON --version 2>&1 | cut -d' ' -f2)"
else
  MISSING+=("python")
fi

# uv — opcional pero recomendado
UV=""
if command -v uv >/dev/null 2>&1; then
  UV="uv"
  ok "uv $(uv --version 2>&1 | cut -d' ' -f2)"
else
  # Buscar en rutas comunes de Windows
  for p in "$HOME/AppData/Roaming/Python/Python314/Scripts/uv.exe" \
           "$HOME/AppData/Roaming/Python/Python313/Scripts/uv.exe" \
           "$HOME/AppData/Roaming/Python/Python312/Scripts/uv.exe" \
           "$HOME/.local/bin/uv"; do
    if [ -f "$p" ]; then
      UV="$p"
      ok "uv (found at $p)"
      break
    fi
  done
  if [ -z "$UV" ]; then
    warn "uv no encontrado — excalidraw renderer no se instalará"
  fi
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  fail "Faltan prerequisites: ${MISSING[*]}"
  echo "Instala los componentes faltantes y vuelve a ejecutar el script."
  exit 1
fi

# =============================================================================
# 2. Instalar Claude Code
# =============================================================================
step "Claude Code..."

if command -v claude >/dev/null 2>&1; then
  ok "Claude Code ya instalado ($(claude --version 2>/dev/null || echo 'version unknown'))"
else
  echo "Instalando Claude Code..."
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code instalado"
fi

# =============================================================================
# 3. Crear directorios de Claude
# =============================================================================
step "Preparando directorios..."

mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills/excalidraw-diagram/references"
ok "Directorios creados en $CLAUDE_DIR"

# =============================================================================
# 4. Desplegar agentes
# =============================================================================
step "Desplegando agentes..."

AGENT_COUNT=0
for f in "$AI_DEV/agents/"*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$CLAUDE_DIR/agents/"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done
ok "$AGENT_COUNT agentes → ~/.claude/agents/"

# =============================================================================
# 5. Desplegar skills (commands)
# =============================================================================
step "Desplegando skills..."

SKILL_COUNT=0
for f in "$AI_DEV/skills/"*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$CLAUDE_DIR/commands/"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done
ok "$SKILL_COUNT skills → ~/.claude/commands/"

# =============================================================================
# 6. Desplegar excalidraw skill
# =============================================================================
step "Desplegando excalidraw skill..."

if [ -d "$AI_DEV/skills/excalidraw-diagram" ]; then
  cp -r "$AI_DEV/skills/excalidraw-diagram/"* "$CLAUDE_DIR/skills/excalidraw-diagram/"
  ok "excalidraw-diagram → ~/.claude/skills/excalidraw-diagram/"
else
  warn "excalidraw-diagram no encontrado en el repo"
fi

# =============================================================================
# 7. Instalar dependencias de excalidraw renderer
# =============================================================================
step "Dependencias de excalidraw renderer..."

if [ -n "$UV" ]; then
  RENDER_DIR="$CLAUDE_DIR/skills/excalidraw-diagram/references"
  if [ -f "$RENDER_DIR/pyproject.toml" ]; then
    (cd "$RENDER_DIR" && "$UV" sync 2>&1) && ok "uv sync completado"
    (cd "$RENDER_DIR" && "$UV" run playwright install chromium 2>&1) && ok "playwright chromium instalado"
  else
    warn "pyproject.toml no encontrado en $RENDER_DIR"
  fi
else
  warn "Skipping — uv no disponible. Instalar manualmente:"
  echo "  pip install uv"
  echo "  cd ~/.claude/skills/excalidraw-diagram/references && uv sync && uv run playwright install chromium"
fi

# =============================================================================
# 8. Instalar ChromaDB (para memoria semántica)
# =============================================================================
step "ChromaDB..."

if $PYTHON -c "import chromadb" 2>/dev/null; then
  ok "ChromaDB ya instalado"
else
  echo "Instalando ChromaDB..."
  if [ -n "$UV" ]; then
    "$UV" pip install chromadb 2>&1 && ok "ChromaDB instalado via uv"
  else
    $PYTHON -m pip install chromadb 2>&1 && ok "ChromaDB instalado via pip"
  fi
fi

# =============================================================================
# 9. Configurar MCP servers
# =============================================================================
step "Configurando MCP servers..."

# Memory MCP (knowledge graph actual)
if claude mcp list 2>&1 | grep -q "memory"; then
  ok "Memory MCP ya configurado"
else
  claude mcp add --scope user -e MEMORY_FILE_PATH="$CLAUDE_DIR/knowledge.json" \
    memory -- npx -y @modelcontextprotocol/server-memory 2>&1 \
    && ok "Memory MCP configurado" \
    || warn "No se pudo configurar Memory MCP — configurar manualmente"
fi

# context7 MCP
if claude mcp list 2>&1 | grep -q "context7"; then
  ok "context7 MCP ya configurado"
else
  claude mcp add --scope user \
    context7 -- npx -y @upstash/context7-mcp@latest 2>&1 \
    && ok "context7 MCP configurado" \
    || warn "No se pudo configurar context7 — configurar manualmente"
fi

# =============================================================================
# 10. Resumen
# =============================================================================
step "Setup completado!"

echo ""
echo "  Agentes:    $AGENT_COUNT desplegados en ~/.claude/agents/"
echo "  Skills:     $SKILL_COUNT desplegadas en ~/.claude/commands/"
echo "  Excalidraw: $([ -n "$UV" ] && echo 'instalado' || echo 'pendiente (instalar uv)')"
echo "  ChromaDB:   $($PYTHON -c 'import chromadb; print("v" + chromadb.__version__)' 2>/dev/null || echo 'pendiente')"
echo "  MCP:        Memory + context7"
echo ""
echo "  Para verificar: claude → /lint"
echo ""
