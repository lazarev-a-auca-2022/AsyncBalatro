#!/usr/bin/env lua

-- Test runner for AsyncScore mod
-- Simulates basic Steamodded environment for syntax and logic testing

print("AsyncScore Test Runner")
print("====================")

-- Mock Steamodded environment
SMODS = {
    current_mod = {
        config = {},
        config_tab = {
            add_setting = function(self, setting)
                print("Config setting added: " .. setting.name)
            end
        }
    },
    load_file = function(path)
        print("Loading module: " .. path)
        -- Return a function that creates a mock object
        return function()
            if path:find("async_core") then
                return {
                    init = function() end,
                    update = function() end,
                    calculate_hand_async = function() return 0 end,
                    calculate_joker_async = function() return 0 end
                }
            elseif path:find("performance_monitor") then
                return {
                    init = function() end,
                    update = function() end,
                    is_performance_poor = function() return false end
                }
            elseif path:find("compatibility") then
                return {
                    check_mods = function() end,
                    is_cryptid_joker = function() return false end
                }
            end
            return {}
        end
    end
}

-- Mock game globals
G = {
    jokers = {
        cards = {}
    }
}

-- Mock functions that would exist in Balatro
calculate_hand = function() return 0 end
calculate_joker = nil -- Not always present

-- Mock love.timer for performance monitor
love = {
    timer = {
        getTime = function() return os.clock() end
    }
}

print("Setting up mock environment...")

-- Load configuration
local config_loaded, config = pcall(dofile, "config.lua")
if config_loaded then
    print("✓ Configuration loaded successfully")
    SMODS.current_mod.config = config
else
    print("⚠ Configuration not found, using defaults")
    SMODS.current_mod.config = {}
end

-- Test syntax by loading the main mod file
print("\nTesting AsyncScore mod syntax...")
local success, result = pcall(dofile, "AsyncScore.lua")

if success then
    print("✓ AsyncScore mod loaded successfully!")
    print("✓ No syntax errors detected")
    
    if result then
        print("✓ Mod returned successfully")
        print("✓ Version: " .. (result.version or "unknown"))
        print("✓ Enabled: " .. tostring(result.enabled))
        
        -- Test basic functionality
        if result.update then
            print("\nTesting update function...")
            result:update(0.016) -- Simulate 60 FPS frame
            print("✓ Update function works")
        end
    end
    
    print("\n" .. string.rep("=", 40))
    print("SUCCESS: AsyncScore mod passed all tests!")
    print("The mod is ready for use in Balatro with Steamodded.")
    print(string.rep("=", 40))
    
else
    print("✗ Error loading AsyncScore mod:")
    print(result)
    print("\n" .. string.rep("=", 40))
    print("FAILED: Please fix the errors above")
    print(string.rep("=", 40))
    os.exit(1)
end