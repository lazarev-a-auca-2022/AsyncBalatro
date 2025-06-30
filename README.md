# AsyncScore - Asynchronous Scoring Optimization for Balatro

AsyncScore is a performance optimization mod for Balatro that reduces lag in heavily modded games by implementing asynchronous scoring calculations. It's specifically designed to work with popular mods like Cryptid (100+ jokers) and Talisman (extended number systems).

## Features

### 🚀 Performance Optimization
- **Asynchronous Processing**: Complex scoring calculations run without blocking the main game thread
- **Intelligent Threshold Detection**: Automatically switches to async mode when performance suffers
- **Coroutine-Based Architecture**: Uses Lua coroutines for smooth, non-blocking calculations
- **Adaptive Performance**: Dynamically adjusts processing based on current performance

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


## How It Works

### Async
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
