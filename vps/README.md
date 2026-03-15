# VPS Setup — Checklist de instalacion y configuracion

## En el VPS (Ubuntu)

### Seguridad

- [ ] `sudo apt update && sudo apt upgrade -y`
- [ ] `sudo apt install unattended-upgrades -y`
- [ ] Configurar UFW:
  ```bash
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 22/tcp
  sudo ufw enable
  ```
- [ ] Deshabilitar password en SSH (`/etc/ssh/sshd_config`): `PasswordAuthentication no`
- [ ] `sudo systemctl restart sshd`

### Paquetes base

- [ ] `sudo apt install -y git curl wget tmux build-essential`

### Node.js (requerido por Claude Code)

- [ ] `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash`
- [ ] `source ~/.bashrc && nvm install --lts`

### bat y glow (lectura de docs en terminal)

- [ ] `sudo apt install bat -y` + alias: `echo 'alias bat="batcat"' >> ~/.bashrc`
- [ ] `sudo snap install glow`

### Claude Code

- [ ] `npm install -g @anthropic-ai/claude-code`
- [ ] Configurar API key en `~/.bashrc`: `export ANTHROPIC_API_KEY="..."`
- [ ] Verificar: `claude --version`

### OpenClaw

- [ ] Instalar segun docs oficiales del proyecto
- [ ] Configurar credenciales

### code-server (VS Code en navegador)

- [ ] `curl -fsSL https://code-server.dev/install.sh | sh`
- [ ] Configurar `~/.config/code-server/config.yaml`:
  ```yaml
  bind-addr: 127.0.0.1:8080
  auth: password
  password: TU_PASSWORD_SEGURO
  cert: false
  ```
- [ ] `sudo systemctl enable --now code-server@$USER`

### cloudflared (exponer code-server por HTTPS)

- [ ] Instalar cloudflared:
  ```bash
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
  sudo apt update && sudo apt install cloudflared -y
  ```
- [ ] Crear tunnel en dashboard Cloudflare Zero Trust
- [ ] Public Hostname: Type `HTTP`, URL `localhost:8080`, hostname `code.tudominio.com`
- [ ] `sudo cloudflared service install TOKEN`

### Tailscale

- [ ] `curl -fsSL https://tailscale.com/install.sh | sh`
- [ ] `sudo tailscale up`
- [ ] Anotar IP Tailscale (100.x.x.x)

---

## En el PC (Windows)

- [ ] Tailscale instalado
- [ ] VS Code + extension "Remote - SSH"
- [ ] SSH config (`~/.ssh/config`):
  ```
  Host vps
      HostName 100.x.x.x
      User tu-usuario
  ```

---

## En el iPad

- [ ] Tailscale instalado
- [ ] Termius configurado con IP Tailscale del VPS, puerto 22
- [ ] Acceso a code-server desde Safari: `https://code.tudominio.com`
- [ ] GitHub app para revisar PRs

---

## Sesiones tmux (post-instalacion)

- [ ] `tmux new -s claude` — Claude Code corriendo 24/7
- [ ] `tmux new -s openclaw` — OpenClaw corriendo 24/7
