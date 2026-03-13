#!/bin/bash
# Crear symlinks y config en Ubuntu 24 (corre como root)

WIN_HOME=/mnt/c/Users/mario

# Symlinks igual que en Ubuntu vieja
ln -sfn $WIN_HOME/.aws /root/.aws
ln -sfn $WIN_HOME/.azure /root/.azure
ln -sfn $WIN_HOME/.openclaw /root/.openclaw

# Docker config
mkdir -p /root/.docker
echo '{"credsStore":"desktop.exe"}' > /root/.docker/config.json

# Symlinks para usuario valian también
ln -sfn $WIN_HOME/.aws /home/valian/.aws 2>/dev/null || true
ln -sfn $WIN_HOME/.azure /home/valian/.azure 2>/dev/null || true
ln -sfn $WIN_HOME/.openclaw /home/valian/.openclaw 2>/dev/null || true
mkdir -p /home/valian/.docker
echo '{"credsStore":"desktop.exe"}' > /home/valian/.docker/config.json

echo "=== Symlinks creados ==="
ls -la /root/ | grep -E "openclaw|aws|azure|docker"
