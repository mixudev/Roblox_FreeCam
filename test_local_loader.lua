-- test_local_loader.lua
-- Debug script for testing local module loading
-- Use this to diagnose loading issues when injecting locally

print("=== Freecam Local Loader Test ===")

-- Check if script exists
if script and script.Parent then
    print("[OK] script exists: " .. tostring(script))
    print("[OK] script.Parent exists: " .. tostring(script.Parent))
else
    warn("[ERROR] script or script.Parent not found - this is loadstring injection")
    warn("[ERROR] For local injection, place load script in ServerScriptService or game root")
    return
end

-- Test require system
print("\n--- Testing Require System ---")

local function test_require_module(path)
    local part = script.Parent
    print("Searching for: " .. path)
    print("  Starting at: " .. tostring(part) .. " (" .. part.Name .. ")")
    
    for segment in path:gmatch("[^/]+") do
        part = part:FindFirstChild(segment)
        print("  -> Looking for segment: " .. segment .. " -> " .. tostring(part))
        if not part then
            print("[ERROR] Segment not found!")
            return nil
        end
    end
    
    if part then
        print("[OK] Found module at: " .. tostring(part))
        local ok, result = pcall(function()
            return require(part)
        end)
        if ok then
            print("[OK] Module loaded successfully")
            return result
        else
            print("[ERROR] Module execution failed: " .. tostring(result))
            return nil
        end
    end
    return nil
end

-- Test loading each module
local modules_to_test = {
    "config",
    "spring",
    "speed",
    "keybind",
    "input",
}

local loaded = 0
for _, modName in ipairs(modules_to_test) do
    print("\n[Testing] " .. modName)
    local result = test_require_module("src/" .. modName)
    if result then
        loaded = loaded + 1
        print("[SUCCESS] " .. modName .. " loaded")
    else
        print("[FAILED] " .. modName .. " not loaded")
    end
end

print("\n=== Test Summary ===")
print("Loaded: " .. loaded .. "/" .. #modules_to_test)

if loaded == #modules_to_test then
    print("[SUCCESS] All test modules loaded!")
    print("\nNow try running the main loader.lua script")
else
    print("[FAILED] Some modules failed to load")
    print("\nMake sure your folder structure is:")
    print("  script.Parent/")
    print("    ├─ src/")
    print("    │  ├─ config.lua")
    print("    │  ├─ spring.lua")
    print("    │  └─ ... (other modules)")
    print("    └─ loader.lua")
end