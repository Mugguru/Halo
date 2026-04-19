-- Sanity test: creates a plain red box on screen with no library involved.
-- If you see a red square in the middle of your screen for 5 seconds, your
-- executor can create GUIs and the issue is in halo.lua.
-- If you see NOTHING, the issue is at the GUI/host-parent layer.

local function getHostGui()
    if gethui then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

print("[Sanity] gethui exists:", gethui ~= nil)
print("[Sanity] getgenv exists:", getgenv ~= nil)

local host = getHostGui()
print("[Sanity] host gui:", host, "class:", host.ClassName)

local screen = Instance.new("ScreenGui")
screen.Name = "HaloSanity"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 9999
screen.Parent = host

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.Size = UDim2.new(0, 300, 0, 200)
box.Position = UDim2.new(0.5, 0, 0.5, 0)
box.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
box.BorderSizePixel = 0
box.Parent = screen

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "If you see this,\nGUI creation works.\nDestroying in 5s."
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = box

print("[Sanity] Box created. ScreenGui Enabled:", screen.Enabled)
print("[Sanity] Box AbsoluteSize:", box.AbsoluteSize)
print("[Sanity] Box Visible:", box.Visible)

task.delay(5, function()
    screen:Destroy()
    print("[Sanity] Cleaned up.")
end)
