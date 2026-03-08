# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## Exec Security

- El archivo `~/.openclaw/exec-approvals.json` controla el allowlist de comandos
- `"security": "full"` en ese archivo = sin restricciones, sin pedir aprobación
- Si vuelve a bloquearse, editar ese archivo directamente

## Entorno

- OS: WSL2 en Windows (Mario-PC)
- `/root/.openclaw/` → symlink a `C:\Users\mario\.openclaw\`
- Un solo archivo sincronizado entre WSL y Windows
- Cambios en config se reflejan inmediatamente en ambos lados

## Claude Code en tmux (Zippy)

Para sesiones de proyectos Zippy, lanzar con:
```bash
claude --dangerously-skip-permissions
```
Para sesiones con código externo o PRs de terceros, usar `claude` normal (con permisos).

## Comandos Windows desde WSL

### Suspender PC
```bash
rundll32.exe powrprof.dll,SetSuspendState 0,1,0
```
Cuando Mario diga "suspende el PC" (o similar), ejecutar este comando.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.
