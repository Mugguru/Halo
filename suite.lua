-- Halo Universal Suite — feature consumer for the Halo UI library.
--
-- USAGE:
--   1) Paste halo.lua into Potassium and run it once (registers getgenv().Halo).
--   2) Paste this file and run it.
--   3) Toggle window with `\` (backslash). Hover Movement tab to test.
--
-- This file is the cheat itself. halo.lua only draws the UI.
-- Tabs: MOVEMENT (live), VISUALS / COMBAT / MISC (stubbed for now).

local genv = (getgenv and getgenv()) or _G
local library = genv.Halo or _G.Halo
if not library then
    error("[Halo Suite] Library not loaded. Run halo.lua first (it registers getgenv().Halo).")
end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")

local LP = Players.LocalPlayer

-------------------------------------------------------------------------------
-- CHARACTER REFS — refreshed on respawn, used by every movement feature
-------------------------------------------------------------------------------

local character, humanoid, root

local function refreshCharacter(char)
    character = char or LP.Character
    if not character then return end
    humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    root     = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
end
refreshCharacter()

-------------------------------------------------------------------------------
-- WINDOW
-------------------------------------------------------------------------------

local window = library:Window({
    Name = "HALO",
    ToggleKey = Enum.KeyCode.BackSlash,
})

-------------------------------------------------------------------------------
-- MOVEMENT TAB
-------------------------------------------------------------------------------

local tabMove = window:Tab({Name = "MOVEMENT"})

----------------------------------------------------------------- SPEED -----
-- Walk speed and jump power overrides. Each has its own toggle so the slider
-- value isn't applied until you opt in. Originals are cached when override
-- turns on so games with custom defaults (e.g. WalkSpeed = 20) restore right.

local secSpeed = tabMove:Section({Name = "SPEED"})

local speedOverride, speedValue = false, 16
local origWalkSpeed = 16
local jumpOverride,  jumpValue  = false, 50
local origJumpPower, origJumpHeight, origUseJumpPower = 50, 7.2, true

local function applySpeed()
    if not humanoid then return end
    if speedOverride then
        humanoid.WalkSpeed = speedValue
    else
        humanoid.WalkSpeed = origWalkSpeed
    end
end

local function applyJump()
    if not humanoid then return end
    if jumpOverride then
        -- Roblox now supports both JumpPower and JumpHeight depending on
        -- UseJumpPower. Set both so the override sticks regardless of mode.
        humanoid.JumpPower  = jumpValue
        humanoid.JumpHeight = jumpValue * (7.2 / 50)  -- proportional
    else
        humanoid.JumpPower      = origJumpPower
        humanoid.JumpHeight     = origJumpHeight
        humanoid.UseJumpPower   = origUseJumpPower
    end
end

secSpeed:Toggle({
    Name = "Walk speed override",
    Default = false,
    Callback = function(v)
        if v and humanoid then origWalkSpeed = humanoid.WalkSpeed end
        speedOverride = v
        applySpeed()
    end,
})
secSpeed:Slider({
    Name = "Walk speed",
    Default = 16, Min = 16, Max = 250,
    Callback = function(v)
        speedValue = v
        if speedOverride then applySpeed() end
    end,
})

secSpeed:Toggle({
    Name = "Jump power override",
    Default = false,
    Callback = function(v)
        if v and humanoid then
            origJumpPower    = humanoid.JumpPower
            origJumpHeight   = humanoid.JumpHeight
            origUseJumpPower = humanoid.UseJumpPower
        end
        jumpOverride = v
        applyJump()
    end,
})
secSpeed:Slider({
    Name = "Jump power",
    Default = 50, Min = 50, Max = 500,
    Callback = function(v)
        jumpValue = v
        if jumpOverride then applyJump() end
    end,
})

----------------------------------------------------------------- NOCLIP -----
-- Sets CanCollide=false on every BasePart of the character every Stepped.
-- On disable: restore CanCollide=true on body parts (skip HumanoidRootPart,
-- which is always non-colliding by default).

local secMobility = tabMove:Section({Name = "MOBILITY"})

local noclipEnabled = false
local noclipConn

local function noclipStep()
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

local function noclipRestore()
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
end

secMobility:Toggle({
    Name = "Noclip",
    Default = false,
    Callback = function(v)
        noclipEnabled = v
        if v then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(noclipStep)
            end
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            noclipRestore()
        end
    end,
})

----------------------------------------------------------------- FLY -----
-- Camera-relative fly using BodyVelocity + BodyGyro on HumanoidRootPart.
-- BodyMovers are widely supported across Roblox games (LinearVelocity is
-- newer but not always available). PlatformStand prevents the Humanoid
-- from fighting the velocity by trying to walk back to the ground.

local flyEnabled = false
local flySpeed   = 50
local flyConn
local flyBV, flyBG

local function flyStop()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if humanoid then humanoid.PlatformStand = false end
end

local function flyStart()
    if not character or not root or not humanoid then return end
    flyStop() -- clean any stale movers

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "HaloFlyBV"
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "HaloFlyBG"
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 9000
    flyBG.D = 1000
    flyBG.CFrame = Workspace.CurrentCamera.CFrame
    flyBG.Parent = root

    humanoid.PlatformStand = true

    flyConn = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not character or not root then return end
        local cam = Workspace.CurrentCamera
        local move = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then move = move + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then move = move - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then move = move - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then move = move + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
        if move.Magnitude > 0 then move = move.Unit end
        flyBV.Velocity = move * flySpeed
        flyBG.CFrame = cam.CFrame
    end)
end

secMobility:Toggle({
    Name = "Fly",
    Default = false,
    Callback = function(v)
        flyEnabled = v
        if v then flyStart() else flyStop() end
    end,
})
secMobility:Slider({
    Name = "Fly speed",
    Default = 50, Min = 10, Max = 500,
    Callback = function(v) flySpeed = v end,
})

local flyKeybindRef -- captured below for keybind callback
flyKeybindRef = secMobility:Keybind({
    Name = "Toggle fly",
    Default = Enum.KeyCode.F,
    Callback = function()
        flyEnabled = not flyEnabled
        if flyEnabled then flyStart() else flyStop() end
    end,
})

----------------------------------------------------------------- MISC MOVEMENT -----

local secMiscMove = tabMove:Section({Name = "MISC"})

local infJumpEnabled = false
secMiscMove:Toggle({
    Name = "Infinite jump",
    Default = false,
    Callback = function(v) infJumpEnabled = v end,
})
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-------------------------------------------------------------------------------
-- RESPAWN HANDLER — re-engage features on the new character
-------------------------------------------------------------------------------

LP.CharacterAdded:Connect(function(char)
    refreshCharacter(char)
    -- Wait for humanoid to be fully wired up before applying overrides.
    char:WaitForChild("Humanoid", 5)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.2)

    -- Cache new defaults (since the new character may have different ones)
    if humanoid then
        if not speedOverride then origWalkSpeed = humanoid.WalkSpeed end
        if not jumpOverride then
            origJumpPower    = humanoid.JumpPower
            origJumpHeight   = humanoid.JumpHeight
            origUseJumpPower = humanoid.UseJumpPower
        end
        applySpeed()
        applyJump()
    end

    if flyEnabled then flyStart() end
    -- Noclip step uses the live `character` var, no rewire needed
end)

-------------------------------------------------------------------------------
-- VISUALS TAB — stub
-------------------------------------------------------------------------------

local tabVis = window:Tab({Name = "VISUALS"})
local secEspTodo = tabVis:Section({Name = "ESP — COMING NEXT"})
secEspTodo:Button({Name = "Box / Healthbar / Name / Distance / Tracers / Chams", Callback = function() end})
local secWorldTodo = tabVis:Section({Name = "WORLD — COMING NEXT"})
secWorldTodo:Button({Name = "Fullbright / FOV", Callback = function() end})

-------------------------------------------------------------------------------
-- COMBAT TAB — stub
-------------------------------------------------------------------------------

local tabCombat = window:Tab({Name = "COMBAT"})
tabCombat:Section({Name = "AIMBOT — TODO"}):Button({Name = "3 lock modes / FOV / smoothness / wallcheck", Callback = function() end})
tabCombat:Section({Name = "TRIGGERBOT — TODO"}):Button({Name = "Auto-fire on crosshair target", Callback = function() end})
tabCombat:Section({Name = "SILENT AIM — TODO"}):Button({Name = "Registry + heuristic remote detection", Callback = function() end})

-------------------------------------------------------------------------------
-- MISC TAB — stub
-------------------------------------------------------------------------------

local tabMisc = window:Tab({Name = "MISC"})
tabMisc:Section({Name = "UTILITY — TODO"}):Button({Name = "Anti-AFK / Rejoin / Server hop", Callback = function() end})
tabMisc:Section({Name = "CONFIG — TODO"}):Button({Name = "Save / Load / Panic key", Callback = function() end})

-------------------------------------------------------------------------------

print("[Halo Suite] Loaded. Movement features live. Press \\ to toggle window.")
