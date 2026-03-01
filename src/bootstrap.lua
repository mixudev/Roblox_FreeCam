-- src/bootstrap.lua
-- Orchestrator module. Initializes all systems and wires up connections.

local Bootstrap = {}

function Bootstrap.Init()
    local Config = _G.FreecamModules.Config
    local KeybindManager = _G.FreecamModules.Keybind
    local Input = _G.FreecamModules.Input
    local Camera = _G.FreecamModules.Camera
    local Nametag = _G.FreecamModules.Nametag
    local Recording = _G.FreecamModules.Recording
    local UI = _G.FreecamModules.UI

    -- 1. Initialize Subsystems
    KeybindManager.Init()
    Input.Init()
    Camera.Init()
    Nametag.Init()
    Recording.Init()
    UI.Init()

    -- 2. Register Hotkeys based on config
    
    -- RightCtrl toggles UI
    KeybindManager.Register(Config.Keybinds.ToggleUI, nil, function()
        UI.Toggle()
    end)

    -- Toggle Freecam
    KeybindManager.Register(Config.Keybinds.ToggleFreecam, Config.Keybinds.ToggleFreecamModifier, function()
        Camera.Toggle()
        UI.UpdateToggles()
    end)

    -- Toggle Recording
    KeybindManager.Register(Config.Keybinds.ToggleRecording, Config.Keybinds.ToggleRecordingModifier, function()
        Recording.Toggle()
        UI.UpdateToggles()
    end)

    -- Open UI by default
    UI.IsOpen = true
end

return Bootstrap
