#!/bin/bash
# Migrar variables de entorno y config a Ubuntu 24

BASHRC=/home/valian/.bashrc

# Variables de entorno (API keys)
cat >> $BASHRC << 'ENVVARS'

# API Keys
export GROQ_API_KEY=<GROQ_API_KEY>
ENVVARS

# Aliases útiles
cat >> $BASHRC << 'ALIASES'

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
ALIASES

# git config (si existe en Ubuntu vieja, copiar manualmente)
echo "=== Variables migradas a $BASHRC ==="
grep -E "API_KEY|BASE_URL|alias" $BASHRC | tail -10
