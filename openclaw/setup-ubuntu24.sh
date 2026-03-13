#!/bin/bash
set -e

# Node ya instalado por fnm, buscar path
FNM_VER=$(ls /usr/local/lib/fnm/node-versions/ | sort -V | tail -1)
NODE_BIN="/usr/local/lib/fnm/node-versions/${FNM_VER}/installation/bin"
export PATH=$NODE_BIN:$PATH

echo "Node: $(node --version)"
echo "npm: $(npm --version)"

# Instalar OpenClaw + Claude Code
npm install -g openclaw @anthropic-ai/claude-code 2>&1 | tail -5

# Instalar tmux
apt-get install -y tmux 2>&1 | tail -1

# Configurar .bashrc del usuario valian
BASHRC=/home/valian/.bashrc
grep -q "fnm/node-versions" $BASHRC 2>/dev/null || echo "export PATH=${NODE_BIN}:\$PATH" >> $BASHRC
grep -q "cd /mnt/c/Users/mario" $BASHRC 2>/dev/null || echo "cd /mnt/c/Users/mario" >> $BASHRC

echo "=== Todo listo ==="
node --version
openclaw --version 2>/dev/null || echo "openclaw ok"
claude --version 2>/dev/null || echo "claude ok"
tmux -V
