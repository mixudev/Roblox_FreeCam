-- src/visuals.lua
-- Visual enhancements: Night Vision and Player Highlights (ESP)

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Visuals = {
    NightVisionEnabled = false,
    HighlightsEnabled = false,
    _cacheAmbient = nil,
    _cacheOutdoorAmbient = nil,
    _cacheBrightness = nil,
    _cacheClockTime = nil,
    _cacheGlobalShadows = nil,
    
    _highlights = {},
    _connections = {}
}

-- == NIGHT VISION == --
function Visuals.ToggleNightVision(state)
    if state == nil then state = not Visuals.NightVisionEnabled end
    Visuals.NightVisionEnabled = state

    if Visuals.NightVisionEnabled then
        -- Backup lighting settings
        Visuals._cacheAmbient = Lighting.Ambient
        Visuals._cacheOutdoorAmbient = Lighting.OutdoorAmbient
        Visuals._cacheBrightness = Lighting.Brightness
        Visuals._cacheClockTime = Lighting.ClockTime
        Visuals._cacheGlobalShadows = Lighting.GlobalShadows

        -- Apply Night Vision
        Lighting.Ambient = Color3.fromRGB(150, 150, 150)
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.ClockTime = 14
    else
        -- Restore lighting settings
        if Visuals._cacheAmbient then
            Lighting.Ambient = Visuals._cacheAmbient
            Lighting.OutdoorAmbient = Visuals._cacheOutdoorAmbient
            Lighting.Brightness = Visuals._cacheBrightness
            Lighting.ClockTime = Visuals._cacheClockTime
            Lighting.GlobalShadows = Visuals._cacheGlobalShadows
        end
    end
end

-- == PLAYER HIGHLIGHTS (ESP) == --
local function CreateHighlight(player)
    if player == Players.LocalPlayer then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "FreecamHighlight"
    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = player.Character
    
    local folder = Workspace:FindFirstChild("FreecamHighlights")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "FreecamHighlights"
        folder.Parent = Workspace
    end
    
    highlight.Parent = folder
    Visuals._highlights[player] = highlight
end

local function RemoveHighlight(player)
    if Visuals._highlights[player] then
        Visuals._highlights[player]:Destroy()
        Visuals._highlights[player] = nil
    end
end

local function ConnectPlayerHighlight(player)
    if player.Character and Visuals.HighlightsEnabled then
        CreateHighlight(player)
    end
    
    local conn = player.CharacterAdded:Connect(function(character)
        task.wait(0.5) -- wait for Rig to load
        if Visuals.HighlightsEnabled then
            RemoveHighlight(player)
            CreateHighlight(player)
        end
    end)
    table.insert(Visuals._connections, conn)
end

function Visuals.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        ConnectPlayerHighlight(player)
    end

    table.insert(Visuals._connections, Players.PlayerAdded:Connect(function(player)
        ConnectPlayerHighlight(player)
    end))
    
    table.insert(Visuals._connections, Players.PlayerRemoving:Connect(function(player)
        RemoveHighlight(player)
    end))
end

function Visuals.ToggleHighlights(state)
    if state == nil then state = not Visuals.HighlightsEnabled end
    Visuals.HighlightsEnabled = state

    if Visuals.HighlightsEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            CreateHighlight(player)
        end
    else
        for player, hl in pairs(Visuals._highlights) do
            RemoveHighlight(player)
        end
    end
end

function Visuals.Cleanup()
    -- Disconnect events
    for _, conn in ipairs(Visuals._connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    Visuals._connections = {}

    -- Revert visual changes
    if Visuals.NightVisionEnabled then
        Visuals.ToggleNightVision(false)
    end
    
    if Visuals.HighlightsEnabled then
        Visuals.ToggleHighlights(false)
    end
    
    -- Destroy remnant highlights folder just in case
    local folder = Workspace:FindFirstChild("FreecamHighlights")
    if folder then folder:Destroy() end
end

return Visuals
