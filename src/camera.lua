-- src/camera.lua
-- Drone-style cinematic camera core logic (Spring Mathematics)

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Config = _G.Freecam.require("config")
local SpeedManager = _G.Freecam.require("speed")
local Input = _G.Freecam.require("input")
local Spring = _G.Freecam.require("spring")

local CameraManager = {
    Enabled = false,
    _renderSteppedConn = nil,
    _cacheHRPAnchor = nil
}

local currentCamera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Spring Instances (Mass, Damping, Stiffness)
local velSpring = Spring.new(1, 0.4, 1.2, Vector3.zero) -- Lower damping means glides longer
local rotSpring = Spring.new(1, 0.6, 2, Vector2.zero)   -- High stiffness for snappy rotation
local fovSpring = Spring.new(1, 0.5, 2, Config.Camera.FOV)

local stateRot = Vector2.new()
local panDeltaMouse = Vector2.new()

-- Constants equivalent to sample Freecam
local LVEL_GAIN = Vector3.new(1, 0.75, 1) * 3  -- World velocity translation multiplier
local RVEL_GAIN = Vector2.new(0.85, 1) / 128   -- Mouse to pan gain

local function Clamp(x, min, max)
    return x < min and min or x > max and max or x
end

local function LockMouse(state)
    if state then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

local function Panned(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Delta
        panDeltaMouse = Vector2.new(-delta.Y, -delta.X)
    end
end
local _panConn = nil

local function UpdateCamera(dt)
    if not CameraManager.Enabled then return end

    local camCFrame = currentCamera.CFrame

    -- Translate movement input into a vector
    local moveVector = Input.MovementVector
    
    -- Invert Z-axis because -1 is forward in Input module but we want it forward relative to camera's LookVector
    local dx = moveVector.X
    local dy = moveVector.Y
    local dz = moveVector.Z

    local targetSpeed = SpeedManager.CurrentSpeed * Input.GetSpeedMultiplier()

    -- Adjust Spring variables based on SpeedManager Smoothness
    local damping = math.clamp(1.5 - SpeedManager.Smoothness, 0.1, 2)
    velSpring.damping = damping
    
    -- Mouse delta scaling using rotation sensitivity slider
    local scaledDeltaMouse = panDeltaMouse * SpeedManager.RotationSensitivity

    velSpring.target = Vector3.new(dx, dy, dz) * targetSpeed
    rotSpring.target = scaledDeltaMouse
    fovSpring.target = Clamp(Config.Camera.FOV, 5, 120)

    local fov = fovSpring:Update(dt)
    
    -- Local space positional step
    local dPos = velSpring:Update(dt) * LVEL_GAIN
    -- Rotational Step
    local NM_ZOOM = math.tan(fov * math.pi/360)
    local dRot = rotSpring:Update(dt) * (RVEL_GAIN * NM_ZOOM)

    -- Reset delta each frame so it only accumulates upon mouse movement (Panned event)
    panDeltaMouse = Vector2.new()

    stateRot = stateRot + dRot
    stateRot = Vector2.new(Clamp(stateRot.X, -1.5, 1.5), stateRot.Y)

    local newCFrame = CFrame.new(camCFrame.Position) 
        * CFrame.Angles(0, stateRot.Y, 0) 
        * CFrame.Angles(stateRot.X, 0, 0) 
        * CFrame.new(dPos)

    currentCamera.CFrame = newCFrame
    currentCamera.FieldOfView = fov
end

function CameraManager.Init()
    currentCamera = Workspace.CurrentCamera
    
    localPlayer.CharacterAdded:Connect(function()
        if CameraManager.Enabled then
            CameraManager.Disable()
        end
    end)
end

function CameraManager.Enable()
    if CameraManager.Enabled then return end
    CameraManager.Enabled = true

    currentCamera = Workspace.CurrentCamera
    currentCamera.CameraType = Enum.CameraType.Scriptable
    
    local lookVector = currentCamera.CFrame.LookVector
    stateRot = Vector2.new(
        math.asin(lookVector.Y),
        math.atan2(-lookVector.Z, lookVector.X) - math.pi/2
    )

    velSpring.target, velSpring.velocity, velSpring.position = Vector3.zero, Vector3.zero, Vector3.zero
    rotSpring.target, rotSpring.velocity, rotSpring.position = Vector2.zero, Vector2.zero, Vector2.zero
    fovSpring.target, fovSpring.velocity, fovSpring.position = currentCamera.FieldOfView, 0, currentCamera.FieldOfView
    panDeltaMouse = Vector2.new()

    -- Hide character
    if localPlayer.Character then
        local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            CameraManager._cacheHRPAnchor = hrp.Anchored
            hrp.Anchored = true
        end

        local iter; iter = function(inst)
            for _, v in ipairs(inst:GetChildren()) do
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = 1
                end
                iter(v)
            end
        end
        iter(localPlayer.Character)
    end

    LockMouse(true)
    _panConn = UserInputService.InputChanged:Connect(Panned)
    CameraManager._renderSteppedConn = RunService.RenderStepped:Connect(UpdateCamera)
end

function CameraManager.Disable()
    if not CameraManager.Enabled then return end
    CameraManager.Enabled = false

    if CameraManager._renderSteppedConn then
        CameraManager._renderSteppedConn:Disconnect()
        CameraManager._renderSteppedConn = nil
    end
    if _panConn then
        _panConn:Disconnect()
        _panConn = nil
    end

    currentCamera.CameraType = Enum.CameraType.Custom
    currentCamera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") or nil
    currentCamera.FieldOfView = Config.Camera.FOV

    -- Restore character visibility & anchor
    if localPlayer.Character then
        local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and CameraManager._cacheHRPAnchor ~= nil then
            hrp.Anchored = CameraManager._cacheHRPAnchor
            CameraManager._cacheHRPAnchor = nil
        end

        local iter; iter = function(inst)
            for _, v in ipairs(inst:GetChildren()) do
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = 0
                end
                iter(v)
            end
        end
        iter(localPlayer.Character)
    end

    LockMouse(false)
end

function CameraManager.Toggle()
    if CameraManager.Enabled then CameraManager.Disable() else CameraManager.Enable() end
end

function CameraManager.Cleanup()
    CameraManager.Disable()
end

return CameraManager
