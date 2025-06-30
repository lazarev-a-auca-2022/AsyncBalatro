# AsyncScore - Asynchronous Scoring Optimization for Balatro

AsyncScore is a performance optimization mod for Balatro that reduces lag in heavily modded games by implementing asynchronous scoring calculations. It's specifically designed to work with popular mods like Cryptid (100+ jokers) and Talisman (extended number systems).

## Features

### 🚀 Performance Optimization
- **Asynchronous Processing**: Complex scoring calculations run without blocking the main game thread
- **Intelligent Threshold Detection**: Automatically switches to async mode when performance suffers
- **Coroutine-Based Architecture**: Uses Lua coroutines for smooth, non-blocking calculations
- **Adaptive Performance**: Dynamically adjusts processing based on current performance

### 🃏 Mod Compatibility
- **Cryptid Integration**: Optimized for Cryptid's 100+ overpowered jokers
- **Talisman Support**: Full compatibility with BigNum and OmegaNum scoring systems
- **Universal Design**: Works with any Steamodded-based mod
- **Fallback Safety**: Automatically falls back to synchronous calculation if issues occur

### 📊 Monitoring & Debug
- **Performance Metrics**: Real-time FPS and calculation timing monitoring
- **Debug Logging**: Detailed logging for troubleshooting and optimization
- **Configuration UI**: Easy-to-use in-game configuration interface
- **Performance Reports**: Periodic performance analysis and recommendations

## Installation

### Prerequisites
1. **Lovely Injector** - Download and place `version.dll` in your Balatro game directory
2. **Steamodded** - Latest version from [Steamodded repository](https://github.com/Steamopollys/Steamodded)
3. **Talisman** (recommended) - Extended number system support
4. **Cryptid** (optional) - Popular joker expansion mod

### Installation Steps
1. Download the latest AsyncScore release
2. Extract to `%AppData%/Balatro/Mods/AsyncScore/`
3. Ensure the folder structure matches:
   ```
   %AppData%/Balatro/Mods/
   ├── Steamodded/
   ├── Talisman/
   ├── Cryptid/
   └── AsyncScore/
       ├── AsyncScore.lua
       ├── AsyncScore.json
       ├── lib/
       ├── localization/
       └── README.md
   ```
4. Launch Balatro and verify AsyncScore appears in the Mods menu

## Configuration

Access configuration through the in-game Mods menu → AsyncScore → Config

### Key Settings

| Setting | Default | Description |
|---------|---------|-------------|
| **Async Threshold** | 10 | Number of jokers before async processing activates |
| **Performance Monitoring** | Enabled | Track performance metrics and frame rates |
| **Fallback Mode** | Enabled | Automatically switch to sync if async fails |
| **Debug Logging** | Disabled | Enable detailed console logging |
| **Caching** | Enabled | Cache calculation results for better performance |

### Advanced Settings

| Setting | Default | Description |
|---------|---------|-------------|
| **Chunk Size** | 5 | Cards processed per async chunk |
| **Cache Size Limit** | 1000 | Maximum number of cached results |
| **Adaptive Threshold** | Enabled | Auto-adjust threshold based on performance |

## How It Works

### Asynchronous Processing
AsyncScore uses Lua coroutines to break up complex scoring calculations into smaller chunks that can be processed over multiple frames. This prevents the game from freezing during heavy joker calculations.

```lua
-- Example: Processing cards in chunks
local chunk_size = 5
local processed = 0

while processed < #cards do
    -- Process chunk of cards
    local end_idx = math.min(processed + chunk_size, #cards)
    
    for i = processed + 1, end_idx do
        -- Perform scoring operations
        if should_yield() then
            coroutine.yield() -- Give control back to main thread
        end
    end
    
    processed = end_idx
end
