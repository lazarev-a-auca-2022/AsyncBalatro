-- Compatibility layer for Cryptid, Talisman, and other mods
local Compatibility = {}

function Compatibility:new()
    local obj = {
        cryptid_detected = false,
        talisman_detected = false,
        cryptid_jokers = {},
        known_complex_jokers = {},
        mod_hooks = {}
    }
    setmetatable(obj, {__index = self})
    return obj
end

-- Check for installed mods
function Compatibility:check_mods()
    -- Check for Cryptid
    if SMODS and SMODS.Mods then
        for mod_id, mod in pairs(SMODS.Mods) do
            if mod_id == "Cryptid" or (mod.name and string.find(mod.name:lower(), "cryptid")) then
                self.cryptid_detected = true
                self:setup_cryptid_compatibility()
                if AsyncScore.debug then
                    print("[AsyncScore] Cryptid mod detected")
                end
            end
            
            if mod_id == "Talisman" or (mod.name and string.find(mod.name:lower(), "talisman")) then
                self.talisman_detected = true
                self:setup_talisman_compatibility()
                if AsyncScore.debug then
                    print("[AsyncScore] Talisman mod detected")
                end
            end
        end
    end
    
    -- Fallback detection methods
    if not self.cryptid_detected then
        self:detect_cryptid_fallback()
    end
    
    if not self.talisman_detected then
        self:detect_talisman_fallback()
    end
end

-- Setup Cryptid-specific compatibility
function Compatibility:setup_cryptid_compatibility()
    -- List of known complex Cryptid jokers that benefit from async processing
    self.cryptid_jokers = {
        -- M jokers (typically complex)
        "cry_m",
        "cry_jimball", 
        "cry_sus",
        "cry_impostor",
        "cry_unjust_dagger",
        "cry_compound_interest",
        "cry_monkey_dagger",
        "cry_exponentia",
        "cry_mprime",
        "cry_big_jimbo",
        "cry_stellar",
        "cry_morse",
        "cry_unity",
        "cry_sacrifice",
        "cry_flip_side",
        "cry_canvas",
        "cry_error",
        "cry_membership_card",
        "cry_lucky_joker",
        "cry_seal_the_deal",
        "cry_curse",
        "cry_oldblueprint",
        -- Add more as needed
    }
    
    -- Mark these as complex jokers needing async processing
    for _, joker_key in ipairs(self.cryptid_jokers) do
        self.known_complex_jokers[joker_key] = true
    end
end

-- Setup Talisman-specific compatibility  
function Compatibility:setup_talisman_compatibility()
    -- Hook into Talisman's number system if available
    if to_big and from_big then
        -- Talisman BigNum support detected
        self.big_num_support = true
        if AsyncScore.debug then
            print("[AsyncScore] Talisman BigNum support enabled")
        end
    end
    
    if to_omega and from_omega then
        -- Talisman OmegaNum support detected
        self.omega_num_support = true
        if AsyncScore.debug then
            print("[AsyncScore] Talisman OmegaNum support enabled")
        end
    end
end

-- Fallback Cryptid detection
function Compatibility:detect_cryptid_fallback()
    -- Check for Cryptid jokers in the game
    if G and G.P_CENTERS then
        for key, center in pairs(G.P_CENTERS) do
            if string.find(key, "cry_") == 1 or string.find(key, "cryptid") then
                self.cryptid_detected = true
                self:setup_cryptid_compatibility()
                if AsyncScore.debug then
                    print("[AsyncScore] Cryptid detected via joker analysis")
                end
                break
            end
        end
    end
end

-- Fallback Talisman detection
function Compatibility:detect_talisman_fallback()
    -- Check for Talisman functions
    if to_big or from_big or to_omega or from_omega then
        self.talisman_detected = true
        self:setup_talisman_compatibility()
        if AsyncScore.debug then
            print("[AsyncScore] Talisman detected via function analysis")
        end
    end
end

-- Check if a joker is from Cryptid
function Compatibility:is_cryptid_joker(card)
    if not card or not card.config or not card.config.center then
        return false
    end
    
    local key = card.config.center.key
    if not key then return false end
    
    -- Check against known Cryptid jokers
    if self.known_complex_jokers[key] then
        return true
    end
    
    -- Check for Cryptid prefixes
    return string.find(key, "cry_") == 1 or 
           string.find(key, "cryptid") or
           string.find(key, "m_") == 1
end

-- Check if a joker is computationally complex
function Compatibility:is_complex_joker(card)
    if not card then return false end
    
    -- Cryptid jokers are generally complex
    if self:is_cryptid_joker(card) then
        return true
    end
    
    -- Check for other patterns that indicate complexity
    local key = card.config and card.config.center and card.config.center.key
    if key then
        -- Jokers with mathematical operations
        if string.find(key:lower(), "exponential") or
           string.find(key:lower(), "factorial") or
           string.find(key:lower(), "fibonacci") or
           string.find(key:lower(), "compound") or
           string.find(key:lower(), "recursive") then
            return true
        end
    end
    
    return false
end

-- Get safe number conversion for Talisman compatibility
function Compatibility:safe_number_convert(value, target_type)
    if not self.talisman_detected then
        return value
    end
    
    target_type = target_type or "number"
    
    if target_type == "big" and to_big then
        return to_big(value)
    elseif target_type == "omega" and to_omega then
        return to_omega(value)
    elseif target_type == "number" then
        if from_big and type(value) == "table" and value.array then
            return from_big(value)
        elseif from_omega and type(value) == "table" and value.sign then
            return from_omega(value)
        end
    end
    
    return value
end

-- Hook into mod-specific events
function Compatibility:hook_mod_events()
    -- Hook into Cryptid events if available
    if self.cryptid_detected and cry_pre_calculate_hand then
        local original_pre_calc = cry_pre_calculate_hand
        cry_pre_calculate_hand = function(...)
            AsyncScore.performance_monitor:start_timing("cryptid_pre_calc")
            local result = original_pre_calc(...)
            AsyncScore.performance_monitor:end_timing("cryptid_pre_calc", "cryptid_hook", false)
            return result
        end
    end
    
    -- Hook into Talisman events if available
    if self.talisman_detected and talisman_calculate then
        local original_talisman_calc = talisman_calculate
        talisman_calculate = function(...)
            AsyncScore.performance_monitor:start_timing("talisman_calc")
            local result = original_talisman_calc(...)
            AsyncScore.performance_monitor:end_timing("talisman_calc", "talisman_hook", false)
            return result
        end
    end
end

-- Get compatibility information
function Compatibility:get_info()
    return {
        cryptid_detected = self.cryptid_detected,
        talisman_detected = self.talisman_detected,
        big_num_support = self.big_num_support or false,
        omega_num_support = self.omega_num_support or false,
        known_cryptid_jokers = #self.cryptid_jokers,
        complex_joker_patterns = self.known_complex_jokers
    }
end

-- Apply compatibility patches
function Compatibility:apply_patches()
    -- Patch Cryptid jokers to work better with async
    if self.cryptid_detected then
        self:patch_cryptid_jokers()
    end
    
    -- Patch Talisman number handling
    if self.talisman_detected then
        self:patch_talisman_numbers()
    end
end

-- Patch Cryptid jokers for better async compatibility
function Compatibility:patch_cryptid_jokers()
    if not G or not G.P_CENTERS then return end
    
    for key, center in pairs(G.P_CENTERS) do
        if self:is_cryptid_joker({config = {center = center}}) then
            -- Add async-friendly markers
            if center.config then
                center.config.async_friendly = true
                center.config.complexity_score = self:calculate_complexity_score(center)
            end
        end
    end
end

-- Patch Talisman number operations
function Compatibility:patch_talisman_numbers()
    -- Ensure number operations are async-safe
    if to_big then
        local original_to_big = to_big
        to_big = function(value)
            -- Add bounds checking for async safety
            if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then
                return original_to_big(0) -- Safe fallback
            end
            return original_to_big(value)
        end
    end
end

-- Calculate complexity score for a joker
function Compatibility:calculate_complexity_score(center)
    local score = 1
    
    if not center then return score end
    
    local key = center.key or ""
    
    -- Base complexity for Cryptid jokers
    if string.find(key, "cry_") == 1 then
        score = score + 2
    end
    
    -- Additional complexity for certain patterns
    local complex_patterns = {
        "exponential", "factorial", "compound", "recursive",
        "m_", "jimball", "sus", "impostor", "stellar"
    }
    
    for _, pattern in ipairs(complex_patterns) do
        if string.find(key:lower(), pattern) then
            score = score + 1
        end
    end
    
    return score
end

return function()
    return Compatibility:new()
end
