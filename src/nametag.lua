-- src/nametag.lua
-- Hides player display names, usernames, and overhead UI (BillboardGuis)

local Players = game:GetService("Players")

local Nametag = {
    IsHidden = false,
    _connections = {},
    _cache = {} -- Store previous DisplayDistanceTypes
}

local function HideCharacterNametags(character)
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        Nametag._cache[humanoid] = humanoid.DisplayDistanceType
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    -- Hide all BillboardGuis inside character
    for _, child in ipairs(character:GetDescendants()) do
        if child:IsA("BillboardGui") then
            Nametag._cache[child] = child.Enabled
            child.Enabled = false
        end
    end
end

local function RestoreCharacterNametags(character)
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and Nametag._cache[humanoid] ~= nil then
        humanoid.DisplayDistanceType = Nametag._cache[humanoid]
        Nametag._cache[humanoid] = nil
    end

    for _, child in ipairs(character:GetDescendants()) do
        if child:IsA("BillboardGui") and Nametag._cache[child] ~= nil then
            child.Enabled = Nametag._cache[child]
            Nametag._cache[child] = nil
        end
    end
end

local function HandlePlayer(player)
    if player.Character then
        if Nametag.IsHidden then
            HideCharacterNametags(player.Character)
        end
    end
    
    local conn = player.CharacterAdded:Connect(function(character)
        if Nametag.IsHidden then
            task.wait(0.5) -- Wait for humanoid to load
            HideCharacterNametags(character)
        end
    end)
    table.insert(Nametag._connections, conn)
end

function Nametag.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        HandlePlayer(player)
    end

    table.insert(Nametag._connections, Players.PlayerAdded:Connect(function(player)
        HandlePlayer(player)
    end))
end

function Nametag.Toggle(state)
    if state == nil then
        Nametag.IsHidden = not Nametag.IsHidden
    else
        Nametag.IsHidden = state
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if Nametag.IsHidden then
            HideCharacterNametags(player.Character)
        else
            RestoreCharacterNametags(player.Character)
        end
    end
end

function Nametag.Cleanup()
    -- Disconnect events
    for _, conn in ipairs(Nametag._connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    Nametag._connections = {}
    
    -- Restore all nametags
    if Nametag.IsHidden then
        Nametag.Toggle(false)
    end
end

return Nametag
