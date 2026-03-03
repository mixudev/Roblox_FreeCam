-- loader.lua
-- Main executor entry point script - Supports both remote (GitHub) and local injection

local HttpService = game:GetService("HttpService")

local isRemote = false
local baseUrl = "https://raw.githubusercontent.com/mixudev/Roblox_FreeCam/main/src"
local ScriptFolder = nil

-- AUTO DETECT: Script-based vs loadstring-based injection
if script and script.Parent and script:IsDescendantOf(game) then
    isRemote = false
    ScriptFolder = script.Parent
else
    isRemote = true
end

-- Prevent double injection
if _G.Freecam and _G.Freecam.Loaded then
    warn("[Freecam] System is already loaded!")
    if _G.Freecam.UI then
        _G.Freecam.UI.Toggle()
    end
    return
end

local cache = {}
local loadErrors = {}

local function require_module(path)
    -- Check cache first
    if cache[path] then
        return cache[path]
    end

    local module = nil
    local errorMsg = ""

    if isRemote then
        -- REMOTE: Load from GitHub via HttpGet
        local url = baseUrl .. "/" .. path .. ".lua"
        local success, res = pcall(function()
            if type(game.HttpGet) == "function" then
                return game:HttpGet(url)
            else
                return HttpService:GetAsync(url)
            end
        end)

        if not success then
            errorMsg = "HttpGet failed for " .. url .. ": " .. tostring(res)
        elseif not res or type(res) ~= "string" or #res < 5 then
            errorMsg = "Empty or invalid response from " .. url
        else
            -- Remove BOM if present
            local content = res
            if type(content) == "string" and content:sub(1,3) == "\239\187\191" then
                content = content:sub(4)
            end

            -- Parse and execute
            local fn, parseErr = loadstring(content, path)
            if not fn then
                errorMsg = "Parse error in " .. path .. ": " .. tostring(parseErr)
            else
                local okExec, resultExec = pcall(fn)
                if not okExec then
                    errorMsg = "Execution error in " .. path .. ": " .. tostring(resultExec)
                else
                    module = resultExec
                end
            end
        end
    else
        -- LOCAL: Load from script instances (game hierarchy)
        local part = ScriptFolder
        if not part then
            errorMsg = "ScriptFolder not found (script.Parent is nil)"
        else
            for segment in path:gmatch("[^/]+") do
                part = part:FindFirstChild(segment)
                if not part then
                    errorMsg = "Module path not found: " .. path .. " (missing segment: " .. segment .. ")"
                    break
                end
            end

            if not errorMsg and part then
                local ok, result = pcall(function()
                    return require(part)
                end)
                if not ok then
                    errorMsg = "Require error for " .. path .. ": " .. tostring(result)
                else
                    module = result
                end
            end
        end
    end

    if not module then
        loadErrors[path] = errorMsg
        warn("[Freecam] Failed to load module '" .. path .. "': " .. errorMsg)
        return nil
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
    g.Freecam.loadErrors = loadErrors
    g.Freecam.cache = cache
end

-- Load all modules
local loaderGui = Instance.new("ScreenGui", game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui)
loaderGui.Name = "FreecamLoading"
local loaderText = Instance.new("TextLabel", loaderGui)
loaderText.Size = UDim2.new(0, 400, 0, 60)
loaderText.Position = UDim2.new(0.5, -200, 0, 50)
loaderText.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
loaderText.TextColor3 = Color3.fromRGB(255, 255, 255)
loaderText.Font = Enum.Font.GothamMedium
loaderText.TextSize = 16
loaderText.TextWrapped = true
loaderText.Text = "Freecam Loading...\n(Remote: " .. tostring(isRemote) .. ")"
local corner = Instance.new("UICorner", loaderText)
corner.CornerRadius = UDim.new(0, 8)

local ModulesToLoad = {
    "config",
    "spring",
    "speed",
    "keybind",
    "input",
    "nametag",
    "recording",
    "visuals",
    "camera",
    "ui",
    "bootstrap"
}

-- Load all modules in dependency order
print("[Freecam] Starting module loading... (Mode: " .. (isRemote and "REMOTE" or "LOCAL") .. ")")

local successCount = 0
local failedModules = {}

for i, modName in ipairs(ModulesToLoad) do
    loaderText.Text = "Loading " .. modName .. "...\n(" .. i .. "/" .. #ModulesToLoad .. ")"
    task.wait(0.05)
    
    local mod = require_module(modName)
    if mod then
        print("[Freecam] ✓ Loaded: " .. modName)
        successCount = successCount + 1
    else
        print("[Freecam] ✗ Failed: " .. modName)
        table.insert(failedModules, modName)
    end
end

loaderText.Text = "Load Status: " .. successCount .. "/" .. #ModulesToLoad

if successCount == #ModulesToLoad then
    loaderText.Text = "Initializing system..."
    task.wait(0.3)
    
    local Bootstrap = require_module("bootstrap")
    if Bootstrap and Bootstrap.Init then
        local initOk, initErr = pcall(function()
            Bootstrap.Init()
        end)
        
        if initOk then
            _G.Freecam.Loaded = true
            _G.Freecam.UI = require_module("ui")
            loaderText.Text = "Freecam loaded successfully!"
            print("[Freecam] System initialized successfully")
        else
            loaderText.Text = "Init error: " .. tostring(initErr)
            print("[Freecam] Bootstrap.Init() failed: " .. tostring(initErr))
        end
    else
        loaderText.Text = "Bootstrap not found"
        print("[Freecam] Bootstrap module load failed")
    end
    task.wait(1.5)
else
    loaderText.Text = "Error: Failed to load modules:\n" .. table.concat(failedModules, ", ")
    print("[Freecam] Failed modules: " .. table.concat(failedModules, ", "))
    print("[Freecam] Load errors: " .. HttpService:JSONEncode(loadErrors))
    task.wait(3)
end

loaderGui:Destroy()
