-- src/speed.lua
-- Real-time adjustable speed manager

local Config = _G.FreecamModules and _G.FreecamModules.Config or require(script.Parent.config)

local SpeedManager = {
    CurrentSpeed = Config.Camera.BaseSpeed,
    RotationSensitivity = Config.Camera.RotationSensitivity,
    BoostMultiplier = Config.Camera.BoostMultiplier,
    PrecisionMultiplier = Config.Camera.PrecisionMultiplier,
    Smoothness = Config.Camera.Smoothness
}

-- Clamps speed bounds
function SpeedManager.SetSpeed(val)
    SpeedManager.CurrentSpeed = math.clamp(val, 1, Config.Camera.MaxSpeed)
end

-- Used by mouse scroll to quickly adjust speed
function SpeedManager.AdjustSpeed(delta)
    SpeedManager.SetSpeed(SpeedManager.CurrentSpeed + delta)
end

function SpeedManager.SetRotationSensitivity(val)
    SpeedManager.RotationSensitivity = val
end

function SpeedManager.SetBoostMultiplier(val)
    SpeedManager.BoostMultiplier = val
end

function SpeedManager.SetSmoothness(val)
    SpeedManager.Smoothness = math.clamp(val, 0, 0.99)
end

return SpeedManager
