#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# devtools-config setup — centralizado
# Detecta el entorno y configura Windows + WSL cuando aplica
# Uso: git clone <repo> && cd devtools-config && ./scripts/setup.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AI_DEV="$REPO_DIR/claude-code"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }
step() { echo -e "\n${CYAN}==>${NC} $1"; }

# =============================================================================
# Detectar entorno
# =============================================================================
detect_env() {
  IS_WINDOWS=false
  IS_WSL=false
  IS_LINUX=false
  IS_MAC=false
  HAS_WSL=false

  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
    IS_WINDOWS=true
    # Verificar si WSL está disponible
    if command -v wsl.exe >/dev/null 2>&1 || command -v wsl >/dev/null 2>&1; then
      # Verificar que hay una distro instalada
      if wsl.exe --list --quiet 2>/dev/null | head -1 | grep -q .; then
        HAS_WSL=true
      elif wsl --list --quiet 2>/dev/null | head -1 | grep -q .; then
        HAS_WSL=true
      fi
    fi
  elif grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
    IS_WSL=true
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MAC=true
  else
    IS_LINUX=true
  fi
}

detect_env

echo ""
echo "========================================="
echo "  devtools-config setup"
echo "========================================="

if $IS_WINDOWS; then
  echo "  Entorno: Windows (Git Bash)"
  $HAS_WSL && echo "  WSL:     detectado — se configurará también"
elif $IS_WSL; then
  echo "  Entorno: WSL"
elif $IS_MAC; then
  echo "  Entorno: macOS"
else
  echo "  Entorno: Linux"
fi

# =============================================================================
# Funciones de setup reutilizables
# =============================================================================

find_python() {
  if command -v python >/dev/null 2>&1; then
    echo "python"
  elif command -v python3 >/dev/null 2>&1; then
    echo "python3"
  else
    echo ""
  fi
}

find_uv() {
  if command -v uv >/dev/null 2>&1; then
    echo "uv"
    return
  fi
  # Rutas comunes en Windows
  for p in "$HOME/AppData/Roaming/Python/Python314/Scripts/uv.exe" \
           "$HOME/AppData/Roaming/Python/Python313/Scripts/uv.exe" \
           "$HOME/AppData/Roaming/Python/Python312/Scripts/uv.exe" \
           "$HOME/.local/bin/uv" \
           "$HOME/.cargo/bin/uv"; do
    if [ -f "$p" ]; then
      echo "$p"
      return
    fi
  done
  echo ""
}

check_prerequisites() {
  local env_label="$1"
  local missing=()

  step "[$env_label] Verificando prerequisites..."

  command -v node  >/dev/null 2>&1 && ok "node $(node -v)"           || missing+=("node")
  command -v npm   >/dev/null 2>&1 && ok "npm $(npm -v)"             || missing+=("npm")
  command -v git   >/dev/null 2>&1 && ok "git $(git --version | cut -d' ' -f3)" || missing+=("git")

  PYTHON="$(find_python)"
  if [ -n "$PYTHON" ]; then
    ok "$PYTHON $($PYTHON --version 2>&1 | cut -d' ' -f2)"
  else
    missing+=("python")
  fi

  UV="$(find_uv)"
  if [ -n "$UV" ]; then
    ok "uv encontrado"
  else
    warn "uv no encontrado — excalidraw renderer no se instalará"
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    fail "Faltan prerequisites: ${missing[*]}"
    return 1
  fi
  return 0
}

install_claude_code() {
  local env_label="$1"
  step "[$env_label] Claude Code..."

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code ya instalado"
  else
    echo "  Instalando Claude Code..."
    npm install -g @anthropic-ai/claude-code 2>&1 | tail -1
    ok "Claude Code instalado"
  fi
}

deploy_files() {
  local env_label="$1"
  local claude_dir="$2"
  local source_dir="$3"

  # Crear directorios
  step "[$env_label] Preparando directorios..."
  mkdir -p "$claude_dir/agents"
  mkdir -p "$claude_dir/commands"
  mkdir -p "$claude_dir/skills/excalidraw-diagram/references"
  ok "Directorios en $claude_dir"

  # Agentes
  step "[$env_label] Desplegando agentes..."
  local agent_count=0
  for f in "$source_dir/agents/"*.md; do
    [ -f "$f" ] || continue
    cp "$f" "$claude_dir/agents/"
    agent_count=$((agent_count + 1))
  done
  ok "$agent_count agentes → $claude_dir/agents/"

  # Skills
  step "[$env_label] Desplegando skills..."
  local skill_count=0
  for f in "$source_dir/skills/"*.md; do
    [ -f "$f" ] || continue
    cp "$f" "$claude_dir/commands/"
    skill_count=$((skill_count + 1))
  done
  ok "$skill_count skills → $claude_dir/commands/"

  # Excalidraw skill
  step "[$env_label] Desplegando excalidraw skill..."
  if [ -d "$source_dir/skills/excalidraw-diagram" ]; then
    cp -r "$source_dir/skills/excalidraw-diagram/"* "$claude_dir/skills/excalidraw-diagram/"
    ok "excalidraw-diagram desplegado"
  else
    warn "excalidraw-diagram no encontrado"
  fi

  echo "$agent_count:$skill_count"
}

install_python_deps() {
  local env_label="$1"
  local claude_dir="$2"

  # Excalidraw renderer
  step "[$env_label] Dependencias de excalidraw renderer..."
  if [ -n "$UV" ]; then
    local render_dir="$claude_dir/skills/excalidraw-diagram/references"
    if [ -f "$render_dir/pyproject.toml" ]; then
      (cd "$render_dir" && "$UV" sync 2>&1 | tail -1) && ok "uv sync completado"
      (cd "$render_dir" && "$UV" run playwright install chromium 2>&1 | tail -3) && ok "playwright chromium instalado"
    else
      warn "pyproject.toml no encontrado en $render_dir"
    fi
  else
    warn "Skipping — uv no disponible"
  fi

  # ChromaDB ya se instala como parte de install_chromadb_mcp()
}

install_chromadb_mcp() {
  local env_label="$1"
  local claude_dir="$2"
  local source_dir="$3"

  step "[$env_label] ChromaDB MCP server..."
  local mcp_src="$source_dir/chromadb-mcp"
  local mcp_dest="$claude_dir/chromadb-mcp"

  if [ -d "$mcp_src" ]; then
    mkdir -p "$mcp_dest"
    cp "$mcp_src/server.py" "$mcp_dest/"
    cp "$mcp_src/pyproject.toml" "$mcp_dest/"
    cp "$mcp_src/migrate_knowledge.py" "$mcp_dest/"
    cp "$mcp_src/manage-server.sh" "$mcp_dest/" && chmod +x "$mcp_dest/manage-server.sh"
    mkdir -p "$mcp_dest/viewer"
    cp "$mcp_src/viewer/app.py" "$mcp_dest/viewer/"

    # Install dependencies
    if [ -n "$UV" ]; then
      (cd "$mcp_dest" && "$UV" sync 2>&1 | tail -1) && ok "Dependencias instaladas via uv"
    elif [ -n "$PYTHON" ]; then
      (cd "$mcp_dest" && $PYTHON -m pip install chromadb "mcp>=1.0.0" uvicorn 2>&1 | tail -1) && ok "Dependencias instaladas via pip"
    else
      warn "Python no disponible — ChromaDB MCP no se instalará"
      return
    fi
    ok "ChromaDB MCP desplegado en $mcp_dest"
  else
    warn "chromadb-mcp source no encontrado en $mcp_src"
  fi
}

configure_mcp() {
  local env_label="$1"
  local claude_dir="$2"

  step "[$env_label] Configurando MCP servers..."

  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code no encontrado — MCP servers no se configurarán"
    return
  fi

  # ChromaDB MCP — SSE mode (single server on Windows, accessible from WSL)
  # Remove old registrations (legacy stdio)
  claude mcp remove chromadb-knowledge --scope user 2>&1 || true
  claude mcp remove chromadb-knowledge --scope project 2>&1 || true

  local mcp_server="$claude_dir/chromadb-mcp/server.py"
  local manage_script="$claude_dir/chromadb-mcp/manage-server.sh"
  local sse_port="${CHROMADB_PORT:-8421}"
  local sse_url="http://localhost:$sse_port/sse"

  if [ -f "$mcp_server" ]; then
    # Start SSE server (binds 0.0.0.0 so WSL can reach it)
    if [ -f "$manage_script" ]; then
      export CHROMADB_PATH="$claude_dir/chromadb"
      export CHROMADB_MCP_DIR="$claude_dir/chromadb-mcp"
      export CHROMADB_HOST="0.0.0.0"
      bash "$manage_script" restart 2>&1 | while read -r line; do echo "    $line"; done
      ok "ChromaDB MCP SSE server en $sse_url"
    fi

    # Register as SSE
    claude mcp remove memory --scope user 2>&1 || true
    claude mcp add --transport sse --scope user memory "$sse_url" 2>&1 \
      && ok "ChromaDB MCP registrado como 'memory' (SSE: $sse_url)" \
      || warn "No se pudo registrar ChromaDB MCP"
  else
    warn "ChromaDB MCP server no encontrado — saltando configuración"
  fi

  # context7 MCP
  if claude mcp list 2>&1 | grep -q "context7"; then
    ok "context7 MCP ya configurado"
  else
    claude mcp add --scope user \
      context7 -- npx -y @upstash/context7-mcp@latest 2>&1 \
      && ok "context7 MCP configurado" \
      || warn "No se pudo configurar context7"
  fi

  # Migrate knowledge.json if it exists (merge into ChromaDB, then backup)
  local knowledge_file="$claude_dir/knowledge.json"
  local chromadb_dir="$claude_dir/chromadb"
  if [ -f "$knowledge_file" ]; then
    step "[$env_label] Migrando knowledge.json a ChromaDB (merge)..."
    local migrate_script_py="$claude_dir/chromadb-mcp/migrate_knowledge.py"
    if [ -f "$migrate_script_py" ]; then
      if [ -n "$UV" ]; then
        (cd "$claude_dir/chromadb-mcp" && "$UV" run python migrate_knowledge.py \
          --source "$knowledge_file" --db-path "$chromadb_dir" 2>&1) \
          && ok "Migración completada (knowledge.json → .bak)" \
          || warn "Migración falló — knowledge.json conservado"
      elif [ -n "$PYTHON" ]; then
        $PYTHON "$migrate_script_py" --source "$knowledge_file" --db-path "$chromadb_dir" 2>&1 \
          && ok "Migración completada (knowledge.json → .bak)" \
          || warn "Migración falló — knowledge.json conservado"
      fi
    fi
  fi
}

# =============================================================================
# Setup del entorno actual
# =============================================================================
ENV_LABEL="local"
$IS_WINDOWS && ENV_LABEL="Windows"
$IS_WSL && ENV_LABEL="WSL"
$IS_MAC && ENV_LABEL="macOS"
$IS_LINUX && ENV_LABEL="Linux"

PYTHON=""
UV=""

if check_prerequisites "$ENV_LABEL"; then
  install_claude_code "$ENV_LABEL"
  COUNTS=$(deploy_files "$ENV_LABEL" "$HOME/.claude" "$AI_DEV")
  install_chromadb_mcp "$ENV_LABEL" "$HOME/.claude" "$REPO_DIR/scripts"
  install_python_deps "$ENV_LABEL" "$HOME/.claude"
  configure_mcp "$ENV_LABEL" "$HOME/.claude"
  LOCAL_AGENTS=$(echo "$COUNTS" | cut -d: -f1)
  LOCAL_SKILLS=$(echo "$COUNTS" | cut -d: -f2)
else
  fail "Setup del entorno local abortado por prerequisites faltantes"
  exit 1
fi

# =============================================================================
# Setup de WSL (solo si estamos en Windows y WSL está disponible)
# =============================================================================
WSL_DONE=false

if $IS_WINDOWS && $HAS_WSL; then
  echo ""
  echo "========================================="
  echo "  Configurando WSL..."
  echo "========================================="

  # Convertir ruta del repo a formato accesible desde WSL
  # C:\Users\mario\projects\... → /mnt/c/Users/mario/projects/...
  WSL_REPO_DIR=$(echo "$REPO_DIR" | sed 's|^/\([a-zA-Z]\)/|/mnt/\L\1/|' | sed 's|\\|/|g')
  # Ruta al .claude de Windows desde WSL (para compartir ChromaDB)
  WSL_WIN_CLAUDE=$(echo "$HOME/.claude" | sed 's|^/\([a-zA-Z]\)/|/mnt/\L\1/|' | sed 's|\\|/|g')

  # Script que se ejecuta dentro de WSL
  WSL_SCRIPT='
set -euo pipefail

REPO_DIR="'"$WSL_REPO_DIR"'"
AI_DEV="$REPO_DIR/claude-code"
CLAUDE_DIR="$HOME/.claude"
# ChromaDB compartida: apunta al directorio de Windows para tener una sola DB
WIN_CHROMADB_PATH="'"$WSL_WIN_CLAUDE"'/chromadb"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }
step() { echo -e "\n${CYAN}==>${NC} $1"; }

# Prerequisites
step "[WSL] Verificando prerequisites..."
MISSING=()
command -v node  >/dev/null 2>&1 && ok "node $(node -v)"           || MISSING+=("node")
command -v npm   >/dev/null 2>&1 && ok "npm $(npm -v)"             || MISSING+=("npm")
command -v git   >/dev/null 2>&1 && ok "git $(git --version | cut -d" " -f3)" || MISSING+=("git")

PYTHON=""
command -v python3 >/dev/null 2>&1 && PYTHON="python3" || command -v python >/dev/null 2>&1 && PYTHON="python"
[ -n "$PYTHON" ] && ok "$PYTHON $($PYTHON --version 2>&1 | cut -d" " -f2)" || MISSING+=("python")

UV=""
command -v uv >/dev/null 2>&1 && UV="uv" && ok "uv encontrado"
[ -z "$UV" ] && [ -f "$HOME/.local/bin/uv" ] && UV="$HOME/.local/bin/uv" && ok "uv encontrado"
[ -z "$UV" ] && [ -f "$HOME/.cargo/bin/uv" ] && UV="$HOME/.cargo/bin/uv" && ok "uv encontrado"
[ -z "$UV" ] && warn "uv no encontrado"

if [ ${#MISSING[@]} -gt 0 ]; then
  fail "Faltan prerequisites en WSL: ${MISSING[*]}"
  echo "  Instala los componentes faltantes en WSL y vuelve a ejecutar."
  exit 1
fi

# Claude Code
step "[WSL] Claude Code..."
if command -v claude >/dev/null 2>&1; then
  ok "Claude Code ya instalado"
else
  npm install -g @anthropic-ai/claude-code 2>&1 | tail -1
  ok "Claude Code instalado"
fi

# Directorios
step "[WSL] Preparando directorios..."
mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/skills/excalidraw-diagram/references"
ok "Directorios creados"

# Agentes
step "[WSL] Desplegando agentes..."
AGENT_COUNT=0
for f in "$AI_DEV/agents/"*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$CLAUDE_DIR/agents/"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done
ok "$AGENT_COUNT agentes desplegados"

# Skills
step "[WSL] Desplegando skills..."
SKILL_COUNT=0
for f in "$AI_DEV/skills/"*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$CLAUDE_DIR/commands/"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done
ok "$SKILL_COUNT skills desplegadas"

# Excalidraw skill
step "[WSL] Desplegando excalidraw skill..."
if [ -d "$AI_DEV/skills/excalidraw-diagram" ]; then
  cp -r "$AI_DEV/skills/excalidraw-diagram/"* "$CLAUDE_DIR/skills/excalidraw-diagram/"
  ok "excalidraw-diagram desplegado"
fi

# Excalidraw renderer
step "[WSL] Dependencias de excalidraw renderer..."
if [ -n "$UV" ]; then
  RENDER_DIR="$CLAUDE_DIR/skills/excalidraw-diagram/references"
  if [ -f "$RENDER_DIR/pyproject.toml" ]; then
    (cd "$RENDER_DIR" && "$UV" sync 2>&1 | tail -1) && ok "uv sync completado"
    (cd "$RENDER_DIR" && "$UV" run playwright install chromium 2>&1 | tail -3) && ok "playwright chromium instalado"
  fi
else
  warn "Skipping renderer — uv no disponible en WSL"
fi

# ChromaDB MCP — WSL connects to Windows-side SSE server (no local server needed)
step "[WSL] Configurando ChromaDB MCP (SSE client)..."
SSE_PORT="${CHROMADB_PORT:-8421}"
# WSL2 reaches Windows host via default gateway IP
WIN_HOST_IP=$(ip route show default 2>/dev/null | head -1 | cut -d" " -f3)
SSE_URL="http://${WIN_HOST_IP:-172.27.224.1}:$SSE_PORT/sse"

if command -v claude >/dev/null 2>&1; then
  # Remove old registrations (legacy stdio)
  claude mcp remove chromadb-knowledge --scope user 2>&1 || true
  claude mcp remove memory --scope user 2>&1 || true

  # Register as SSE — connects to the Windows-side server via gateway IP
  claude mcp add --transport sse --scope user memory "$SSE_URL" 2>&1 \
    && ok "ChromaDB MCP registrado como 'memory' (SSE: $SSE_URL)" \
    || warn "No se pudo registrar ChromaDB MCP"

  # context7 MCP
  claude mcp list 2>&1 | grep -q "context7" \
    && ok "context7 MCP ya configurado" \
    || (claude mcp add --scope user \
        context7 -- npx -y @upstash/context7-mcp@latest 2>&1 \
        && ok "context7 MCP configurado" || warn "No se pudo configurar context7")
else
  warn "Claude Code no encontrado en WSL — MCP no configurado"
fi

echo ""
echo "  WSL setup completado"
'

  wsl bash -c "$WSL_SCRIPT" && WSL_DONE=true || warn "WSL setup falló — verificar manualmente"

  # ===========================================================================
  # WSL auto-start: Task Scheduler + .wslconfig (mirrored networking)
  # ===========================================================================
  step "[Windows] Configurando auto-start de WSL..."

  # .wslconfig — mirrored networking para que localhost:18789 sea accesible desde Windows
  WSLCONFIG="$USERPROFILE/.wslconfig"
  if [ -z "$USERPROFILE" ]; then
    WSLCONFIG="$HOME/.wslconfig"
  fi
  if [ ! -f "$WSLCONFIG" ] || ! grep -q "networkingMode=mirrored" "$WSLCONFIG" 2>/dev/null; then
    cat > "$WSLCONFIG" <<'WSLCFG'
[wsl2]
networkingMode=mirrored
WSLCFG
    ok ".wslconfig con networkingMode=mirrored"
  else
    ok ".wslconfig ya configurado"
  fi

  # Copiar start-hidden.vbs a ~/.openclaw/
  step "[Windows] Desplegando start-hidden.vbs..."
  VBS_SRC="$REPO_DIR/openclaw/start-hidden.vbs"
  VBS_DEST="$HOME/.openclaw/start-hidden.vbs"
  if [ -f "$VBS_SRC" ]; then
    mkdir -p "$HOME/.openclaw"
    cp "$VBS_SRC" "$VBS_DEST"
    ok "start-hidden.vbs → $VBS_DEST"
  else
    warn "start-hidden.vbs no encontrado en $VBS_SRC"
  fi

  # Task Scheduler — lanza WSL via VBS (sin consola visible)
  TASK_NAME="OpenClaw Gateway"
  TASK_EXISTS=false
  schtasks //query //tn "$TASK_NAME" //fo LIST >/dev/null 2>&1 && TASK_EXISTS=true

  # Ruta de Windows al VBS
  VBS_WIN_PATH=$(echo "$VBS_DEST" | sed 's|^/\([a-zA-Z]\)/|\1:\\|' | sed 's|/|\\|g')

  if $TASK_EXISTS; then
    powershell.exe -NoProfile -Command "
      \$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '\"$VBS_WIN_PATH\"'
      Set-ScheduledTask -TaskName '$TASK_NAME' -Action \$action | Out-Null
    " 2>&1 && ok "Task '$TASK_NAME' actualizada (VBS hidden)" || warn "No se pudo actualizar la tarea (requiere admin?)"
  else
    powershell.exe -NoProfile -Command "
      \$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '\"$VBS_WIN_PATH\"'
      \$trigger = New-ScheduledTaskTrigger -AtLogOn -User '$USERNAME'
      \$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
      Register-ScheduledTask -TaskName '$TASK_NAME' -Action \$action -Trigger \$trigger -Settings \$settings -Description 'Mantiene WSL vivo para OpenClaw gateway (systemd)' | Out-Null
    " 2>&1 && ok "Task '$TASK_NAME' creada (VBS hidden)" || warn "No se pudo crear la tarea (requiere admin?)"
  fi

  # Desplegar hooks de Claude Code
  step "[Windows] Desplegando hooks de Claude Code..."
  HOOKS_SRC="$REPO_DIR/claude-code/hooks"
  HOOKS_DEST="$HOME/.claude/hooks"
  if [ -d "$HOOKS_SRC" ]; then
    mkdir -p "$HOOKS_DEST"
    cp "$HOOKS_SRC"/*.sh "$HOOKS_DEST/"
    ok "Hooks desplegados → $HOOKS_DEST"
  fi
fi

# =============================================================================
# Resumen final
# =============================================================================
echo ""
echo "========================================="
echo "  Setup completado"
echo "========================================="
echo ""
echo "  $ENV_LABEL:"
echo "    Agentes:    ${LOCAL_AGENTS:-0} → ~/.claude/agents/"
echo "    Skills:     ${LOCAL_SKILLS:-0} → ~/.claude/commands/"
echo "    Excalidraw: $([ -n "$UV" ] && echo 'instalado' || echo 'pendiente')"
echo "    ChromaDB MCP: $([ -f "$HOME/.claude/chromadb-mcp/server.py" ] && echo 'instalado' || echo 'pendiente')"
echo "    MCP:        ChromaDB + context7"

if $IS_WINDOWS && $HAS_WSL; then
  echo ""
  if $WSL_DONE; then
    echo "  WSL:"
    echo "    Mismo contenido desplegado en la home de WSL"
    echo "    ChromaDB: compartida con Windows (misma DB)"
    echo "    Claude Code + MCP configurados independientemente"
  else
    echo "  WSL: no configurado (verificar manualmente)"
  fi
fi

echo ""
echo "  Verificar: claude → /lint"
echo ""
