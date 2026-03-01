-- loader.lua
-- Main executor entry point script

local HttpService = game:GetService("HttpService")

local isRemote = false
local baseUrl = "https://raw.githubusercontent.com/mixudev/Roblox_FreeCam/main/src"
local ScriptFolder = nil

if script and script.Parent then
    isRemote = false
    ScriptFolder = script.Parent
else
    isRemote = true
end

-- Prevent double injection
if _G.Freecam and _G.Freecam.Loaded then
    warn("Freecam System is already loaded!")
    if _G.Freecam.UI then
        _G.Freecam.UI.Toggle()
    end
    return
end

local cache = {}

local function require_module(path)
    if cache[path] then
        return cache[path]
    end

    local module

    if isRemote then
        local url = baseUrl .. "/" .. path .. ".lua"
        local success, res = pcall(function()
            if type(game.HttpGet) == "function" then
                return game:HttpGet(url)
            else
                return HttpService:GetAsync(url)
            end
        end)

        if not success or not res or type(res) ~= "string" or #res < 5 then
            warn("Failed to download from GitHub: " .. url)
            return nil
        end
        
        local content = res
        if type(content) == "string" and content:sub(1,3) == "\239\187\191" then
            content = content:sub(4)
        end

        local fn, err = loadstring(content, path)
        if not fn then
            warn("Failed to parse module: " .. path .. "\nError: " .. tostring(err))
            return nil
        end

        local okExec, resultExec = pcall(fn)
        if not okExec then
            warn("Module execution error: " .. path .. "\nError: " .. tostring(resultExec))
            return nil
        end
        module = resultExec
    else
        local part = ScriptFolder
        for segment in path:gmatch("[^/]+") do
            part = part:FindFirstChild(segment)
            if not part then return nil end
        end
        module = require(part)
    end

    cache[path] = module
    return module
end

do
    local g = _G or getfenv and getfenv(0) or {}
    g.Freecam = g.Freecam or {}
    g.Freecam.require = require_module
    g.Freecam.isRemote = isRemote
    g.Freecam.baseUrl = baseUrl
end

-- Load all modules
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

local ModulesToLoad = {
    "config",
    "speed",
    "keybind",
    "input",
    "nametag",
    "recording",
    "visuals",
    "camera",
    "ui"
}

-- Pre-load core files first to populate cache
local successCount = 0
for _, modName in ipairs(ModulesToLoad) do
    loaderText.Text = "Downloading " .. modName .. ".lua..."
    task.wait()
    local mod = require_module(modName)
    if mod then
        successCount = successCount + 1
    end
end

if successCount == #ModulesToLoad then
    loaderText.Text = "Initializing..."
    local Bootstrap = require_module("bootstrap")
    if Bootstrap then
        Bootstrap.Init()
        _G.Freecam.Loaded = true
        _G.Freecam.UI = require_module("ui")
        loaderText.Text = "Loaded Successfully!"
    else
        loaderText.Text = "Failed to bootstrap."
    end
    task.wait(1)
else
    loaderText.Text = "Failed to load all modules."
    task.wait(2)
end

loaderGui:Destroy()
