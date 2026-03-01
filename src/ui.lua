-- src/ui.lua
-- Futuristic Professional Dashboard with Close & Minimize Logic

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
    ConfirmFrame = nil,
    IsOpen = true,
    IsMinimized = false,
    _toggles = {},
    _pages = {},
    _navButtons = {},
    _currentPage = nil
}

-- Local helpers
local function MakeDraggable(topbar, frame)
    local dragging, dragInput, dragStart, startPos

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
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 235)
    label.Font = Config.UI.Font
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 50, 0, 26)
    toggleBg.Position = UDim2.new(1, -65, 0.5, -13)
    toggleBg.BackgroundColor3 = defaultState and Config.UI.AccentColor or Color3.fromRGB(40, 40, 45)
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = toggleBg

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = defaultState and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = toggleBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local state = defaultState
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function setState(newState)
        state = newState
        local goalCircle = {Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)}
        local goalBg = {BackgroundColor3 = state and Config.UI.AccentColor or Color3.fromRGB(40, 40, 45)}
        TweenService:Create(circle, tweenInfo, goalCircle):Play()
        TweenService:Create(toggleBg, tweenInfo, goalBg):Play()
        callback(state)
    end

    toggleBg.MouseButton1Click:Connect(function() setState(not state) end)
    UI._toggles[text] = setState
end

local function CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 235)
    label.Font = Config.UI.Font
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 25)
    valueLabel.Position = UDim2.new(1, -65, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Config.UI.AccentColor
    valueLabel.Font = Config.UI.Font
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(1, -30, 0, 6)
    bg.Position = UDim2.new(0, 15, 0, 35)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.Parent = container
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Config.UI.AccentColor
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

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
    sg.Name = "FreecamDashboardUI"
    sg.DisplayOrder = 100000
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = CoreGui end)
    if not (sg.Parent) then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    UI.ScreenGui = sg

    -- Main UI Frame (Glassmorphism look)
    local mf = Instance.new("Frame")
    mf.Name = "MainFrame"
    -- Make it much wider and taller
    mf.Size = UDim2.new(0, 600, 0, 400)
    mf.Position = UDim2.new(1, -640, 0.5, -200)
    mf.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    mf.BackgroundTransparency = 0.1 -- slight glass effect
    mf.ClipsDescendants = true
    mf.Parent = sg
    UI.MainFrame = mf

    local mfCorner = Instance.new("UICorner")
    mfCorner.CornerRadius = UDim.new(0, 12)
    mfCorner.Parent = mf
    
    local mfStroke = Instance.new("UIStroke")
    mfStroke.Color = Color3.fromRGB(45, 45, 50)
    mfStroke.Thickness = 1
    mfStroke.Parent = mf

    -- Topbar
    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 45)
    topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    topbar.Parent = mf
    
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 12)
    topCorner.Parent = topbar
    
    local topbarPatch = Instance.new("Frame")
    topbarPatch.Size = UDim2.new(1, 0, 0, 12)
    topbarPatch.Position = UDim2.new(0, 0, 1, -12)
    topbarPatch.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    topbarPatch.BorderSizePixel = 0
    topbarPatch.Parent = topbar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FREECAM STUDIO"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topbar

    MakeDraggable(topbar, mf)

    -- Window Controls Container
    local windowControls = Instance.new("Frame")
    windowControls.Size = UDim2.new(0, 80, 1, 0)
    windowControls.Position = UDim2.new(1, -80, 0, 0)
    windowControls.BackgroundTransparency = 1
    windowControls.Parent = topbar

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 40, 1, 0)
    minBtn.Position = UDim2.new(0, 0, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minBtn.TextSize = 24
    minBtn.Font = Enum.Font.GothamMedium
    minBtn.Parent = windowControls
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 1, 0)
    closeBtn.Position = UDim2.new(0, 40, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(250, 80, 80)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = windowControls

    -- Animations for Topbar buttons
    minBtn.MouseEnter:Connect(function() minBtn.TextColor3 = Color3.new(1,1,1) end)
    minBtn.MouseLeave:Connect(function() minBtn.TextColor3 = Color3.fromRGB(200,200,200) end)
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(250, 80, 80); closeBtn.BackgroundTransparency=0; closeBtn.TextColor3 = Color3.new(1,1,1) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundTransparency=1; closeBtn.TextColor3 = Color3.fromRGB(250,80,80) end)

    minBtn.MouseButton1Click:Connect(function()
        UI.IsMinimized = not UI.IsMinimized
        if UI.IsMinimized then
            TweenService:Create(mf, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 45)}):Play()
        else
            TweenService:Create(mf, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 400)}):Play()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        UI.ShowCloseConfirmation()
    end)

    -- Content Body
    local cf = Instance.new("Frame")
    cf.Name = "ContentBody"
    cf.Size = UDim2.new(1, 0, 1, -45)
    cf.Position = UDim2.new(0, 0, 0, 45)
    cf.BackgroundTransparency = 1
    cf.Parent = mf
    UI.ContentFrame = cf

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 160, 1, 0)
    sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = cf
    
    local sbStroke = Instance.new("Frame")
    sbStroke.Size = UDim2.new(0, 1, 1, 0)
    sbStroke.Position = UDim2.new(1, 0, 0, 0)
    sbStroke.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    sbStroke.BorderSizePixel = 0
    sbStroke.Parent = sidebar

    local sbLayout = Instance.new("UIListLayout")
    sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sbLayout.Parent = sidebar

    -- Page Container
    local pageContainer = Instance.new("Frame")
    pageContainer.Size = UDim2.new(1, -160, 1, 0)
    pageContainer.Position = UDim2.new(0, 160, 0, 0)
    pageContainer.BackgroundTransparency = 1
    pageContainer.Parent = cf

    local function MakePage(name)
        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, 0, 1, -20)
        frame.Position = UDim2.new(0, 0, 0, 10)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 4
        frame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
        frame.Visible = false
        frame.Parent = pageContainer

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 5)
        layout.Parent = frame

        UI._pages[name] = frame

        local navBtn = Instance.new("TextButton")
        navBtn.Size = UDim2.new(1, 0, 0, 50)
        navBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
        navBtn.BorderSizePixel = 0
        navBtn.Text = "   " .. name
        navBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
        navBtn.Font = Enum.Font.GothamMedium
        navBtn.TextSize = 14
        navBtn.TextXAlignment = Enum.TextXAlignment.Left
        navBtn.Parent = sidebar
        
        local navHighlight = Instance.new("Frame")
        navHighlight.Size = UDim2.new(0, 4, 1, 0)
        navHighlight.BackgroundColor3 = Config.UI.AccentColor
        navHighlight.BorderSizePixel = 0
        navHighlight.Visible = false
        navHighlight.Parent = navBtn

        navBtn.MouseButton1Click:Connect(function()
            for pgName, pgFrame in pairs(UI._pages) do
                pgFrame.Visible = (pgName == name)
            end
            for _, btn in pairs(UI._navButtons) do
                btn.TextColor3 = Color3.fromRGB(140, 140, 150)
                btn.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
                btn:FindFirstChildOfClass("Frame").Visible = false
            end
            navBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            navBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
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
    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, 0, 0, 60)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = pgCamera

    local speedTitle = Instance.new("TextLabel")
    speedTitle.Size = UDim2.new(1, 0, 0, 20)
    speedTitle.Position = UDim2.new(0, 15, 0, 5)
    speedTitle.BackgroundTransparency = 1
    speedTitle.Text = "Movement Speed Presets"
    speedTitle.TextColor3 = Color3.fromRGB(230,230,235)
    speedTitle.Font = Config.UI.Font
    speedTitle.TextSize = 14
    speedTitle.TextXAlignment = Enum.TextXAlignment.Left
    speedTitle.Parent = speedRow

    local speedBtnsContainer = Instance.new("Frame")
    speedBtnsContainer.Size = UDim2.new(1, -30, 0, 30)
    speedBtnsContainer.Position = UDim2.new(0, 15, 0, 30)
    speedBtnsContainer.BackgroundTransparency = 1
    speedBtnsContainer.Parent = speedRow

    local sbcLayout = Instance.new("UIListLayout")
    sbcLayout.FillDirection = Enum.FillDirection.Horizontal
    sbcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sbcLayout.Padding = UDim.new(0, 10)
    sbcLayout.Parent = speedBtnsContainer

    -- Translated absolute speed scales to Spring physics SpeedModifiers
    local speeds = {
        {"Walk", 1},
        {"Normal", 4},
        {"Fast", 12},
        {"Cinematic", 0.5}
    }

    local speedUIBtns = {}
    for i, data in ipairs(speeds) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        btn.Text = data[1]
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.Parent = speedBtnsContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Color3.fromRGB(50, 50, 55)

        if data[2] == Config.Camera.BaseSpeed or (i==2) then
            btn.BackgroundColor3 = Config.UI.AccentColor
            stroke.Color = Config.UI.AccentColor
            SpeedManager.SetSpeed(data[2]) -- apply default
        end

        btn.MouseButton1Click:Connect(function()
            SpeedManager.SetSpeed(data[2])
            
            for _, b in pairs(speedUIBtns) do
                b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                b:FindFirstChild("UIStroke").Color = Color3.fromRGB(50, 50, 55)
            end
            btn.BackgroundColor3 = Config.UI.AccentColor
            stroke.Color = Config.UI.AccentColor
        end)
        table.insert(speedUIBtns, btn)
    end

    CreateSlider(pgCamera, "Rotation Sensitivity", 0.1, 2, Config.Camera.RotationSensitivity, SpeedManager.SetRotationSensitivity)
    CreateSlider(pgCamera, "Boost Multiplier (Shift)", 1.5, 5, Config.Camera.BoostMultiplier, SpeedManager.SetBoostMultiplier)
    -- This controls the spring damping
    CreateSlider(pgCamera, "Spring Smoothness", 0.1, 1, Config.Camera.Smoothness, SpeedManager.SetSmoothness)

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
    
    local helpTextContainer = Instance.new("Frame")
    helpTextContainer.Size = UDim2.new(1, -30, 0, 160)
    helpTextContainer.Position = UDim2.new(0, 15, 0, 5)
    helpTextContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    helpTextContainer.Parent = pgSettings
    Instance.new("UICorner", helpTextContainer).CornerRadius = UDim.new(0, 8)

    local helpText = Instance.new("TextLabel")
    helpText.Size = UDim2.new(1, -20, 1, -20)
    helpText.Position = UDim2.new(0, 10, 0, 10)
    helpText.BackgroundTransparency = 1
    helpText.Text = "KEYBOARD CONTROLS:\n\n• Shift+L : Toggle Freecam Mode\n• Shift+G : Screen Recording Toggle\n• RightCtrl : Hide GUI Completely\n\nFREECAM CONTROLS:\n• W/A/S/D/Q/E : Move around\n• Shift : Boost speed multiplier\n• Right Click + Drag : Rotate Camera\n• Mouse Scroll : Adjust FOV\n\nMade for Roblox Executors."
    helpText.TextColor3 = Color3.fromRGB(180, 180, 190)
    helpText.Font = Enum.Font.Gotham
    helpText.TextSize = 13
    helpText.TextXAlignment = Enum.TextXAlignment.Left
    helpText.TextYAlignment = Enum.TextYAlignment.Top
    helpText.Parent = helpTextContainer

    -- Set Default Tab
    UI._navButtons["Camera"]:FindFirstChildOfClass("Frame").Visible = true
    UI._navButtons["Camera"].TextColor3 = Color3.new(1,1,1)
    UI._navButtons["Camera"].BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    pgCamera.Visible = true

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

function UI.ShowCloseConfirmation()
    if UI.ConfirmFrame then return end

    local confBg = Instance.new("Frame")
    confBg.Size = UDim2.new(1, 0, 1, 0)
    confBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    confBg.BackgroundTransparency = 1
    confBg.ZIndex = 50
    confBg.Parent = UI.MainFrame
    UI.ConfirmFrame = confBg

    local confBox = Instance.new("Frame")
    confBox.Size = UDim2.new(0, 300, 0, 150)
    confBox.Position = UDim2.new(0.5, -150, 0.5, -75)
    confBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    confBox.ZIndex = 51
    confBox.Parent = confBg
    Instance.new("UICorner", confBox).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", confBox)
    stroke.Color = Color3.fromRGB(60, 60, 70)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 80)
    txt.BackgroundTransparency = 1
    txt.Text = "Unload Freecam?\n\nThis will completely remove all features from the game."
    txt.TextColor3 = Color3.new(1,1,1)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14
    txt.ZIndex = 52
    txt.Parent = confBox

    local btnYes = Instance.new("TextButton")
    btnYes.Size = UDim2.new(0, 100, 0, 35)
    btnYes.Position = UDim2.new(0.5, -110, 1, -50)
    btnYes.BackgroundColor3 = Color3.fromRGB(250, 80, 80)
    btnYes.Text = "Kill Script"
    btnYes.TextColor3 = Color3.new(1,1,1)
    btnYes.Font = Enum.Font.GothamBold
    btnYes.TextSize = 14
    btnYes.ZIndex = 52
    btnYes.Parent = confBox
    Instance.new("UICorner", btnYes).CornerRadius = UDim.new(0, 6)

    local btnNo = Instance.new("TextButton")
    btnNo.Size = UDim2.new(0, 100, 0, 35)
    btnNo.Position = UDim2.new(0.5, 10, 1, -50)
    btnNo.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btnNo.Text = "Cancel"
    btnNo.TextColor3 = Color3.new(1,1,1)
    btnNo.Font = Enum.Font.GothamMedium
    btnNo.TextSize = 14
    btnNo.ZIndex = 52
    btnNo.Parent = confBox
    Instance.new("UICorner", btnNo).CornerRadius = UDim.new(0, 6)

    TweenService:Create(confBg, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()

    btnNo.MouseButton1Click:Connect(function()
        local tw = TweenService:Create(confBg, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        tw:Play()
        tw.Completed:Wait()
        confBg:Destroy()
        UI.ConfirmFrame = nil
    end)

    btnYes.MouseButton1Click:Connect(function()
        -- Attempt to call via bootstrap unloading flow to ensure cross-module cleanup
        local Bootstrap = _G.Freecam.require("bootstrap")
        if Bootstrap and Bootstrap.Unload then
            Bootstrap.Unload()
        else
            -- Failsafe self destruct
            UI.Cleanup()
        end
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
    if UI.ScreenGui then
        UI.ScreenGui.Enabled = UI.IsOpen
    end
end

function UI.Cleanup()
    if UI.ScreenGui then
        UI.ScreenGui:Destroy()
        UI.ScreenGui = nil
    end
end

return UI
