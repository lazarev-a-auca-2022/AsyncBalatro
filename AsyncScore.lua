--- STEAMODDED HEADER
--- MOD_NAME: AsyncScore
--- MOD_ID: AsyncScore
--- MOD_AUTHOR: [AsyncScore Team]
--- MOD_DESCRIPTION: Asynchronous scoring optimization mod for reducing lag in heavily modded games
--- BADGE_COLOUR: 3FC7EB
--- PREFIX: async

----------------------------------------------
------------MOD CODE -------------------------

-- Load configuration
local config = SMODS.current_mod.config or {}

-- Load core modules
local async_core = SMODS.load_file("lib/async_core.lua")()
local performance_monitor = SMODS.load_file("lib/performance_monitor.lua")()
local compatibility = SMODS.load_file("lib/compatibility.lua")()

-- Global mod state
AsyncScore = {
    config = config,
    async_core = async_core,
    performance_monitor = performance_monitor,
    compatibility = compatibility,
    version = "1.0.0",
    enabled = true,
    debug = config.debug_logging or false
}

-- Debug logging function
local function log(message, level)
    if AsyncScore.debug or (level and level == "error") then
        print("[AsyncScore] " .. (level and ("[" .. level:upper() .. "] ") or "") .. tostring(message))
    end
end

-- Initialize mod
function AsyncScore:init()
    log("Initializing AsyncScore v" .. self.version)
    
    -- Initialize performance monitoring
    self.performance_monitor:init()
    
    -- Check for Cryptid and Talisman compatibility
    self.compatibility:check_mods()
    
    -- Hook into scoring system
    self:hook_scoring_system()
    
    -- Setup configuration UI
    self:setup_config_ui()
    
    log("AsyncScore initialization complete")
end

-- Hook into the game's scoring calculation system
function AsyncScore:hook_scoring_system()
    log("Hooking into scoring system...")
    
    -- Store original calculate_hand function
    local original_calculate_hand = calculate_hand
    
    -- Override with async version
    calculate_hand = function(cards, hand, mult, base_mult, base_scoring, scoring_hand)
        -- Check if async processing should be used
        if AsyncScore:should_use_async(cards, hand) then
            return AsyncScore.async_core:calculate_hand_async(
                cards, hand, mult, base_mult, base_scoring, scoring_hand,
                original_calculate_hand
            )
        else
            -- Use original synchronous calculation
            return original_calculate_hand(cards, hand, mult, base_mult, base_scoring, scoring_hand)
        end
    end
    
    -- Hook joker calculation if present
    if calculate_joker then
        local original_calculate_joker = calculate_joker
        calculate_joker = function(card, context)
            if AsyncScore:should_use_async_joker(card, context) then
                return AsyncScore.async_core:calculate_joker_async(card, context, original_calculate_joker)
            else
                return original_calculate_joker(card, context)
            end
        end
    end
    
    log("Scoring system hooks installed")
end

-- Determine if async processing should be used
function AsyncScore:should_use_async(cards, hand)
    local joker_count = G.jokers and #G.jokers.cards or 0
    local complexity_threshold = self.config.complexity_threshold or 10
    
    -- Use async if many jokers present or performance is poor
    return joker_count >= complexity_threshold or 
           self.performance_monitor:is_performance_poor()
end

-- Determine if async joker processing should be used
function AsyncScore:should_use_async_joker(card, context)
    -- Check if this is a complex Cryptid joker
    if self.compatibility:is_cryptid_joker(card) then
        return true
    end
    
    -- Check if performance is suffering
    return self.performance_monitor:is_performance_poor()
end

-- Setup configuration UI
function AsyncScore:setup_config_ui()
    -- Add configuration options to mod menu
    if SMODS.current_mod and SMODS.current_mod.config_tab then
        local config_tab = SMODS.current_mod.config_tab
        
        -- Async threshold setting
        config_tab:add_setting({
            id = "complexity_threshold",
            name = "Async Threshold",
            desc = "Number of jokers before async processing kicks in",
            type = "slider",
            min = 5,
            max = 50,
            default = 10,
            step = 1
        })
        
        -- Performance monitoring setting
        config_tab:add_setting({
            id = "performance_monitoring",
            name = "Performance Monitoring",
            desc = "Monitor and log performance metrics",
            type = "toggle",
            default = true
        })
        
        -- Debug logging setting
        config_tab:add_setting({
            id = "debug_logging",
            name = "Debug Logging",
            desc = "Enable detailed debug logging",
            type = "toggle",
            default = false
        })
        
        -- Fallback mode setting
        config_tab:add_setting({
            id = "fallback_mode",
            name = "Fallback Mode",
            desc = "Automatically fallback to sync calculation if async fails",
            type = "toggle",
            default = true
        })
    end
end

-- Update function called each frame
function AsyncScore:update(dt)
    if not self.enabled then return end
    
    -- Update async core
    self.async_core:update(dt)
    
    -- Update performance monitoring
    self.performance_monitor:update(dt)
end

-- Initialize the mod when loaded
AsyncScore:init()

-- Export for other mods to use
return AsyncScore
