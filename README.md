# Professional Freecam Studio v2.0

A production-ready cinematic freecam system for Roblox games. Features responsive UI, advanced camera modes, smooth physics, and professional visual effects.

## ✨ Key Features

- **Responsive Dashboard UI** - Adaptive layout that works on all screen sizes
- **Avatar Retention** - Character stays visible and accessible while in freecam
- **Cinematic Camera Modes** - Free Flight, Smooth Follow, Orbit, Dolly Zoom, Static, Slow Motion
- **Professional Movement** - Spring-based physics with adjustable smoothness & acceleration
- **Advanced Effects** - Camera shake, depth-of-field simulation, motion smoothing
- **Modern Interface** - Dark glassmorphism theme with smooth animations
- **UI Controls** - Minimize, collapse sidebar, floating button for quick access

## 📁 Repository Structure

```
/
├── loader.lua              # EXECUTOR ENTRY POINT
│
└── src/
    ├── bootstrap.lua       # System initialization & keybinds
    ├── camera.lua          # Core camera logic + cinematic modes
    ├── config.lua          # Configuration & UI theming
    ├── input.lua           # Input state management (keyboard)
    ├── keybind.lua         # Keybind registration & handling
    ├── nametag.lua         # Player name/billboard hiding
    ├── recording.lua       # Screen recording toggle
    ├── speed.lua           # Speed state & multipliers
    ├── spring.lua          # Spring physics library
    ├── ui.lua              # Dashboard interface (responsive & modular)
    └── visuals.lua         # Night vision & ESP highlights
```

## 🚀 Quick Start Guide

### For Users (Loadstring Method - Remote)

1. Copy this command and paste into your Roblox executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourName/YourRepo/main/loader.lua"))()
```

### For Developers (Local Injection)

**Setup:**
1. Create a GitHub repository with the structure above
2. Upload all `src/` files to your repository  
3. Edit `loader.lua` line 4: Replace the raw GitHub URL with your repo's `src/` folder URL
4. Use the loader via loadstring (see Users section)

**Local Testing (Game Scripts):**
1. In Studio: Insert ModuleScript named "loader" in ServerScriptService
2. Paste `loader.lua` content into the ModuleScript
3. Create folder "src" inside loader, add all module scripts
4. Call: `require(game.ServerScriptService.loader)()`

### ⚠️ Troubleshooting Module Loading Errors

If you see "Failed to load all modules" message:

**Step 1: Run Diagnostics**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourName/YourRepo/main/debug_freecam.lua"))()
```

**Step 2: Check Common Issues**

| Problem | Solution |
|---------|----------|
| `HttpGet failed` | Check internet connection, ensure GitHub URLs are correct |
| `Module path not found` | For local injection, ensure folder structure: `script.Parent/src/[module].lua` |
| `Parse error in [module]` | Check the module file for Lua syntax errors |
| `Execution error` | Module has runtime error - check Console for details |

**Step 3: Manual Debug (Local Injection)**
```lua
-- Test if modules load correctly
local loader = require(game.ServerScriptService.loader)
local config = loader.require("config")
print(config) -- Should print a table
```

## 🎮 Keyboard Controls

### UI Navigation
- **Shift + L** - Toggle dashboard visibility
- **Tab** - Show/hide sidebar menu

### Freecam Movement
- **Shift + L** (in-game) - Enable/disable freecam mode
- **W** - Move forward
- **A** - Move left
- **S** - Move backward
- **D** - Move right
- **Q** - Move down
- **E** - Move up
- **Scroll Up/Down** - Adjust movement speed
- **Hold Shift** - 3x speed boost multiplier
- **Hold Ctrl** - 0.2x precision slow mode
- **Drag Mouse** - Smooth cinematic camera rotation

### Additional Features
- **Shift + G** - Toggle screen recording indicator
- **Right Click + Drag** - Alternative rotation control

## 📋 Dashboard Pages

### Camera Page
- Movement speed presets (Walk, Normal, Fast, Cinematic)
- Rotation sensitivity slider
- Boost multiplier adjustment
- Spring smoothness control

### Cinematic Page (NEW)
- **Mode Selection** - Choose camera mode (Free, Follow, Orbit, etc.)
- **Field of View** - Adjustable from 5° to 120°
- **Camera Shake** - Toggle slight shaking effect
- **Depth Effect** - Depth-of-field intensity slider
- **Motion Smoothing** - Camera movement interpolation

### Visuals Page
- Hide all player nametags
- Player highlights (ESP)
- Night vision mode
- Recording indicator

### Settings Page
- Enable/disable freecam
- Keyboard control reference
- Help documentation

## 🎬 Camera Modes Explained

| Mode | Description |
|------|-------------|
| **Free** | Full manual control - fly anywhere with smooth physics |
| **Smooth Follow** | Auto-follow a target with smooth interpolation |
| **Orbit** | Circular orbit around a target position |
| **Dolly Zoom** | Perspective zoom effect (cinematic hallmark) |
| **Static** | Fixed camera shot - set once, locks position |
| **Slow Motion** | 0.25x time scaling for dramatic slow-mo shots |

## ⚙️ Configuration

Edit `src/config.lua` to customize:

- **Movement Speed** - Base speed: 50 studs/sec, max: 200
- **Rotation Sensitivity** - Mouse movement multiplier (default: 0.5)
- **Boost Multiplier** - Shift key speed increase (default: 3x)
- **Smoothness** - Spring damping (0.1-1.0, higher = smoother)
- **FOV Control** - Default field of view (default: 70°)
- **UI Theme** - Colors, animations, corner radius

## 🔧 Architecture

The system is modular and production-ready:

- **camera.lua** - Spring physics-based camera with cinematic modes
- **ui.lua** - Responsive dashboard with page system & animations
- **input.lua** - Keystroke tracking with speed multipliers
- **bootstrap.lua** - Dependency injection & event wiring

Each module is self-contained and can be easily extended.

## 🐛 Troubleshooting

**Avatar disappears in freecam?**
- Avatar is intentionally hidden for clarity. Enable "Show Avatar" in Settings if needed.

**Sidebar won't appear?**
- Press Tab to toggle sidebar visibility
- Check that the main dashboard is open (Shift+L)

**Camera movement feels slow?**
- Increase Speed Presets (Camera page)
- Adjust Spring Smoothness slider
- Hold Shift for 3x boost

**Mouse rotation not working?**
- Ensure freecam is ENABLED (toggle with Shift+L)
- Press Tab to ensure sidebar isn't blocking mouse input

## 📝 Notes

- This is production-ready code for Roblox executors
- All features are optimized for performance
- No external dependencies required
- Clean, modular architecture for easy customization
- Fully featured for cinematic film-making in-game

---

**Made for professional Roblox cinematography and recording.**
