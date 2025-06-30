#!/usr/bin/env lua

-- Localization compatibility test for AsyncScore
-- Tests the localization structure against common Balatro patterns

print("AsyncScore Localization Test")
print("============================")

-- Test loading the localization file
local success, localization = pcall(dofile, "localization/en-us.lua")

if not success then
    print("✗ Failed to load localization file:")
    print(localization)
    os.exit(1)
end

print("✓ Localization file loaded successfully")

-- Test structure validation
local function validate_structure(data, path)
    path = path or "root"
    
    if type(data) ~= "table" then
        print("✗ Expected table at " .. path .. ", got " .. type(data))
        return false
    end
    
    return true
end

-- Test descriptions structure
if not validate_structure(localization, "localization") then
    os.exit(1)
end

if not validate_structure(localization.descriptions, "descriptions") then
    os.exit(1)
end

if not validate_structure(localization.descriptions.Mod, "descriptions.Mod") then
    os.exit(1)
end

if not validate_structure(localization.descriptions.Mod.AsyncScore, "descriptions.Mod.AsyncScore") then
    os.exit(1)
end

-- Test that mod description has required fields
local mod_desc = localization.descriptions.Mod.AsyncScore
if type(mod_desc.name) ~= "string" then
    print("✗ Mod name must be a string")
    os.exit(1)
end

if type(mod_desc.text) ~= "table" then
    print("✗ Mod text must be a table")
    os.exit(1)
end

if #mod_desc.text == 0 then
    print("✗ Mod text must not be empty")
    os.exit(1)
end

print("✓ Mod description structure is valid")

-- Test misc structure
if not validate_structure(localization.misc, "misc") then
    os.exit(1)
end

if not validate_structure(localization.misc.async_score, "misc.async_score") then
    os.exit(1)
end

print("✓ Misc localization structure is valid")

-- Test that all required strings are present
local required_strings = {
    "config_title",
    "complexity_threshold_name",
    "performance_monitoring_name",
    "debug_logging_name",
    "fallback_mode_name"
}

local async_misc = localization.misc.async_score
for _, key in ipairs(required_strings) do
    if type(async_misc[key]) ~= "string" then
        print("✗ Missing or invalid required string: " .. key)
        os.exit(1)
    end
end

print("✓ All required localization strings are present")

-- Simulate the problematic scenario from the crash
print("\nTesting compatibility with Balatro localization system...")

-- Mock the scenario that was causing the crash
local function simulate_balatro_localization()
    local descriptions = localization.descriptions
    
    -- This simulates what the game does when processing mod descriptions
    for category_name, category in pairs(descriptions) do
        if type(category) == "table" then
            for item_name, item in pairs(category) do
                if type(item) == "table" then
                    -- Try to access the properties that were causing the crash
                    if item.name and item.text then
                        -- This should work now
                        local name = item.name
                        local text = item.text
                        
                        if type(name) ~= "string" then
                            error("Name should be string, got " .. type(name))
                        end
                        
                        if type(text) ~= "table" then
                            error("Text should be table, got " .. type(text))
                        end
                        
                        print("✓ Successfully processed: " .. category_name .. "." .. item_name)
                    end
                else
                    error("Expected table for " .. category_name .. "." .. item_name .. ", got " .. type(item))
                end
            end
        else
            error("Expected table for category " .. category_name .. ", got " .. type(category))
        end
    end
end

local success, error_msg = pcall(simulate_balatro_localization)
if not success then
    print("✗ Localization compatibility test failed:")
    print(error_msg)
    os.exit(1)
end

print("✓ Localization compatibility test passed")

print("\n" .. string.rep("=", 50))
print("SUCCESS: AsyncScore localization is properly structured!")
print("The mod should no longer crash during localization loading.")
print(string.rep("=", 50))