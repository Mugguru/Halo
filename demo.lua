-- Halo UI Library — visual demo
--
-- SETUP (no file copying needed):
-- 1) Paste halo.lua into Potassium and RUN IT ONCE. It registers itself at _G.Halo.
-- 2) Then paste THIS script (demo.lua) and run it. Window appears.
-- 3) Toggle the window with `\` (backslash) key.
--
-- The point of this demo is purely to judge the LOOK of the library before
-- features are bolted on. Test: drag the window, hover tabs, switch tabs,
-- toggle the toggles, drag the sliders, click buttons, rebind the keybind.

local genv = (getgenv and getgenv()) or _G
local library = genv.Halo or _G.Halo
if not library then
    -- Fallback to readfile if the global isn't set
    local ok, content = pcall(readfile, "Halo/halo.lua")
    if ok and content then
        library = loadstring(content)()
    else
        error("[Halo Demo] Library not loaded. Paste halo.lua and run it first (it sets getgenv().Halo).")
    end
end
print("[Halo Demo] Library found, building window...")

local window = library:Window({
    Name = "Halo",
    ToggleKey = Enum.KeyCode.BackSlash,
})

----------- TAB 1: Movement (showcase of components) -----------

local tabMove = window:Tab({Name = "Movement", Icon = "→"})

local secSpeed = tabMove:Section({Name = "Speed"})
secSpeed:Toggle({
    Name = "Walk speed override",
    Default = false,
    Callback = function(v) print("[Demo] WalkSpeed override:", v) end,
})
secSpeed:Slider({
    Name = "Walk speed",
    Default = 16, Min = 16, Max = 200,
    Callback = function(v) print("[Demo] WalkSpeed:", v) end,
})
secSpeed:Toggle({
    Name = "Jump power override",
    Default = false,
    Callback = function(v) print("[Demo] JumpPower override:", v) end,
})
secSpeed:Slider({
    Name = "Jump power",
    Default = 50, Min = 50, Max = 300,
    Callback = function(v) print("[Demo] JumpPower:", v) end,
})

local secNoclip = tabMove:Section({Name = "Noclip & Fly"})
secNoclip:Toggle({
    Name = "Noclip",
    Default = false,
    Callback = function(v) print("[Demo] Noclip:", v) end,
})
secNoclip:Toggle({
    Name = "Fly",
    Default = false,
    Callback = function(v) print("[Demo] Fly:", v) end,
})
secNoclip:Slider({
    Name = "Fly speed",
    Default = 50, Min = 10, Max = 300,
    Callback = function(v) print("[Demo] FlySpeed:", v) end,
})
secNoclip:Keybind({
    Name = "Toggle fly",
    Default = Enum.KeyCode.F,
    Callback = function(k) print("[Demo] Fly key pressed:", k.Name) end,
})

----------- TAB 2: Combat -----------

local tabCombat = window:Tab({Name = "Combat", Icon = "⊕"})

local secAimbot = tabCombat:Section({Name = "Aimbot"})
secAimbot:Toggle({
    Name = "Enabled",
    Default = false,
    Callback = function(v) print("[Demo] Aimbot:", v) end,
})
secAimbot:Slider({
    Name = "FOV",
    Default = 100, Min = 10, Max = 500,
    Callback = function(v) print("[Demo] FOV:", v) end,
})
secAimbot:Slider({
    Name = "Smoothness",
    Default = 0.15, Min = 0.05, Max = 1, Decimals = 2,
    Callback = function(v) print("[Demo] Smoothness:", v) end,
})

local secTrigger = tabCombat:Section({Name = "Triggerbot"})
secTrigger:Toggle({
    Name = "Enabled",
    Default = false,
    Callback = function(v) print("[Demo] Trigger:", v) end,
})
secTrigger:Slider({
    Name = "Delay (ms)",
    Default = 50, Min = 0, Max = 500,
    Callback = function(v) print("[Demo] Delay:", v) end,
})
secTrigger:Toggle({
    Name = "Wallcheck",
    Default = true,
    Callback = function(v) print("[Demo] Wallcheck:", v) end,
})

----------- TAB 3: Visuals -----------

local tabVis = window:Tab({Name = "Visuals", Icon = "◇"})

local secEsp = tabVis:Section({Name = "ESP"})
secEsp:Toggle({Name = "Box", Default = true, Callback = function(v) print("[Demo] Box:", v) end})
secEsp:Toggle({Name = "Healthbar", Default = true, Callback = function(v) print("[Demo] HP bar:", v) end})
secEsp:Toggle({Name = "Name", Default = true, Callback = function(v) print("[Demo] Name:", v) end})
secEsp:Toggle({Name = "Distance", Default = true, Callback = function(v) print("[Demo] Distance:", v) end})
secEsp:Toggle({Name = "Tracers", Default = false, Callback = function(v) print("[Demo] Tracers:", v) end})
secEsp:Toggle({Name = "Chams", Default = false, Callback = function(v) print("[Demo] Chams:", v) end})
secEsp:Slider({Name = "Max distance", Default = 500, Min = 50, Max = 2000, Callback = function(v) print("[Demo] Max:", v) end})

local secWorld = tabVis:Section({Name = "World"})
secWorld:Toggle({Name = "Fullbright", Default = false, Callback = function(v) print("[Demo] Fullbright:", v) end})
secWorld:Slider({Name = "FOV", Default = 70, Min = 1, Max = 120, Callback = function(v) print("[Demo] Camera FOV:", v) end})

----------- TAB 4: Misc -----------

local tabMisc = window:Tab({Name = "Misc", Icon = "⚙"})

local secUtil = tabMisc:Section({Name = "Utility"})
secUtil:Toggle({Name = "Anti-AFK", Default = true, Callback = function(v) print("[Demo] Anti-AFK:", v) end})
secUtil:Button({Name = "Rejoin", Callback = function() print("[Demo] Rejoin clicked") end})
secUtil:Button({Name = "Server hop", Callback = function() print("[Demo] Hop clicked") end})

local secConfig = tabMisc:Section({Name = "Config"})
secConfig:Button({Name = "Save current", Callback = function() print("[Demo] Save clicked") end})
secConfig:Button({Name = "Load default", Callback = function() print("[Demo] Load clicked") end})
secConfig:Keybind({Name = "Panic key", Default = Enum.KeyCode.End, Callback = function() print("[Demo] PANIC!") end})

print("[Halo Demo] Loaded. Press \\ to toggle window.")
