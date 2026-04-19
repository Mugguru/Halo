-- Halo UI Library — Brutalist Mono
-- Hard rectangles, mono type, heavy borders, accent slabs. No shadows, no
-- gradients, no soft tweens. Same component API as before:
--   local library = getgenv().Halo
--   local window  = library:Window({Name = "HALO", ToggleKey = Enum.KeyCode.BackSlash})
--   local tab     = window:Tab({Name = "MOVEMENT"})
--   local sec     = tab:Section({Name = "SPEED"})
--   sec:Toggle{Name="Walk speed override", Default=false, Callback=function(v) end}
--   sec:Slider{Name="Walk speed", Default=16, Min=16, Max=200, Callback=function(v) end}
--   sec:Button{Name="Reset", Callback=function() end}
--   sec:Keybind{Name="Toggle", Default=Enum.KeyCode.E, Callback=function(k) end}

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")

local LP = Players.LocalPlayer

-------------------------------------------------------------------------------
-- THEME — brutalist mono
-------------------------------------------------------------------------------

local THEME = {
    -- surfaces
    bg_window      = Color3.fromRGB(14, 14, 16),
    bg_sidebar     = Color3.fromRGB(10, 10, 12),
    bg_section     = Color3.fromRGB(20, 20, 22),
    bg_input       = Color3.fromRGB(26, 26, 30),
    bg_hover       = Color3.fromRGB(36, 36, 40),

    -- accent (purple)
    accent         = Color3.fromRGB(150, 100, 255),
    accent_dim     = Color3.fromRGB(95, 60, 175),
    accent_text    = Color3.fromRGB(14, 14, 16), -- text rendered ON accent fills

    -- borders
    border         = Color3.fromRGB(55, 55, 60),
    border_hi      = Color3.fromRGB(220, 220, 225),

    -- text
    text           = Color3.fromRGB(235, 235, 240),
    text_dim       = Color3.fromRGB(135, 135, 140),
    text_faint     = Color3.fromRGB(85, 85, 90),

    danger         = Color3.fromRGB(240, 70, 80),

    -- typography (monospace)
    font           = Enum.Font.RobotoMono,
    text_size      = 13,
    text_size_sm   = 11,
    text_size_lg   = 14,

    -- geometry
    sidebar_w      = 168,
    titlebar_h     = 38,
    window_w       = 640,
    window_h       = 470,

    pad            = 14,
    pad_sm         = 10,
    section_gap    = 10,
    component_gap  = 8,

    -- ALL borders are this thickness so the brutalist grid feels consistent.
    border_w       = 1,
    border_w_hi    = 2,

    -- snappy linear tween only — no back-bounce, no overshoot
    tween_fast     = 0.08,
    tween_med      = 0.14,
}

-------------------------------------------------------------------------------
-- UTIL
-------------------------------------------------------------------------------

local function tween(obj, t, props, style, dir)
    local info = TweenInfo.new(t, style or Enum.EasingStyle.Linear, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function new(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = inst end
    end
    return inst
end

local function stroke(parent, color, thickness)
    return new("UIStroke", {
        Color = color or THEME.border,
        Thickness = thickness or THEME.border_w,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = parent,
    })
end

local function padding(parent, p, b, l, r)
    return new("UIPadding", {
        PaddingTop    = UDim.new(0, p),
        PaddingBottom = UDim.new(0, b or p),
        PaddingLeft   = UDim.new(0, l or p),
        PaddingRight  = UDim.new(0, r or p),
        Parent = parent,
    })
end

local function listLayout(parent, gap, dir)
    return new("UIListLayout", {
        FillDirection = dir or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, gap or 0),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function getHostGui()
    if gethui then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

local function makeDraggable(handle, target)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = target.Position
            startInput = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-------------------------------------------------------------------------------
-- LIBRARY ROOT
-------------------------------------------------------------------------------

local library = {}
library.__index = library
library._windows = {}

if _G._HALO_CLEANUP then
    pcall(_G._HALO_CLEANUP)
    _G._HALO_CLEANUP = nil
end

-------------------------------------------------------------------------------
-- WINDOW
-------------------------------------------------------------------------------

function library:Window(opts)
    opts = opts or {}
    local windowName = (opts.Name or "HALO"):upper()
    local toggleKey  = opts.ToggleKey or Enum.KeyCode.BackSlash
    if opts.Accent then THEME.accent = opts.Accent end

    local screen = new("ScreenGui", {
        Name = "Halo_" .. windowName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = getHostGui(),
    })

    -- Main window — hard rectangle, no shadow, no rounded corners.
    local main = new("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, THEME.window_w, 0, THEME.window_h),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = THEME.bg_window,
        BorderSizePixel = 0,
        Parent = screen,
    })
    stroke(main, THEME.border_hi, THEME.border_w_hi)

    -- Sidebar
    local sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, THEME.sidebar_w, 1, 0),
        BackgroundColor3 = THEME.bg_sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })
    -- Hard 2px right divider on the sidebar
    new("Frame", {
        Name = "SidebarDivider",
        Size = UDim2.new(0, THEME.border_w_hi, 1, 0),
        Position = UDim2.new(1, -THEME.border_w_hi, 0, 0),
        BackgroundColor3 = THEME.border_hi,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    -- Sidebar header — solid accent slab with the window name in inverted text
    local sidebarHeader = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, -THEME.border_w_hi, 0, THEME.titlebar_h),
        BackgroundColor3 = THEME.accent,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    -- Bottom hard divider on the header to separate from tabs
    new("Frame", {
        Size = UDim2.new(1, 0, 0, THEME.border_w_hi),
        Position = UDim2.new(0, 0, 1, -THEME.border_w_hi),
        BackgroundColor3 = THEME.border_hi,
        BorderSizePixel = 0,
        Parent = sidebarHeader,
    })

    new("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -THEME.pad * 2, 1, 0),
        Position = UDim2.new(0, THEME.pad, 0, 0),
        BackgroundTransparency = 1,
        Font = THEME.font,
        Text = "// " .. windowName,
        TextSize = THEME.text_size_lg,
        TextColor3 = THEME.accent_text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = sidebarHeader,
    })

    -- Tab list
    local tabContainer = new("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -THEME.border_w_hi, 1, -(THEME.titlebar_h + 32)),
        Position = UDim2.new(0, 0, 0, THEME.titlebar_h),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    listLayout(tabContainer, 0)

    -- Sidebar footer
    local footer = new("Frame", {
        Size = UDim2.new(1, -THEME.border_w_hi, 0, 32),
        Position = UDim2.new(0, 0, 1, -32),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    -- Top divider on footer
    new("Frame", {
        Size = UDim2.new(1, 0, 0, THEME.border_w),
        BackgroundColor3 = THEME.border,
        BorderSizePixel = 0,
        Parent = footer,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -THEME.pad * 2, 1, 0),
        Position = UDim2.new(0, THEME.pad, 0, 0),
        BackgroundTransparency = 1,
        Font = THEME.font,
        Text = "v0.1 // BRUTAL",
        TextSize = THEME.text_size_sm,
        TextColor3 = THEME.text_faint,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })

    -- Content area (right side)
    local content = new("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -THEME.sidebar_w, 1, 0),
        Position = UDim2.new(0, THEME.sidebar_w, 0, 0),
        BackgroundTransparency = 1,
        Parent = main,
    })

    -- Title bar
    local titlebar = new("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, THEME.titlebar_h),
        BackgroundColor3 = THEME.bg_window,
        BorderSizePixel = 0,
        Parent = content,
    })
    -- Bottom hard divider on titlebar
    new("Frame", {
        Size = UDim2.new(1, 0, 0, THEME.border_w_hi),
        Position = UDim2.new(0, 0, 1, -THEME.border_w_hi),
        BackgroundColor3 = THEME.border_hi,
        BorderSizePixel = 0,
        Parent = titlebar,
    })

    local pageTitle = new("TextLabel", {
        Name = "PageTitle",
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.new(0, THEME.pad, 0, 0),
        BackgroundTransparency = 1,
        Font = THEME.font,
        Text = "",
        TextSize = THEME.text_size_lg,
        TextColor3 = THEME.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titlebar,
    })

    -- Close button — hollow square, fills danger red on hover
    local closeBtn = new("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0.5, -11),
        BackgroundColor3 = THEME.bg_window,
        BorderSizePixel = 0,
        Font = THEME.font,
        Text = "X",
        TextSize = 12,
        TextColor3 = THEME.text,
        AutoButtonColor = false,
        Parent = titlebar,
    })
    stroke(closeBtn, THEME.border_hi, THEME.border_w)
    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundColor3 = THEME.danger
        closeBtn.TextColor3 = THEME.bg_window
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundColor3 = THEME.bg_window
        closeBtn.TextColor3 = THEME.text
    end)

    -- Page container
    local pages = new("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, 0, 1, -THEME.titlebar_h),
        Position = UDim2.new(0, 0, 0, THEME.titlebar_h),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = content,
    })

    -- Drag (sidebar header + titlebar)
    makeDraggable(sidebarHeader, main)
    makeDraggable(titlebar, main)

    ----------- WINDOW OBJECT -----------

    local window = setmetatable({
        _screen = screen,
        _main = main,
        _tabContainer = tabContainer,
        _pages = pages,
        _pageTitle = pageTitle,
        _tabs = {},
        _activeTab = nil,
        _toggleKey = toggleKey,
        _opened = true,
    }, {__index = library})

    table.insert(library._windows, window)

    ----------- OPEN / CLOSE — instant, no bounce -----------

    local function setOpen(state)
        window._opened = state
        screen.Enabled = state
    end

    closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)

    local toggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == toggleKey then setOpen(not window._opened) end
    end)

    function window:SetOpen(s) setOpen(s) end
    function window:Toggle()   setOpen(not window._opened) end
    function window:Destroy()
        toggleConn:Disconnect()
        screen:Destroy()
    end

    -------------------------------------------------------------------------------
    -- TAB
    -------------------------------------------------------------------------------

    function window:Tab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = (tabOpts.Name or "TAB"):upper()

        -- Sidebar tab button — full-width hard rectangle, bottom 1px divider
        local btn = new("TextButton", {
            Name = "Tab_" .. tabName,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = THEME.bg_sidebar,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = self._tabContainer,
        })
        -- 1px divider at bottom
        new("Frame", {
            Size = UDim2.new(1, 0, 0, THEME.border_w),
            Position = UDim2.new(0, 0, 1, -THEME.border_w),
            BackgroundColor3 = THEME.border,
            BorderSizePixel = 0,
            Parent = btn,
        })
        -- Active accent slab on left edge
        local accentBar = new("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = THEME.accent,
            BorderSizePixel = 0,
            Visible = false,
            Parent = btn,
        })

        local label = new("TextLabel", {
            Size = UDim2.new(1, -THEME.pad * 2, 1, 0),
            Position = UDim2.new(0, THEME.pad, 0, 0),
            BackgroundTransparency = 1,
            Font = THEME.font,
            Text = tabName,
            TextSize = THEME.text_size,
            TextColor3 = THEME.text_dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })

        -- Page (scrolling)
        local page = new("ScrollingFrame", {
            Name = "Page_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = THEME.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = self._pages,
        })
        padding(page, THEME.pad)
        listLayout(page, THEME.section_gap)

        local tab = {
            _btn = btn,
            _label = label,
            _accentBar = accentBar,
            _page = page,
            _name = tabName,
            _window = self,
        }

        local function setActive(active)
            if active then
                btn.BackgroundColor3 = THEME.bg_window
                label.TextColor3 = THEME.text
                accentBar.Visible = true
                page.Visible = true
                self._pageTitle.Text = "// " .. tabName
                self._activeTab = tab
            else
                btn.BackgroundColor3 = THEME.bg_sidebar
                label.TextColor3 = THEME.text_dim
                accentBar.Visible = false
                page.Visible = false
            end
        end
        tab._setActive = setActive

        btn.MouseEnter:Connect(function()
            if self._activeTab ~= tab then
                btn.BackgroundColor3 = THEME.bg_hover
                label.TextColor3 = THEME.text
            end
        end)
        btn.MouseLeave:Connect(function()
            if self._activeTab ~= tab then
                btn.BackgroundColor3 = THEME.bg_sidebar
                label.TextColor3 = THEME.text_dim
            end
        end)
        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(self._tabs) do t._setActive(false) end
            setActive(true)
        end)

        table.insert(self._tabs, tab)
        if #self._tabs == 1 then setActive(true) end

        ---------------------------------------------------------------------------
        -- SECTION
        ---------------------------------------------------------------------------

        function tab:Section(secOpts)
            secOpts = secOpts or {}
            local secName = (secOpts.Name or "SECTION"):upper()

            local section = new("Frame", {
                Name = "Section_" .. secName,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = THEME.bg_section,
                BorderSizePixel = 0,
                Parent = self._page,
            })
            stroke(section, THEME.border, THEME.border_w)

            -- Header — solid bar across the top, accent square on the left
            local header = new("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = THEME.bg_input,
                BorderSizePixel = 0,
                LayoutOrder = 0,
                Parent = section,
            })
            -- 1px divider under header
            new("Frame", {
                Size = UDim2.new(1, 0, 0, THEME.border_w),
                Position = UDim2.new(0, 0, 1, -THEME.border_w),
                BackgroundColor3 = THEME.border,
                BorderSizePixel = 0,
                Parent = header,
            })
            -- Accent square block on the left of the header
            new("Frame", {
                Size = UDim2.new(0, 26, 1, 0),
                BackgroundColor3 = THEME.accent,
                BorderSizePixel = 0,
                Parent = header,
            })
            new("TextLabel", {
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 36, 0, 0),
                BackgroundTransparency = 1,
                Font = THEME.font,
                Text = secName,
                TextSize = THEME.text_size_sm,
                TextColor3 = THEME.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = header,
            })

            local body = new("Frame", {
                Name = "Body",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Parent = section,
            })
            padding(body, THEME.pad_sm)
            listLayout(body, THEME.component_gap)

            -- Section is itself a vertical list (header, body)
            listLayout(section, 0)

            local sec = {_frame = section, _body = body}

            -----------------------------------------------------------------------
            -- TOGGLE  — hollow square (off) / solid accent square (on)
            -----------------------------------------------------------------------

            function sec:Toggle(o)
                o = o or {}
                local state = o.Default and true or false

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Parent = self._body,
                })

                local label = new("TextLabel", {
                    Size = UDim2.new(1, -32, 1, 0),
                    BackgroundTransparency = 1,
                    Font = THEME.font,
                    Text = o.Name or "Toggle",
                    TextSize = THEME.text_size,
                    TextColor3 = THEME.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local box = new("TextButton", {
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -20, 0.5, -10),
                    BackgroundColor3 = THEME.bg_input,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    Parent = row,
                })
                local boxStroke = stroke(box, THEME.border_hi, THEME.border_w)

                local function render()
                    if state then
                        box.BackgroundColor3 = THEME.accent
                        boxStroke.Color = THEME.accent
                    else
                        box.BackgroundColor3 = THEME.bg_input
                        boxStroke.Color = THEME.border_hi
                    end
                end
                render()

                local function setState(v)
                    state = v and true or false
                    render()
                    if o.Callback then
                        local ok, err = pcall(o.Callback, state)
                        if not ok then warn("[Halo] Toggle callback: " .. tostring(err)) end
                    end
                end

                box.MouseButton1Click:Connect(function() setState(not state) end)
                -- Whole row clickable for ergonomics
                local rowBtn = new("TextButton", {
                    Size = UDim2.new(1, -32, 1, 0),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    Text = "",
                    Parent = row,
                })
                rowBtn.MouseButton1Click:Connect(function() setState(not state) end)

                return {Set = setState, Get = function() return state end}
            end

            -----------------------------------------------------------------------
            -- SLIDER — hard fill bar, value shown as [ 145 ] mono
            -----------------------------------------------------------------------

            function sec:Slider(o)
                o = o or {}
                local minV, maxV = o.Min or 0, o.Max or 100
                local val = o.Default or minV
                local decimals = o.Decimals or 0
                local function fmt(v)
                    if decimals == 0 then return tostring(math.floor(v + 0.5)) end
                    return string.format("%." .. decimals .. "f", v)
                end

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    Parent = self._body,
                })

                new("TextLabel", {
                    Size = UDim2.new(1, -100, 0, 16),
                    BackgroundTransparency = 1,
                    Font = THEME.font,
                    Text = o.Name or "Slider",
                    TextSize = THEME.text_size,
                    TextColor3 = THEME.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local valueLabel = new("TextLabel", {
                    Size = UDim2.new(0, 100, 0, 16),
                    Position = UDim2.new(1, -100, 0, 0),
                    BackgroundTransparency = 1,
                    Font = THEME.font,
                    Text = "[ " .. fmt(val) .. " ]",
                    TextSize = THEME.text_size,
                    TextColor3 = THEME.accent,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = row,
                })

                local bar = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.new(0, 0, 0, 22),
                    BackgroundColor3 = THEME.bg_input,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    Parent = row,
                })
                stroke(bar, THEME.border_hi, THEME.border_w)

                local fill = new("Frame", {
                    Size = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0),
                    BackgroundColor3 = THEME.accent,
                    BorderSizePixel = 0,
                    Parent = bar,
                })

                local function setVal(v, fire)
                    v = math.clamp(v, minV, maxV)
                    if decimals == 0 then v = math.floor(v + 0.5) end
                    val = v
                    local pct = (v - minV) / (maxV - minV)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    valueLabel.Text = "[ " .. fmt(v) .. " ]"
                    if fire ~= false and o.Callback then
                        local ok, err = pcall(o.Callback, v)
                        if not ok then warn("[Halo] Slider callback: " .. tostring(err)) end
                    end
                end

                local dragging = false
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                        setVal(minV + (maxV - minV) * math.clamp(rel, 0, 1))
                    end
                end)
                bar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
                        local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                        setVal(minV + (maxV - minV) * math.clamp(rel, 0, 1))
                    end
                end)

                setVal(val, false)
                return {Set = setVal, Get = function() return val end}
            end

            -----------------------------------------------------------------------
            -- BUTTON  — full-width rect, hover inverts (bg→accent, text→bg)
            -----------------------------------------------------------------------

            function sec:Button(o)
                o = o or {}
                local btn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = THEME.bg_input,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Font = THEME.font,
                    Text = "> " .. (o.Name or "Button"),
                    TextSize = THEME.text_size,
                    TextColor3 = THEME.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = self._body,
                })
                padding(btn, 0, 0, THEME.pad_sm, THEME.pad_sm)
                stroke(btn, THEME.border, THEME.border_w)
                btn.MouseEnter:Connect(function()
                    btn.BackgroundColor3 = THEME.accent
                    btn.TextColor3 = THEME.accent_text
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundColor3 = THEME.bg_input
                    btn.TextColor3 = THEME.text
                end)
                btn.MouseButton1Click:Connect(function()
                    btn.BackgroundColor3 = THEME.accent_dim
                    task.delay(0.06, function() btn.BackgroundColor3 = THEME.accent end)
                    if o.Callback then
                        local ok, err = pcall(o.Callback)
                        if not ok then warn("[Halo] Button callback: " .. tostring(err)) end
                    end
                end)
                return {SetText = function(t) btn.Text = "> " .. t end}
            end

            -----------------------------------------------------------------------
            -- KEYBIND — value shown in [ KEY ] brackets, listening shows [ ... ]
            -----------------------------------------------------------------------

            function sec:Keybind(o)
                o = o or {}
                local key = o.Default
                local listening = false

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Parent = self._body,
                })

                new("TextLabel", {
                    Size = UDim2.new(1, -100, 1, 0),
                    BackgroundTransparency = 1,
                    Font = THEME.font,
                    Text = o.Name or "Keybind",
                    TextSize = THEME.text_size,
                    TextColor3 = THEME.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local btn = new("TextButton", {
                    Size = UDim2.new(0, 96, 1, 0),
                    Position = UDim2.new(1, -96, 0, 0),
                    BackgroundColor3 = THEME.bg_input,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Font = THEME.font,
                    Text = "[ " .. (key and key.Name:upper() or "NONE") .. " ]",
                    TextSize = THEME.text_size_sm,
                    TextColor3 = THEME.accent,
                    Parent = row,
                })
                stroke(btn, THEME.border_hi, THEME.border_w)
                btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.bg_hover end)
                btn.MouseLeave:Connect(function() btn.BackgroundColor3 = THEME.bg_input end)

                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = "[ ... ]"
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                key = nil
                                btn.Text = "[ NONE ]"
                            else
                                key = input.KeyCode
                                btn.Text = "[ " .. key.Name:upper() .. " ]"
                            end
                            listening = false
                            if o.Callback then pcall(o.Callback, key) end
                        end
                        return
                    end
                    if processed then return end
                    if key and input.KeyCode == key and o.Callback then
                        pcall(o.Callback, key)
                    end
                end)

                return {
                    Set = function(k) key = k; btn.Text = "[ " .. (k and k.Name:upper() or "NONE") .. " ]" end,
                    Get = function() return key end,
                }
            end

            return sec
        end

        return tab
    end

    return window
end

-------------------------------------------------------------------------------
-- GLOBAL CLEANUP + EXPOSE
-------------------------------------------------------------------------------

_G._HALO_CLEANUP = function()
    for _, w in pairs(library._windows) do
        pcall(function() w:Destroy() end)
    end
    library._windows = {}
end

local genv = (getgenv and getgenv()) or _G
genv.Halo = library
_G.Halo = library
print("[Halo] Library loaded (brutalist mono). Stored at getgenv().Halo")

return library
