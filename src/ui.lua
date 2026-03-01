-- src/ui.lua
-- Professional draggable sidebar dashboard

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Config = _G.Freecam.require("config")
local Camera = _G.Freecam.require("camera")
local SpeedManager = _G.Freecam.require("speed")
local Nametag = _G.Freecam.require("nametag")
local Recording = _G.Freecam.require("recording")
local Visuals = _G.Freecam.require("visuals")

local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    ContentFrame = nil,
    IsOpen = true,
    IsMinimized = false,
    _toggles = {},
    _pages = {},
    _navButtons = {},
    _currentPage = nil
}

local function MakeDraggable(topbar, frame)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function CreateToggle(parent, text, defaultState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UI.TextColor
    label.Font = Config.UI.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 44, 0, 24)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -12)
    toggleBg.BackgroundColor3 = defaultState and Config.UI.AccentColor or Config.UI.SectionColor
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = toggleBg

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = toggleBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local state = defaultState
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function setState(newState)
        state = newState
        local goalCircle = {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}
        local goalBg = {BackgroundColor3 = state and Config.UI.AccentColor or Config.UI.SectionColor}
        TweenService:Create(circle, tweenInfo, goalCircle):Play()
        TweenService:Create(toggleBg, tweenInfo, goalBg):Play()
        callback(state)
    end

    toggleBg.MouseButton1Click:Connect(function()
        setState(not state)
    end)
    
    UI._toggles[text] = setState
end

local function CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UI.TextColor
    label.Font = Config.UI.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -60, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Config.UI.AccentColor
    valueLabel.Font = Config.UI.Font
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(1, -20, 0, 6)
    bg.Position = UDim2.new(0, 10, 0, 30)
    bg.BackgroundColor3 = Config.UI.SectionColor
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.Parent = container
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = bg

    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Config.UI.AccentColor
    fill.Parent = bg
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local dragging = false

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = min + (max - min) * pos
        
        if max <= 10 then valueLabel.Text = string.format("%.2f", val)
        else valueLabel.Text = tostring(math.floor(val)) end
        callback(val)
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
end

function UI.Init()
    local sg = Instance.new("ScreenGui")
    sg.Name = "FreecamDashboard"
    sg.DisplayOrder = 100000
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = CoreGui end)
    if not (sg.Parent) then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    UI.ScreenGui = sg

    local mf = Instance.new("Frame")
    mf.Name = "MainFrame"
    mf.Size = UDim2.new(0, 420, 0, 300)
    mf.Position = UDim2.new(1, -440, 0.5, -150)
    mf.BackgroundColor3 = Config.UI.BackgroundColor
    mf.ClipsDescendants = true
    mf.Parent = sg
    UI.MainFrame = mf

    local mfCorner = Instance.new("UICorner")
    mfCorner.CornerRadius = Config.UI.CornerRadius
    mfCorner.Parent = mf

    -- Topbar
    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 40)
    topbar.BackgroundColor3 = Config.UI.SectionColor
    topbar.Parent = mf
    
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = Config.UI.CornerRadius
    topCorner.Parent = topbar
    
    local topbarPatch = Instance.new("Frame")
    topbarPatch.Size = UDim2.new(1, 0, 0, 10)
    topbarPatch.Position = UDim2.new(0, 0, 1, -10)
    topbarPatch.BackgroundColor3 = Config.UI.SectionColor
    topbarPatch.BorderSizePixel = 0
    topbarPatch.Parent = topbar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FREECAM DASHBOARD"
    title.TextColor3 = Config.UI.TextColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topbar

    MakeDraggable(topbar, mf)

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -40, 0.5, -15)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Config.UI.TextColor
    minBtn.TextSize = 24
    minBtn.Font = Enum.Font.GothamMedium
    minBtn.Parent = topbar
    
    minBtn.MouseButton1Click:Connect(function()
        UI.IsMinimized = not UI.IsMinimized
        if UI.IsMinimized then
            minBtn.Text = "+"
            TweenService:Create(mf, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 40)}):Play()
        else
            minBtn.Text = "-"
            TweenService:Create(mf, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 300)}):Play()
        end
    end)

    -- Content Frame
    local cf = Instance.new("Frame")
    cf.Name = "ContentBody"
    cf.Size = UDim2.new(1, 0, 1, -40)
    cf.Position = UDim2.new(0, 0, 0, 40)
    cf.BackgroundTransparency = 1
    cf.Parent = mf
    UI.ContentFrame = cf

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, 0)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = cf

    local sbLayout = Instance.new("UIListLayout")
    sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sbLayout.Parent = sidebar

    local pageContainer = Instance.new("Frame")
    pageContainer.Size = UDim2.new(1, -120, 1, 0)
    pageContainer.Position = UDim2.new(0, 120, 0, 0)
    pageContainer.BackgroundTransparency = 1
    pageContainer.Parent = cf

    local function MakePage(name)
        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, 0, 1, -10)
        frame.Position = UDim2.new(0, 0, 0, 5)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 2
        frame.ScrollBarImageColor3 = Config.UI.SectionColor
        frame.Visible = false
        frame.Parent = pageContainer

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 5)
        layout.Parent = frame

        UI._pages[name] = frame

        local navBtn = Instance.new("TextButton")
        navBtn.Size = UDim2.new(1, 0, 0, 40)
        navBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        navBtn.BorderSizePixel = 0
        navBtn.Text = "  " .. name
        navBtn.TextColor3 = Config.UI.SubTextColor
        navBtn.Font = Enum.Font.GothamMedium
        navBtn.TextSize = 13
        navBtn.TextXAlignment = Enum.TextXAlignment.Left
        navBtn.Parent = sidebar
        
        local navHighlight = Instance.new("Frame")
        navHighlight.Size = UDim2.new(0, 3, 1, 0)
        navHighlight.BackgroundColor3 = Config.UI.AccentColor
        navHighlight.BorderSizePixel = 0
        navHighlight.Visible = false
        navHighlight.Parent = navBtn

        navBtn.MouseButton1Click:Connect(function()
            for pgName, pgFrame in pairs(UI._pages) do
                pgFrame.Visible = (pgName == name)
            end
            for _, btn in pairs(UI._navButtons) do
                btn.TextColor3 = Config.UI.SubTextColor
                btn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
                btn:FindFirstChildOfClass("Frame").Visible = false
            end
            navBtn.TextColor3 = Config.UI.TextColor
            navBtn.BackgroundColor3 = Config.UI.SectionColor
            navHighlight.Visible = true
        end)
        
        UI._navButtons[name] = navBtn

        return frame, layout
    end

    -- PAGES CREATE
    local pgCamera, lCamera = MakePage("Camera")
    local pgVisuals, lVisuals = MakePage("Visuals")
    local pgSettings, lSettings = MakePage("Settings")

    -- == CAMERA PAGE ==
    -- Speed Buttons
    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, 0, 0, 50)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = pgCamera

    local speedTitle = Instance.new("TextLabel")
    speedTitle.Size = UDim2.new(1, 0, 0, 20)
    speedTitle.Position = UDim2.new(0, 10, 0, 0)
    speedTitle.BackgroundTransparency = 1
    speedTitle.Text = "Movement Speed"
    speedTitle.TextColor3 = Config.UI.TextColor
    speedTitle.Font = Config.UI.Font
    speedTitle.TextSize = 13
    speedTitle.TextXAlignment = Enum.TextXAlignment.Left
    speedTitle.Parent = speedRow

    local speedBtnsContainer = Instance.new("Frame")
    speedBtnsContainer.Size = UDim2.new(1, -20, 0, 25)
    speedBtnsContainer.Position = UDim2.new(0, 10, 0, 22)
    speedBtnsContainer.BackgroundTransparency = 1
    speedBtnsContainer.Parent = speedRow

    local sbcLayout = Instance.new("UIListLayout")
    sbcLayout.FillDirection = Enum.FillDirection.Horizontal
    sbcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sbcLayout.Padding = UDim.new(0, 5)
    sbcLayout.Parent = speedBtnsContainer

    local speeds = {
        {"Walk", 16, 0.8},
        {"Normal", 50, 0.85},
        {"Fast", 150, 0.9},
        {"Cinematic", 20, 0.98}
    }

    local speedUIBtns = {}
    for i, data in ipairs(speeds) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 65, 1, 0)
        btn.BackgroundColor3 = Config.UI.SectionColor
        btn.Text = data[1]
        btn.TextColor3 = Config.UI.TextColor
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.AutoButtonColor = false
        btn.Parent = speedBtnsContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        if data[2] == Config.Camera.BaseSpeed then
            btn.BackgroundColor3 = Config.UI.AccentColor
        end

        btn.MouseButton1Click:Connect(function()
            SpeedManager.SetSpeed(data[2])
            SpeedManager.SetSmoothness(data[3])
            
            for _, b in pairs(speedUIBtns) do
                b.BackgroundColor3 = Config.UI.SectionColor
            end
            btn.BackgroundColor3 = Config.UI.AccentColor
        end)
        table.insert(speedUIBtns, btn)
    end

    CreateSlider(pgCamera, "Rotation Sensitivity", 0.1, 2, Config.Camera.RotationSensitivity, SpeedManager.SetRotationSensitivity)
    CreateSlider(pgCamera, "Boost Multiplier (Shift)", 1, 10, Config.Camera.BoostMultiplier, SpeedManager.SetBoostMultiplier)

    -- == VISUALS PAGE ==
    CreateToggle(pgVisuals, "Hide All Nametags", false, function(state) Nametag.Toggle(state) end)
    CreateToggle(pgVisuals, "Player Highlights (ESP)", false, function(state) Visuals.ToggleHighlights(state) end)
    CreateToggle(pgVisuals, "Night Vision", false, function(state) Visuals.ToggleNightVision(state) end)
    CreateToggle(pgVisuals, "Recording Indicator", false, function(state)
        if state ~= Recording.IsRecording then Recording.Toggle() end
    end)

    -- == SETTINGS PAGE ==
    CreateToggle(pgSettings, "Enable Freecam", false, function(state)
        if state then Camera.Enable() else Camera.Disable() end
    end)
    
    local helpText = Instance.new("TextLabel")
    helpText.Size = UDim2.new(1, -20, 0, 100)
    helpText.Position = UDim2.new(0, 10, 0, 0)
    helpText.BackgroundTransparency = 1
    helpText.Text = "Shortcuts:\nShift+L: Toggle Freecam\nShift+G: Screen Recording\nRightCtrl: Hide GUI Entirely\n\nMade for Roblox Executors."
    helpText.TextColor3 = Config.UI.SubTextColor
    helpText.Font = Config.UI.Font
    helpText.TextSize = 12
    helpText.TextXAlignment = Enum.TextXAlignment.Left
    helpText.TextYAlignment = Enum.TextYAlignment.Top
    helpText.Parent = pgSettings

    -- Set Default Tab
    UI._navButtons["Camera"]:FindFirstChildOfClass("Frame").Visible = true
    UI._navButtons["Camera"].TextColor3 = Config.UI.TextColor
    UI._navButtons["Camera"].BackgroundColor3 = Config.UI.SectionColor
    pgCamera.Visible = true

    -- Fix scroll sizes
    local function FixCanvas(pg, layout)
        pg.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end
    task.spawn(function()
        task.wait(0.2)
        FixCanvas(pgCamera, lCamera)
        FixCanvas(pgVisuals, lVisuals)
        FixCanvas(pgSettings, lSettings)
    end)
end

function UI.UpdateToggles()
    if UI._toggles["Enable Freecam"] then
        UI._toggles["Enable Freecam"](Camera.Enabled)
    end
    if UI._toggles["Recording Indicator"] then
        UI._toggles["Recording Indicator"](Recording.IsRecording)
    end
end

function UI.Toggle()
    UI.IsOpen = not UI.IsOpen
    UI.ScreenGui.Enabled = UI.IsOpen
end

return UI
