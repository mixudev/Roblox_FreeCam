-- debug_freecam.lua
-- Quick diagnostic tool for Freecam loading issues
-- Paste this into executor after Freecam fails to load

print("\n=== FREECAM DIAGNOSTIC REPORT ===\n")

-- Check _G.Freecam setup
if not _G.Freecam then
    print("[ERROR] _G.Freecam not initialized!")
    print("       Make sure loader.lua was executed first")
    return
end

print("[CHECK] _G.Freecam exists: " .. tostring(_G.Freecam))
print("[CHECK] isRemote mode: " .. tostring(_G.Freecam.isRemote))
print("[CHECK] baseUrl: " .. (_G.Freecam.baseUrl or "NOT SET"))

-- Check cached modules
print("\n--- Cached Modules ---")
local cache = _G.Freecam.cache or {}
local cached_count = 0
for modName, mod in pairs(cache) do
    print("  [✓] " .. modName .. ": " .. type(mod))
    cached_count = cached_count + 1
end
print("Total cached: " .. cached_count .. " modules")

-- Check loading errors
print("\n--- Load Errors ---")
local errors = _G.Freecam.loadErrors or {}
if next(errors) == nil then
    print("  [✓] No errors")
else
    for modName, errMsg in pairs(errors) do
        print("  [✗] " .. modName)
        print("      Error: " .. errMsg)
    end
end

-- Check if modules have required functions
print("\n--- Module Function Check ---")
local modules_to_check = {"config", "camera", "ui", "bootstrap"}
for _, modName in ipairs(modules_to_check) do
    local mod = cache[modName]
    if mod then
        local has_functions = {}
        for k, v in pairs(mod) do
            if type(v) == "function" then
                table.insert(has_functions, k)
            end
        end
        print("  [" .. modName .. "] Functions: " .. table.concat(has_functions, ", "))
    else
        print("  [" .. modName .. "] NOT LOADED")
    end
end

-- Test require function
print("\n--- Testing require() function ---")
local test = _G.Freecam.require("config")
if test then
    print("  [✓] require('config') works")
    print("    Type: " .. type(test))
    print("    Keys: " .. table.concat(type(test) == "table" and {table.unpack(next(test) and {"...has data"} or {"empty"})} or {"not-a-table"}, ", "))
else
    print("  [✗] require('config') failed")
end

-- System status
print("\n--- System Status ---")
print("  Loaded: " .. tostring(_G.Freecam.Loaded or false))
print("  UI available: " .. tostring(_G.Freecam.UI ~= nil))

print("\n=== END REPORT ===\n")

-- Provide instructions
if cached_count == 0 then
    print("PROBLEM: No modules loaded at all")
    print("FIX: Check that loader.lua executed successfully and library URLs are correct")
elseif next(errors) ~= nil then
    print("PROBLEM: Some modules failed to load")
    print("FIX: Check error messages above, verify module files exist and are valid Lua")
elseif not _G.Freecam.Loaded then
    print("PROBLEM: Modules loaded but system not initialized")
    print("FIX: Try running: _G.Freecam.require('bootstrap').Init()")
else
    print("✓ System appears to be loaded successfully")
    print("TRY: Open the UI with Shift+L")
end