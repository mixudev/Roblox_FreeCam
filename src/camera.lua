-- src/camera.lua
-- Drone‑style cinematic camera core logic (spring physics + modes)

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Config = _G.Freecam.require("config")
local SpeedManager = _G.Freecam.require("speed")
local Input = _G.Freecam.require("input")
local Spring = _G.Freecam.require("spring")

local CameraManager = {
    Enabled = false,
    _renderSteppedConn = nil,
    _panConn = nil,

    -- character freeze cache
    _cacheHRPAnchor = nil,
    _cachedWalkSpeed = nil,
    _cachedJumpPower = nil,
    _cachedPlatformStand = nil,

    -- cinematic
    Mode = Config.Camera.Cinematic.DefaultMode,
    ModeTarget = nil,
    Modes = Config.Camera.Cinematic.Modes,
    ModeRadius = 15,
    _staticCFrame = nil,
    _dollyTime = 0,

    ShakeEnabled = false,
    DepthAmount = Config.Camera.Cinematic.DepthEffect,
    _dof = nil
}

local currentCamera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- springs
local velSpring = Spring.new(1, 0.4, 1.2, Vector3.zero)
local rotSpring = Spring.new(1, 0.6, 2, Vector2.zero)
local fovSpring = Spring.new(1, 0.5, 2, Config.Camera.FOV)

local stateRot = Vector2.new()
local panDeltaMouse = Vector2.new()

local function Clamp(x, min, max)
    return x < min and min or x > max and max or x
end

local function LockMouse(state)
    UserInputService.MouseBehavior = state and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = not state
end

local function Panned(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseMovement then
        panDeltaMouse = Vector2.new(-input.Delta.Y, -input.Delta.X)
    end
end

-- API -------------------------------------------------------
function CameraManager.SetMode(mode)
    if type(mode) ~= "string" then return end
    for _, opt in ipairs(CameraManager.Modes) do
        if opt == mode then
            CameraManager.Mode = mode
            if mode == "Static" and currentCamera then
                CameraManager._staticCFrame = currentCamera.CFrame
            end
            if mode == "DollyZoom" then
                CameraManager._dollyTime = 0
            end
            return
        end
    end
    warn("[Freecam] tried to set unknown camera mode:",mode)
end

function CameraManager.SetModeTarget(instance)
    CameraManager.ModeTarget = instance
end

function CameraManager.SetFOV(val)
    Config.Camera.FOV = Clamp(val, 5, 120)
    if CameraManager.Enabled then
        fovSpring.target = Config.Camera.FOV
    end
end

function CameraManager.SetShake(state)
    CameraManager.ShakeEnabled = state and true or false
end

function CameraManager.SetDepthEffect(amount)
    CameraManager.DepthAmount = Clamp(amount,0,1)
    if CameraManager.DepthAmount > 0 then
        if not CameraManager._dof then
            CameraManager._dof = Instance.new("DepthOfFieldEffect")
            CameraManager._dof.Parent = Lighting
        end
        CameraManager._dof.Enabled = true
        CameraManager._dof.NearIntensity = CameraManager.DepthAmount
        CameraManager._dof.FarIntensity = CameraManager.DepthAmount
    elseif CameraManager._dof then
        CameraManager._dof.Enabled = false
    end
end

local function ApplyShake(cf)
    if not CameraManager.ShakeEnabled then return cf end
    local mag = Config.Camera.ShakeMagnitude
    local t = tick()
    local noise = Vector3.new(math.noise(t*10)-0.5, math.noise(t*11)-0.5, math.noise(t*12)-0.5) * mag
    return cf * CFrame.new(noise)
end

-- camera update loop ------------------------------------------------
local function UpdateCamera(dt)
    if not CameraManager.Enabled then return end

    local camCFrame = currentCamera.CFrame
    local moveVector = Input.MovementVector
    local dx, dy, dz = moveVector.X, moveVector.Y, moveVector.Z

    local targetSpeed = SpeedManager.CurrentSpeed * Input.GetSpeedMultiplier()
    local damping = math.clamp(1.5 - SpeedManager.Smoothness, 0.1, 2)
    velSpring.damping = damping

    local scaledDeltaMouse = panDeltaMouse * SpeedManager.RotationSensitivity

    velSpring.target = Vector3.new(dx, dy, dz) * targetSpeed
    rotSpring.target = scaledDeltaMouse
    fovSpring.target = Clamp(Config.Camera.FOV, 5, 120)

    if CameraManager.Mode == "SlowMotion" then
        dt = dt * 0.25
    end

    local fov = fovSpring:Update(dt)
    local dPos = velSpring:Update(dt) * Vector3.new(1,0.75,1) * 3
    local NM_ZOOM = math.tan(fov * math.pi/360)
    local dRot = rotSpring:Update(dt) * (Vector2.new(0.85,1)/128 * NM_ZOOM)

    panDeltaMouse = Vector2.new()
    stateRot = stateRot + dRot
    stateRot = Vector2.new(Clamp(stateRot.X, -1.5, 1.5), stateRot.Y)

    local newCFrame = CFrame.new(camCFrame.Position)
        * CFrame.Angles(0, stateRot.Y, 0)
        * CFrame.Angles(stateRot.X, 0, 0)
        * CFrame.new(dPos)

    if CameraManager.Mode == "SmoothFollow" and CameraManager.ModeTarget then
        local tgt = CameraManager.ModeTarget
        local goal = tgt.CFrame * CFrame.new(0,5,15)
        newCFrame = newCFrame:Lerp(goal, SpeedManager.Smoothness)
    elseif CameraManager.Mode == "Orbit" and CameraManager.ModeTarget then
        local tgt = CameraManager.ModeTarget.Position
        CameraManager._orbitAngle = (CameraManager._orbitAngle or 0) + dt * 0.5
        local offset = Vector3.new(math.cos(CameraManager._orbitAngle),0,math.sin(CameraManager._orbitAngle)) * CameraManager.ModeRadius
        newCFrame = CFrame.new(tgt + offset) * CFrame.lookAt(tgt + offset, tgt)
    elseif CameraManager.Mode == "DollyZoom" and CameraManager.ModeTarget then
        CameraManager._dollyTime = CameraManager._dollyTime + dt
        fovSpring.target = 20 + 50 * (0.5 + 0.5 * math.sin(CameraManager._dollyTime))
    elseif CameraManager.Mode == "Static" then
        newCFrame = CameraManager._staticCFrame or newCFrame
    end

    newCFrame = ApplyShake(newCFrame)

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

    -- freeze character (visible)
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            CameraManager._cachedWalkSpeed = humanoid.WalkSpeed
            CameraManager._cachedJumpPower = humanoid.JumpPower
            CameraManager._cachedPlatformStand = humanoid.PlatformStand
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.PlatformStand = true
        end
        local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            CameraManager._cacheHRPAnchor = hrp.Anchored
            hrp.Anchored = true
        end
    end

    LockMouse(true)
    CameraManager._panConn = UserInputService.InputChanged:Connect(Panned)
    CameraManager._renderSteppedConn = RunService.RenderStepped:Connect(UpdateCamera)
end

function CameraManager.Disable()
    if not CameraManager.Enabled then return end
    CameraManager.Enabled = false

    if CameraManager._renderSteppedConn then
        CameraManager._renderSteppedConn:Disconnect()
        CameraManager._renderSteppedConn = nil
    end
    if CameraManager._panConn then
        CameraManager._panConn:Disconnect()
        CameraManager._panConn = nil
    end

    currentCamera.CameraType = Enum.CameraType.Custom
    currentCamera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") or nil
    currentCamera.FieldOfView = Config.Camera.FOV

    -- restore character
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = CameraManager._cachedWalkSpeed or humanoid.WalkSpeed
            humanoid.JumpPower = CameraManager._cachedJumpPower or humanoid.JumpPower
            humanoid.PlatformStand = CameraManager._cachedPlatformStand or false
        end
        local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and CameraManager._cacheHRPAnchor ~= nil then
            hrp.Anchored = CameraManager._cacheHRPAnchor
            CameraManager._cacheHRPAnchor = nil
        end
    end

    LockMouse(false)
end

function CameraManager.Toggle()
    if CameraManager.Enabled then CameraManager.Disable() else CameraManager.Enable() end
end

function CameraManager.Cleanup()
    CameraManager.Disable()
    if CameraManager._dof then
        CameraManager._dof:Destroy()
        CameraManager._dof = nil
    end
end

return CameraManager
