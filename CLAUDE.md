# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

FiveM resource for a trucker job. Stack: Lua (client/server) + Vue 3 NUI

## Multi-Framework Support

Supports **qbox**, **qb-core**, and **esx**. Active framework set in `config/shared.lua`. Framework-specific code lives in adapter files - never call framework globals directly. Always go through the adapter so the rest of the codebase stays framework-agnostic.

## Structure

```
config/          # shared, client, server config (Framework key lives in shared.lua)
framework/       # framework adapters
  shared.lua     # dispatcher — requires framework/<active>/shared.lua based on config Framework
  client.lua     # dispatcher — requires framework/<active>/client.lua
  server.lua     # dispatcher — requires framework/<active>/server.lua
  qbox/          # qbox provider — shared.lua, client.lua, server.lua
  qb-core/       # qb-core provider — shared.lua, client.lua, server.lua
  esx/           # esx provider — shared.lua, client.lua, server.lua
shared/          # utilities loaded on both sides (debug module)
client/
  modules/       # self-contained logic modules (one concern per file)
  nui/           # NUI message + callback handlers
server/
  modules/       # self-contained logic modules
  database.lua   # DB cache loading
web/src/         # Vue 3 NUI frontend
```

Modules (`client/modules/`, `server/modules/`) are the primary place for feature logic. Each module is a single concern (e.g. job progression, vehicle spawning). `client/main.lua` and `server/main.lua` are entry points only.

## Web UI

Commands run from `web/`:

```bash
npm run build      # typecheck + build → ../html/
npm run typecheck  # type check only
```

## NUI ↔ Lua Communication

**Lua → NUI:** `SendNUIMessage({ action = "...", data = {...} })` — handled in the single `switch` block in `web/src/App.vue`. All message handling must stay there.

**NUI → Lua:** `nuiCallbackAsync("name", data)` in Vue → `RegisterNUICallback('name', cb)` in `client/nui/nui_callbacks.lua`.

## Key Dependencies that are always available

- `ox_lib` — utilities, `lib.callback`
- `oxmysql` — database (`MySQL.*`)
