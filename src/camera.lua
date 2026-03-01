-- src/camera.lua
-- Drone-style cinematic camera core logic

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Config = _G.Freecam.require("config")
local SpeedManager = _G.Freecam.require("speed")
local Input = _G.Freecam.require("input")

local CameraManager = {
    Enabled = false,
    _renderSteppedConn = nil,
    _cameraCFrame = CFrame.new(),
    _cameraFocus = CFrame.new(),
    _velocity = Vector3.zero,
    _pan = Vector2.zero
}

local currentCamera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local function LockMouse(state)
    if state then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

local function UpdateCamera(dt)
    if not CameraManager.Enabled then return end

    -- Extract Delta Mouse for panning
    local mouseDelta = Input.GetMouseDelta()
    
    -- Update Pan Angles using RotationSensitivity
    CameraManager._pan = CameraManager._pan + Vector2.new(-mouseDelta.Y, -mouseDelta.X) * (SpeedManager.RotationSensitivity * 0.01)
     CameraManager._pan = Vector2.new(
        math.clamp(CameraManager._pan.X, -math.rad(89), math.rad(89)), -- Pitch clamp to avoid flipping
        CameraManager._pan.Y -- Yaw is unlimited
    )

    local targetRot = CFrame.fromEulerAnglesYXZ(CameraManager._pan.X, CameraManager._pan.Y, 0)

    -- Calculate Movement Input
    local moveVector = Input.MovementVector
    
    -- Apply Speed and Multipliers
    local targetSpeed = SpeedManager.CurrentSpeed * Input.GetSpeedMultiplier()
    
    -- Transform local moveVector to world space based on current camera rotation
    local targetVelocity = targetRot:VectorToWorldSpace(moveVector) * targetSpeed

    -- Apply Smoothness / Inertia using Lerp (1 = no lerp/infinite inertia, 0 = instant/no inertia)
    -- We invert smoothness so 0 is instant and 1 is heavily smoothed
    local smoothingFactor = 1 - SpeedManager.Smoothness
    -- Apply dt to make it frame-rate independent
    local t = math.clamp(smoothingFactor * dt * 60, 0, 1)
    
    CameraManager._velocity = CameraManager._velocity:Lerp(targetVelocity, t)

    -- Position calculation
    local newPos = CameraManager._cameraCFrame.Position + (CameraManager._velocity * dt)
    CameraManager._cameraCFrame = targetRot + newPos

    -- Update Workspace Camera
    currentCamera.FieldOfView = Config.Camera.FOV
    currentCamera.CFrame = CameraManager._cameraCFrame
end

function CameraManager.Init()
    -- Grab latest camera
    currentCamera = Workspace.CurrentCamera
    
    -- Reset on respawn cleanly
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
    CameraManager._cameraCFrame = currentCamera.CFrame
    
    local rx, ry, rz = currentCamera.CFrame:ToEulerAnglesYXZ()
    CameraManager._pan = Vector2.new(rx, ry)
    CameraManager._velocity = Vector3.zero

    currentCamera.CameraType = Enum.CameraType.Scriptable
    
    -- Hide character while in freecam locally
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
    
    CameraManager._renderSteppedConn = RunService.RenderStepped:Connect(UpdateCamera)
end

function CameraManager.Disable()
    if not CameraManager.Enabled then return end
    CameraManager.Enabled = false

    if CameraManager._renderSteppedConn then
        CameraManager._renderSteppedConn:Disconnect()
        CameraManager._renderSteppedConn = nil
    end

    currentCamera.CameraType = Enum.CameraType.Custom
    currentCamera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") or nil

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
    if CameraManager.Enabled then
        CameraManager.Disable()
    else
        CameraManager.Enable()
    end
end

return CameraManager
