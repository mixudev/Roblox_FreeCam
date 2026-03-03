-- LOCAL SETUP GUIDE
-- If you're using local injection (game scripts), follow this guide

--[[
=== LOCAL INJECTION SETUP ===

Step 1: Create the Folder Structure
- In Studio, go to ServerScriptService (or ServerStorage)
- Create a Folder named "FreecamSystem"
- Inside FreecamSystem, create a Folder named "src"
- Structure should look like:
  
  ServerScriptService
  └── FreecamSystem (Folder)
      ├── loader (ModuleScript) -- paste loader.lua here
      └── src (Folder)
          ├── bootstrap (ModuleScript)
          ├── camera (ModuleScript)
          ├── config (ModuleScript)
          ├── input (ModuleScript)
          ├── keybind (ModuleScript)
          ├── nametag (ModuleScript)
          ├── recording (ModuleScript)
          ├── speed (ModuleScript)
          ├── spring (ModuleScript)
          ├── ui (ModuleScript)
          └── visuals (ModuleScript)

Step 2: Paste Module Contents
- Copy each .lua file from src/ folder
- Paste its content into corresponding ModuleScript in game

Step 3: Create Main Entry Script
- Create a Script (NOT ModuleScript) in ServerScriptService
- Paste this code:

    local loader = require(game:WaitForChild("ServerScriptService"):WaitForChild("FreecamSystem"):WaitForChild("loader"))
    _G.Freecam.require = loader.require
    loader.bootstrap.Init()

OR for LocalScript (runs on client side):

    local loader = require(game:WaitForChild("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FreecamLoader"))
    _G.Freecam.require = loader.require
    _G.Freecam.require("bootstrap").Init()

Step 4: Test
- Run the game
- Check Output window for [Freecam] messages
- Press Shift+L to toggle UI

=== COMMON ERRORS ===

Error: "Module path not found"
  → Check folder names are EXACT (case-sensitive on some systems)
  → Ensure ModuleScripts are in correct folders

Error: "Execution error"
  → Check Console for full error message
  → Run debug_freecam.lua to diagnose
  → Verify all module dependencies are loaded

Error: "UI doesn't appear"
  → Make sure to press Shift+L (capital L with Shift held)
  → Check that ScreenGui is being created (look in Explorer)
  → Run debug_freecam.lua to verify modules loaded

]]--

-- OPTIONAL: Simple test to check if modules are set up correctly
print("=== Freecam Local Setup Check ===")

local scriptService = game:GetService("ServerScriptService")
local freecamFolder = scriptService:FindFirstChild("FreecamSystem")

if freecamFolder then
    print("[OK] FreecamSystem folder found")
    
    local srcFolder = freecamFolder:FindFirstChild("src")
    if srcFolder then
        print("[OK] src folder found")
        
        local requiredModules = {
            "bootstrap", "camera", "config", "input", "keybind",
            "nametag", "recording", "speed", "spring", "ui", "visuals"
        }
        
        local found = 0
        for _, modName in ipairs(requiredModules) do
            local mod = srcFolder:FindFirstChild(modName)
            if mod then
                print("[OK] " .. modName .. " found")
                found = found + 1
            else
                print("[MISSING] " .. modName)
            end
        end
        
        print("\nFound: " .. found .. "/" .. #requiredModules .. " modules")
    else
        print("[ERROR] src folder not found inside FreecamSystem!")
    end
else
    print("[ERROR] FreecamSystem folder not found in ServerScriptService!")
    print("       Create it manually or use remote loading instead")
end