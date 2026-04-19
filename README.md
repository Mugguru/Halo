# Halo

Universal Roblox cheat suite + custom UI library. Brutalist-mono visual style, purple accent, no external dependencies.

## Load it

Paste this into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mugguru/Halo/main/loader.lua"))()
```

Press `` \ `` (backslash) to toggle the window.

## Files

- `loader.lua` — fetches and runs the rest. The one-liner above points here.
- `halo.lua` — UI library. Registers itself at `getgenv().Halo`.
- `suite.lua` — feature consumer. Imports `getgenv().Halo` and builds the cheat tabs.
- `demo.lua` — UI-only visual demo (no game effects). Useful for iterating on the look without touching features.
- `sanity.lua` — pure-Roblox red box test. Use when nothing appears on screen to confirm GUI creation works at all.

## Status

| Tab | Status |
|---|---|
| Movement | Walk speed override, Jump power override, Noclip, Fly (with keybind), Infinite jump |
| Visuals | Stub — ESP / Fullbright / FOV planned |
| Combat | Stub — Aimbot / Triggerbot / Silent aim planned |
| Misc | Stub — Anti-AFK / Config save+load / Panic key planned |
