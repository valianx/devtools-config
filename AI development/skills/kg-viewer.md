Manage the Knowledge Graph web viewer. Start or stop the ChromaDB viewer UI. This is a standalone utility — does NOT route through the orchestrator.

Analyze the input: $ARGUMENTS

---

## Actions

### `start` — Start the viewer

1. Check if already running:
   ```bash
   curl -s http://localhost:8420/ >/dev/null 2>&1 && echo "RUNNING" || echo "STOPPED"
   ```
2. If RUNNING → "Knowledge Graph Viewer ya está corriendo en http://localhost:8420"
3. If STOPPED → start it in the background:
   ```bash
   cd ~/.claude/chromadb-mcp/viewer && uv run --directory ~/.claude/chromadb-mcp python viewer/app.py --db-path ~/.claude/chromadb &
   ```
   Wait 2 seconds, verify it started:
   ```bash
   curl -s http://localhost:8420/ >/dev/null 2>&1 && echo "OK" || echo "FAILED"
   ```
4. If OK → "Knowledge Graph Viewer levantado en http://localhost:8420"
5. If FAILED → report the error

### `stop` — Stop the viewer

1. Find and kill the process:
   ```bash
   pkill -f "viewer/app.py" 2>/dev/null || taskkill //F //IM python.exe //FI "WINDOWTITLE eq *app.py*" 2>/dev/null
   ```
2. Verify:
   ```bash
   curl -s http://localhost:8420/ >/dev/null 2>&1 && echo "STILL_RUNNING" || echo "STOPPED"
   ```
3. Report result

### `status` — Check if running

1. ```bash
   curl -s http://localhost:8420/ >/dev/null 2>&1 && echo "RUNNING" || echo "STOPPED"
   ```
2. If RUNNING → "Knowledge Graph Viewer activo en http://localhost:8420"
3. If STOPPED → "Knowledge Graph Viewer no está corriendo. Usa `/kg-viewer start` para levantarlo."

### No args — Show usage

```
Usage: /kg-viewer <action>

Actions:
  start    Levantar el viewer web en http://localhost:8420
  stop     Detener el viewer
  status   Verificar si está corriendo

El viewer muestra todas las entities del Knowledge Graph con búsqueda
semántica, filtros por tipo, y opción de eliminar entries.
```

---

## Important

- Puerto fijo: 8420 (localhost only, no expuesto externamente)
- El viewer abre la misma DB que usa el ChromaDB MCP — los cambios se reflejan en ambos
- Si el viewer no arranca, verificar que `~/.claude/chromadb/` existe y tiene data
