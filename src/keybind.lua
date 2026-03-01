-- src/keybind.lua
-- Centralized keybind manager

local UserInputService = game:GetService("UserInputService")
local Config = _G.FreecamModules and _G.FreecamModules.Config or require(script.Parent.config)

local KeybindManager = {
    _callbacks = {}
}

-- Checks if a modifier key (if specified) is currently being held down
local function IsModifierHeld(modifier)
    if not modifier then return true end
    return UserInputService:IsKeyDown(modifier)
end

function KeybindManager.Init()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
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

return KeybindManager
