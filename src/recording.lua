-- src/recording.lua
-- Manages Roblox's built-in recording shortcut triggering and shows a visual indicator

local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local Recording = {
    IsRecording = false,
    IndicatorFrame = nil,
    DotTween = nil,
    _timerActive = false  -- flag untuk menghentikan loop timer saat Cleanup dipanggil
}

local function CreateIndicator()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FreecamRecordingIndicator"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 99999
    
    -- Try to put it in CoreGui to bypass regular cleanup and UI hiding, 
    -- fallback to PlayerGui if executor doesn't support CoreGui.
    local success = pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not success then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 150, 0, 40)
    indicator.Position = UDim2.new(1, -170, 0, 20)
    indicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    indicator.BackgroundTransparency = 0.5
    indicator.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = indicator

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 12, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    dot.Parent = indicator

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(1, -40, 1, 0)
    text.Position = UDim2.new(0, 40, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = "REC 00:00"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 16
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = indicator

    screenGui.Enabled = false
    Recording.IndicatorFrame = screenGui
    
    -- Animation setup
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    Recording.DotTween = TweenService:Create(dot, tweenInfo, {BackgroundTransparency = 0.8})
    Recording.DotTween:Play()

    -- Basic timer (berhenti otomatis saat _timerActive = false)
    task.spawn(function()
        local seconds = 0
        while Recording._timerActive do
            task.wait(1)
            if not Recording._timerActive then break end  -- double-check setelah wait
            if Recording.IsRecording then
                seconds = seconds + 1
                local m = math.floor(seconds / 60)
                local s = seconds % 60
                text.Text = string.format("REC %02d:%02d", m, s)
            else
                seconds = 0
                text.Text = "REC 00:00"
            end
        end
    end)
end

function Recording.Init()
    Recording._timerActive = true
    CreateIndicator()
end

function Recording.Toggle()
    Recording.IsRecording = not Recording.IsRecording
    
    -- Simulate F12 keypress to toggle actual Roblox recording
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F12, false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F12, false, game)
    end)

    if Recording.IndicatorFrame then
        Recording.IndicatorFrame.Enabled = Recording.IsRecording
    end
end

function Recording.Cleanup()
    Recording._timerActive = false  -- menghentikan loop timer
    
    if Recording.IsRecording then
        Recording.Toggle() -- Toggle off
    end
    
    if Recording.DotTween then
        Recording.DotTween:Cancel()
        Recording.DotTween = nil
    end

    if Recording.IndicatorFrame then
        Recording.IndicatorFrame:Destroy()
        Recording.IndicatorFrame = nil
    end
end

return Recording
