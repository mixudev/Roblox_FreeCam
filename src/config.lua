-- src/config.lua
-- Centralized configuration for the Freecam System

local Config = {
    -- Keybinds
    Keybinds = {
        ToggleFreecam = Enum.KeyCode.L,
        ToggleFreecamModifier = Enum.KeyCode.LeftShift,

        ToggleRecording = Enum.KeyCode.G,
        ToggleRecordingModifier = Enum.KeyCode.LeftShift,

        -- UI visibility controls
        ToggleUI = Enum.KeyCode.L,
        ToggleUIModifier = Enum.KeyCode.LeftShift,

        ToggleSidebar = Enum.KeyCode.Tab,  -- show/hide sidebar

        MoveForward = Enum.KeyCode.W,
        MoveBackward = Enum.KeyCode.S,
        MoveLeft = Enum.KeyCode.A,
        MoveRight = Enum.KeyCode.D,
        MoveUp = Enum.KeyCode.E,
        MoveDown = Enum.KeyCode.Q,

        Boost = Enum.KeyCode.LeftShift,
        Precision = Enum.KeyCode.LeftControl
    },

    -- Camera Defaults
    Camera = {
        BaseSpeed = 50,           -- Studs per second
        MaxSpeed = 200,           -- Maximum allowed BaseSpeed
        RotationSensitivity = 0.5,-- Mouse movement degree multiplier
        BoostMultiplier = 3,      -- Speed multiplier when holding Boost key
        PrecisionMultiplier = 0.2,-- Speed multiplier when holding Precision key
        Smoothness = 0.85,        -- Value between 0 (instant) to 1 (infinite inertia)
        ScrollZoomSpeed = 10,     -- Speed added/removed per scroll tick
        FOV = 70,                 -- Default Field of View
        Acceleration = 8,         -- Higher means snappier acceleration/deceleration
        ShakeMagnitude = 0.5,     -- Intensity used by camera shake

        Cinematic = {
            Modes = {"Free","SmoothFollow","Orbit","DollyZoom","Static","SlowMotion"},
            DefaultMode = "Free",
            DepthEffect = 0          -- 0..1, intensity of depth simulation
        }
    },

    -- UI Theme
    UI = {
        BackgroundColor = Color3.fromRGB(24, 24, 28),
        SectionColor = Color3.fromRGB(32, 32, 38),
        AccentColor = Color3.fromRGB(88, 101, 242),
        TextColor = Color3.fromRGB(255, 255, 255),
        SubTextColor = Color3.fromRGB(180, 180, 180),
        CornerRadius = UDim.new(0, 8),
        Font = Enum.Font.GothamMedium,
        AnimationDuration = 0.3
    }
}

return Config
