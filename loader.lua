-- loader.lua
-- Main executor entry point script
-- Note: Replace the URL below with your actual repository RAW URL
local GITHUB_RAW_BASE = "https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/main/src/"

-- If testing locally from workspace, you might require() but this is for HttpGet executor injection
local ModulesToLoad = {
    "config",
    "speed",
    "keybind",
    "input",
    "nametag",
    "recording",
    "camera",
    "ui",
    "bootstrap"
}

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Prevent double injection
if _G.FreecamModules and _G.FreecamModules.Loaded then
    warn("Freecam System is already loaded!")
    if _G.FreecamModules.UI then
        _G.FreecamModules.UI.Toggle() -- Toggle UI if they try to execute again
    end
    return
end

_G.FreecamModules = {}
local loaderGui = Instance.new("ScreenGui", game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui)
loaderGui.Name = "FreecamLoading"
local loaderText = Instance.new("TextLabel", loaderGui)
loaderText.Size = UDim2.new(0, 300, 0, 50)
loaderText.Position = UDim2.new(0.5, -150, 0, 50)
loaderText.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
loaderText.TextColor3 = Color3.fromRGB(255, 255, 255)
loaderText.Font = Enum.Font.GothamMedium
loaderText.TextSize = 16
loaderText.Text = "Downloading Freecam..."
local corner = Instance.new("UICorner", loaderText)
corner.CornerRadius = UDim.new(0, 8)

local successCount = 0

for _, modName in ipairs(ModulesToLoad) do
    loaderText.Text = "Downloading " .. modName .. ".lua..."
    task.wait() -- Small yield to show progression
    
    local success, response = pcall(function()
        return game:HttpGet(GITHUB_RAW_BASE .. modName .. ".lua")
    end)
    
    if success and response then
        local envFunc, err = loadstring(response)
        if envFunc then
            _G.FreecamModules[modName] = envFunc()
            successCount = successCount + 1
        else
            warn("Syntax error in " .. modName .. ": " .. tostring(err))
        end
    else
        warn("Failed to download: " .. modName)
    end
end

if successCount == #ModulesToLoad then
    loaderText.Text = "Initializing..."
    _G.FreecamModules.bootstrap.Init()
    _G.FreecamModules.Loaded = true
    loaderText.Text = "Loaded Successfully!"
    task.wait(1)
else
    loaderText.Text = "Failed to load all modules."
    task.wait(2)
end

loaderGui:Destroy()
