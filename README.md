# Professional Executor Freecam System

A complete drone-style, cinematic freecam tool designed specifically for Roblox executor injection via `loadstring`. 

## 📁 Required GitHub Structure

Your repository should be structured as follows before running the dynamic loader:

```
/
├── loader.lua              # EXECUTOR ENTRY POINT
│
└── src/
    ├── config.lua          # Centralized configuration mapping
    ├── keybind.lua         # Shortcut management
    ├── input.lua           # Continuous movement vector tracking
    ├── speed.lua           # Speed / scaling data variables
    ├── recording.lua       # Roblox screen recording toggles
    ├── nametag.lua         # Humanoid DisplayName/Overhead hiding
    ├── camera.lua          # Core cinematic drone calculation
    ├── ui.lua              # Dashboard interface rendering
    └── bootstrap.lua       # Wiring and system initialization
```

## 🚀 Setup Instructions

1. Create a GitHub Repository and upload the `src` folder containing all `.lua` modules.
2. Open `loader.lua`.
3. Locate line `4` (`local GITHUB_RAW_BASE = "https://raw.githubusercontent.com/..."`).
4. Replace the URL with your raw github user content link pointing to the `src` folder (ensure it ends with a slash `/`).
5. Upload `loader.lua` to the root of your repository or keep it as your executor script.

## 🎮 Executor Usage Example

Users only need to copy/paste the `loader.lua` logic or a direct URL into their executor:

```lua
-- Example execution using your raw file URL
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourName/YourRepo/main/loader.lua"))()
```

### Shortcuts & Controls

Once loaded, use these shortcuts:
* **SHIFT + L**: Toggle Freecam On/Off
* **W A S D**: Move Forward/Left/Back/Right
* **Q / E**: Move Down / Up
* **Scroll Wheel**: Adjust base speed
* **Hold SHIFT**: Speed Boost multiplier
* **Hold CTRL**: Precision SLOW multiplier
* **SHIFT + G**: Toggle Screen Recording indicator & F12 capture
* **Right Control**: Toggle Sidebar Dashboard UI open/closed

## 🛠️ Maintenance Guide

* **Configuration**: Use `config.lua` to adjust UI colors, base camera speeds, max speeds, FOV, and hotkeys. The `config.lua` acts as the single source of truth.
* **Adding New Sections to UI**: Open `ui.lua` and use the helper functions `CreateSlider` or `CreateToggle` just before the `scroll.CanvasSize` calculation to automatically append new interactive UI parameters. 
* **Changing Modifiers**: To implement new modifiers in `speed.lua`, expose setter functions and call them from `ui.lua`. Use `SpeedManager.GetSomething` inside `camera.lua` `UpdateCamera()`.
* **Dependencies**: Be cautious adding new dependencies. In Roblox executor context, they are fetched dynamically via `HttpGet`. Always update `ModulesToLoad` array inside `loader.lua` if you add a new `.lua` file inside `src`. Do not use circular dependencies.
