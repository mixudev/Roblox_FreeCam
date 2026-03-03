-- src/keybind.lua
-- Centralized keybind manager

local UserInputService = game:GetService("UserInputService")
local Config = _G.Freecam.require("config")

local KeybindManager = {
    _callbacks = {},
    _connections = {}
}

-- Checks if a modifier key (if specified) is currently being held down
local function IsModifierHeld(modifier)
    if not modifier then return true end
    return UserInputService:IsKeyDown(modifier)
end

function KeybindManager.Init()
    local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local callbacks = KeybindManager._callbacks[input.KeyCode]
            if callbacks then
                for _, cbData in ipairs(callbacks) do
                    if IsModifierHeld(cbData.modifier) then
                        cbData.callback()
                    end
                end
            end
        end
    end)
    table.insert(KeybindManager._connections, conn)
end

-- Registers a callback for a specific keycode, optionally requiring a modifier key
function KeybindManager.Register(keyCode, modifierKeyCode, callback)
    if not KeybindManager._callbacks[keyCode] then
        KeybindManager._callbacks[keyCode] = {}
    end
    table.insert(KeybindManager._callbacks[keyCode], {
        modifier = modifierKeyCode,
        callback = callback
    })
end

function KeybindManager.Cleanup()
    for _, conn in ipairs(KeybindManager._connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    KeybindManager._connections = {}
    KeybindManager._callbacks = {}
end

return KeybindManager
