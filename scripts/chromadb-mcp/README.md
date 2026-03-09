# ChromaDB Knowledge Graph MCP Server

Servidor MCP (Model Context Protocol) que reemplaza `@modelcontextprotocol/server-memory` usando ChromaDB como backend. Provee memoria cross-project para Claude Code con busqueda semantica via embeddings locales.

## Arquitectura

```
Claude Code ──stdio──> server.py ──> ChromaDB PersistentClient ──> ~/.claude/chromadb/
                                         │
                                    all-MiniLM-L6-v2 (embeddings locales, ~80MB)
                                         │
                                    2 collections:
                                    ├── entities (knowledge items)
                                    └── relations (links entre entities)
```

- **Embedded mode** — no requiere un servidor ChromaDB separado, usa `PersistentClient` directo a SQLite
- **Embeddings locales** — modelo `all-MiniLM-L6-v2` descargado automaticamente (~80MB), sin API keys
- **Shared DB** — Windows y WSL apuntan a la misma DB (`~/.claude/chromadb/`); retry automático en SQLite locks

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `server.py` | Servidor MCP principal (FastMCP, transport stdio) |
| `pyproject.toml` | Dependencias: `chromadb>=1.0.0`, `mcp>=1.0.0` |
| `migrate_knowledge.py` | Migra `knowledge.json` (Memory MCP viejo) a ChromaDB |
| `viewer/app.py` | Web UI para browsear entities (puerto 8420) |

## Requisitos

- Python >=3.10, <3.14 (ChromaDB no soporta 3.14+)
- `uv` (recomendado) o `pip`

## Instalacion

El `setup.sh` del repo hace todo automaticamente:

```bash
./scripts/setup.sh
```

Manualmente:

```bash
cd ~/.claude/chromadb-mcp
uv sync                      # instala dependencias
uv run python server.py      # inicia el server (stdio, lo invoca Claude Code)
```

## Registro en Claude Code

El setup registra el server como MCP `memory` a nivel user:

```bash
claude mcp add memory --scope user \
  -e CHROMADB_PATH="~/.claude/chromadb" \
  -- /ruta/completa/a/uv run --directory ~/.claude/chromadb-mcp python server.py
```

**Importante:** usar la ruta completa a `uv` (no solo `uv`), porque Claude Code puede no tener `uv` en su PATH al arrancar. El `setup.sh` resuelve la ruta via `find_uv()`.

## API (Tools MCP)

Compatible con la API de `@modelcontextprotocol/server-memory`:

| Tool | Descripcion |
|------|-------------|
| `create_entities` | Crea entities (merge si ya existe) |
| `add_observations` | Agrega observations a entities existentes |
| `delete_observations` | Elimina observations especificas |
| `delete_entities` | Elimina entities y sus relaciones |
| `create_relations` | Crea relaciones entre entities |
| `delete_relations` | Elimina relaciones |
| `search_nodes` | **Busqueda semantica** (vector similarity, no substring) |
| `open_nodes` | Obtiene entities por nombre exacto |
| `read_graph` | Lee el grafo completo (usar con cuidado) |

### Diferencia clave vs Memory MCP

`search_nodes` usa **busqueda semantica** (cosine similarity sobre embeddings) en vez de substring matching. Esto significa que buscar "authentication patterns" encontrara entities sobre "login flow" o "JWT tokens" aunque no contengan la palabra exacta.

## Migracion desde Memory MCP

Si tienes un `knowledge.json` del Memory MCP original:

```bash
cd ~/.claude/chromadb-mcp
uv run python migrate_knowledge.py --source ~/.claude/knowledge.json --db-path ~/.claude/chromadb
```

El script hace merge (no sobreescribe), y renombra el original a `.bak`.

## Viewer (Web UI)

```bash
cd ~/.claude/chromadb-mcp/viewer
uv run python app.py --port 8420
```

Abre `http://localhost:8420` para browsear y buscar entities. Gestionable via `/kg-viewer start|stop|restart`.

## Estructura de datos

### Entity

```json
{
  "name": "nextjs-api-routes-caching",
  "entityType": "pattern",
  "observations": [
    "Next.js API routes need explicit cache-control headers",
    "Use revalidate instead of no-store for ISR compatibility"
  ]
}
```

Tipos: `pattern` | `error` | `constraint` | `decision` | `tool-gotcha`

### Relation

```json
{
  "from": "nextjs-api-routes-caching",
  "to": "nextjs-isr-patterns",
  "relationType": "relates_to"
}
```

## Quien lee y escribe

- **Escritura:** orchestrator al final de pipelines productivos (full, plan, design, research, test, security)
- **Lectura:** orchestrator al inicio de Phase 0a (busqueda semantica por proyecto/tecnologia)
- **Gestion manual:** `/memory` skill (search, list, show, stats, prune, consolidate)
- **Reglas:** max 3 entities por pipeline, dedup obligatorio (`search_nodes` antes de `create_entities`), auto-consolidate a >100 entities

## Troubleshooting

| Problema | Solucion |
|----------|----------|
| MCP falla al reconectar | Verificar que la ruta a `uv` en `.claude.json` es absoluta |
| `database is locked` | Normal si Windows y WSL acceden simultaneamente; el retry automatico lo maneja |
| `Python >=3.14` error | ChromaDB no soporta 3.14+; `uv` auto-descarga 3.13 si es necesario |
| Embeddings lentos la primera vez | Normal, descarga el modelo (~80MB). Despues es instantaneo |
