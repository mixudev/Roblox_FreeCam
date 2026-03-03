-- src/input.lua
-- Manages continuous input states for the freecam movement

local UserInputService = game:GetService("UserInputService")
local Config = _G.Freecam.require("config")
local SpeedManager = _G.Freecam.require("speed")

local Input = {
    MovementVector = Vector3.zero,
    MouseDelta = Vector2.zero,
    IsBoosting = false,
    IsPrecision = false,
    _activeKeys = {},
    _connections = {}
}

local function UpdateMovementVector()
    local x, y, z = 0, 0, 0
    local keys = Config.Keybinds

    if Input._activeKeys[keys.MoveRight] then x = x + 1 end
    if Input._activeKeys[keys.MoveLeft] then x = x - 1 end
    
    if Input._activeKeys[keys.MoveUp] then y = y + 1 end
    if Input._activeKeys[keys.MoveDown] then y = y - 1 end
    
    if Input._activeKeys[keys.MoveBackward] then z = z + 1 end
    if Input._activeKeys[keys.MoveForward] then z = z - 1 end

    Input.MovementVector = Vector3.new(x, y, z)
end

function Input.Init()
    local conn1 = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Input._activeKeys[input.KeyCode] = true
            
            if input.KeyCode == Config.Keybinds.Boost then
                Input.IsBoosting = true
            elseif input.KeyCode == Config.Keybinds.Precision then
                Input.IsPrecision = true
            end

            UpdateMovementVector()
        end
    end)
    table.insert(Input._connections, conn1)

    local conn2 = UserInputService.InputEnded:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Input._activeKeys[input.KeyCode] = nil
            
            if input.KeyCode == Config.Keybinds.Boost then
                Input.IsBoosting = false
            elseif input.KeyCode == Config.Keybinds.Precision then
                Input.IsPrecision = false
            end

            UpdateMovementVector()
        end
    end)
    table.insert(Input._connections, conn2)

    local conn3 = UserInputService.InputChanged:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local scrollDir = input.Position.Z
            SpeedManager.AdjustSpeed(scrollDir * Config.Camera.ScrollZoomSpeed)
        end
    end)
    table.insert(Input._connections, conn3)
end

-- Get mouse delta safely
function Input.GetMouseDelta()
    local delta = UserInputService:GetMouseDelta()
    return delta
end

function Input.GetSpeedMultiplier()
    if Input.IsBoosting then
        return SpeedManager.BoostMultiplier
    elseif Input.IsPrecision then
        return SpeedManager.PrecisionMultiplier
    end
    return 1
end

function Input.Cleanup()
    for _, conn in ipairs(Input._connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    Input._connections = {}
    Input._activeKeys = {}
    Input.MovementVector = Vector3.zero
    Input.IsBoosting = false
    Input.IsPrecision = false
end

return Input
