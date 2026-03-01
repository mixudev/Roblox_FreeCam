-- src/bootstrap.lua
-- Orchestrator module. Initializes all systems and wires up connections.

local Bootstrap = {}

function Bootstrap.Init()
    local Config = _G.Freecam.require("config")
    local KeybindManager = _G.Freecam.require("keybind")
    local Input = _G.Freecam.require("input")
    local Camera = _G.Freecam.require("camera")
    local Nametag = _G.Freecam.require("nametag")
    local Recording = _G.Freecam.require("recording")
    local Visuals = _G.Freecam.require("visuals")
    local UI = _G.Freecam.require("ui")

    -- 1. Initialize Subsystems
    KeybindManager.Init()
    Input.Init()
    Camera.Init()
    Nametag.Init()
    Recording.Init()
    Visuals.Init()
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
