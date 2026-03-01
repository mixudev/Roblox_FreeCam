-- src/ui.lua
-- Professional draggable sidebar dashboard

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Config = _G.FreecamModules and _G.FreecamModules.Config or require(script.Parent.config)
local Camera = _G.FreecamModules and _G.FreecamModules.Camera or require(script.Parent.camera)
local SpeedManager = _G.FreecamModules and _G.FreecamModules.Speed or require(script.Parent.speed)
local Nametag = _G.FreecamModules and _G.FreecamModules.Nametag or require(script.Parent.nametag)
local Recording = _G.FreecamModules and _G.FreecamModules.Recording or require(script.Parent.recording)

local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    IsOpen = false,
    _toggles = {}
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

local function CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UI.TextColor
    label.Font = Config.UI.Font
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Config.UI.AccentColor
    valueLabel.Font = Config.UI.Font
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(1, 0, 0, 8)
    bg.Position = UDim2.new(0, 0, 0, 28)
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
        
        -- formatting hack for decimals vs ints
        if max <= 10 then
            valueLabel.Text = string.format("%.2f", val)
        else
            valueLabel.Text = tostring(math.floor(val))
        end
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

local function CreateToggle(parent, text, defaultState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UI.TextColor
    label.Font = Config.UI.Font
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 44, 0, 24)
    toggleBg.Position = UDim2.new(1, -44, 0.5, -12)
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

function UI.Init()
    local sg = Instance.new("ScreenGui")
    sg.Name = "FreecamDashboard"
    sg.DisplayOrder = 100000
    sg.ResetOnSpawn = false
    local success = pcall(function() sg.Parent = CoreGui end)
    if not success then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    
    UI.ScreenGui = sg

    local mf = Instance.new("Frame")
    mf.Name = "MainFrame"
    mf.Size = UDim2.new(0, 300, 0, 450)
    mf.Position = UDim2.new(1, -320, 0.5, -225)
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
    
    -- Bottom rect to fix corner overlap
    local topbarPatch = Instance.new("Frame")
    topbarPatch.Size = UDim2.new(1, 0, 0, 10)
    topbarPatch.Position = UDim2.new(0, 0, 1, -10)
    topbarPatch.BackgroundColor3 = Config.UI.SectionColor
    topbarPatch.BorderSizePixel = 0
    topbarPatch.Parent = topbar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FREECAM DASHBOARD"
    title.TextColor3 = Config.UI.TextColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topbar

    MakeDraggable(topbar, mf)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -30, 1, -60)
    scroll.Position = UDim2.new(0, 15, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Config.UI.SectionColor
    scroll.Parent = mf

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scroll

    -- Populate Sections
    CreateToggle(scroll, "Enable Freecam", false, function(state)
        if state then Camera.Enable() else Camera.Disable() end
    end)
    CreateToggle(scroll, "Hide Player Nametags", false, function(state)
        Nametag.Toggle(state)
    end)
    CreateToggle(scroll, "Recording Indicator", false, function(state)
        if state ~= Recording.IsRecording then Recording.Toggle() end
    end)

    -- Sliders
    CreateSlider(scroll, "Movement Speed", 1, Config.Camera.MaxSpeed, Config.Camera.BaseSpeed, SpeedManager.SetSpeed)
    CreateSlider(scroll, "Smoothness (Inertia)", 0, 0.99, Config.Camera.Smoothness, SpeedManager.SetSmoothness)
    CreateSlider(scroll, "Rotation Sensitivity", 0.1, 2, Config.Camera.RotationSensitivity, SpeedManager.SetRotationSensitivity)
    CreateSlider(scroll, "Boost Multiplier", 1, 10, Config.Camera.BoostMultiplier, SpeedManager.SetBoostMultiplier)

    local helpText = Instance.new("TextLabel")
    helpText.Size = UDim2.new(1, 0, 0, 100)
    helpText.BackgroundTransparency = 1
    helpText.Text = "Shortcuts:\nShift+L: Freecam Toggle\nShift+G: Recording\nRightCtrl: Hide GUI\nScroll: Zoom Speed"
    helpText.TextColor3 = Config.UI.SubTextColor
    helpText.Font = Config.UI.Font
    helpText.TextSize = 12
    helpText.TextYAlignment = Enum.TextYAlignment.Top
    helpText.Parent = scroll

    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
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
