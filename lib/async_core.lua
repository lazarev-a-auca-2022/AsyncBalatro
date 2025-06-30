-- Asynchronous scoring calculation core
local AsyncCore = {}

function AsyncCore:new()
    local obj = {
        coroutines = {},
        pending_calculations = {},
        max_operations_per_frame = 50,
        current_frame_operations = 0,
        calculation_queue = {},
        results_cache = {}
    }
    setmetatable(obj, {__index = self})
    return obj
end

-- Initialize async core
function AsyncCore:init()
    self.coroutines = {}
    self.pending_calculations = {}
    self.calculation_queue = {}
    self.results_cache = {}
end

-- Main update function called each frame
function AsyncCore:update(dt)
    self.current_frame_operations = 0
    
    -- Process calculation queue
    self:process_queue()
    
    -- Update running coroutines
    self:update_coroutines()
    
    -- Clean up completed calculations
    self:cleanup_completed()
end

-- Async hand calculation
function AsyncCore:calculate_hand_async(cards, hand, mult, base_mult, base_scoring, scoring_hand, original_func)
    local calculation_id = self:generate_calculation_id(cards, hand)
    
    -- Check cache first
    if self.results_cache[calculation_id] then
        return self.results_cache[calculation_id]
    end
    
    -- Create async calculation
    local calculation = {
        id = calculation_id,
        type = "hand",
        cards = cards,
        hand = hand,
        mult = mult,
        base_mult = base_mult,
        base_scoring = base_scoring,
        scoring_hand = scoring_hand,
        original_func = original_func,
        status = "pending",
        result = nil,
        coroutine = nil
    }
    
    -- Start coroutine for calculation
    calculation.coroutine = coroutine.create(function()
        return self:_calculate_hand_coroutine(calculation)
    end)
    
    self.pending_calculations[calculation_id] = calculation
    
    -- Try to get immediate result if possible
    local success, result = coroutine.resume(calculation.coroutine)
    if success and coroutine.status(calculation.coroutine) == "dead" then
        calculation.status = "completed"
        calculation.result = result
        self.results_cache[calculation_id] = result
        return result
    end
    
    -- Return partial/placeholder result for now
    return self:get_placeholder_result(cards, hand, mult, base_mult)
end

-- Async joker calculation
function AsyncCore:calculate_joker_async(card, context, original_func)
    local calculation_id = self:generate_joker_id(card, context)
    
    -- Check cache
    if self.results_cache[calculation_id] then
        return self.results_cache[calculation_id]
    end
    
    -- Create async joker calculation
    local calculation = {
        id = calculation_id,
        type = "joker",
        card = card,
        context = context,
        original_func = original_func,
        status = "pending",
        result = nil,
        coroutine = nil
    }
    
    calculation.coroutine = coroutine.create(function()
        return self:_calculate_joker_coroutine(calculation)
    end)
    
    self.pending_calculations[calculation_id] = calculation
    
    -- Try immediate execution
    local success, result = coroutine.resume(calculation.coroutine)
    if success and coroutine.status(calculation.coroutine) == "dead" then
        calculation.status = "completed" 
        calculation.result = result
        self.results_cache[calculation_id] = result
        return result
    end
    
    -- Return safe default
    return {}
end

-- Hand calculation coroutine
function AsyncCore:_calculate_hand_coroutine(calculation)
    local cards, hand = calculation.cards, calculation.hand
    local mult, base_mult = calculation.mult, calculation.base_mult
    local base_scoring, scoring_hand = calculation.base_scoring, calculation.scoring_hand
    
    -- Break calculation into chunks
    local chunk_size = 5
    local processed = 0
    
    while processed < #cards do
        -- Process chunk of cards
        local end_idx = math.min(processed + chunk_size, #cards)
        
        for i = processed + 1, end_idx do
            -- Perform card scoring operations
            if self:should_yield() then
                coroutine.yield()
            end
        end
        
        processed = end_idx
        
        -- Yield control if we've done enough work this frame
        if self:should_yield() then
            coroutine.yield()
        end
    end
    
    -- Complete calculation with original function
    return calculation.original_func(cards, hand, mult, base_mult, base_scoring, scoring_hand)
end

-- Joker calculation coroutine
function AsyncCore:_calculate_joker_coroutine(calculation)
    local card, context = calculation.card, calculation.context
    
    -- Check if this is a complex joker that needs chunking
    if self:is_complex_joker(card) then
        -- Yield periodically during complex calculations
        if self:should_yield() then
            coroutine.yield()
        end
    end
    
    -- Execute original joker function
    return calculation.original_func(card, context)
end

-- Process calculation queue
function AsyncCore:process_queue()
    for id, calculation in pairs(self.pending_calculations) do
        if calculation.status == "pending" and calculation.coroutine then
            local success, result = coroutine.resume(calculation.coroutine)
            
            if success then
                if coroutine.status(calculation.coroutine) == "dead" then
                    calculation.status = "completed"
                    calculation.result = result
                    self.results_cache[calculation.id] = result
                end
            else
                -- Handle error
                calculation.status = "error"
                calculation.error = result
                if AsyncScore.debug then
                    print("[AsyncScore] Calculation error: " .. tostring(result))
                end
            end
            
            -- Break if we've done enough work this frame
            if self:should_yield() then
                break
            end
        end
    end
end

-- Update running coroutines
function AsyncCore:update_coroutines()
    -- Clean up completed coroutines and update status
    for id, calculation in pairs(self.pending_calculations) do
        if calculation.status == "completed" or calculation.status == "error" then
            -- Mark for cleanup
            calculation.cleanup = true
        end
    end
end

-- Clean up completed calculations
function AsyncCore:cleanup_completed()
    for id, calculation in pairs(self.pending_calculations) do
        if calculation.cleanup then
            self.pending_calculations[id] = nil
        end
    end
    
    -- Clean old cache entries
    local cache_size = 0
    for _ in pairs(self.results_cache) do
        cache_size = cache_size + 1
    end
    
    if cache_size > 1000 then
        -- Clear oldest 25% of cache
        local to_remove = {}
        local count = 0
        for id, _ in pairs(self.results_cache) do
            table.insert(to_remove, id)
            count = count + 1
            if count >= cache_size * 0.25 then break end
        end
        
        for _, id in ipairs(to_remove) do
            self.results_cache[id] = nil
        end
    end
end

-- Check if we should yield control
function AsyncCore:should_yield()
    self.current_frame_operations = self.current_frame_operations + 1
    return self.current_frame_operations >= self.max_operations_per_frame
end

-- Generate calculation ID for caching
function AsyncCore:generate_calculation_id(cards, hand)
    local id_parts = {}
    for i, card in ipairs(cards or {}) do
        table.insert(id_parts, card.base.id or "unknown")
    end
    return table.concat(id_parts, "_") .. "_" .. (hand or "none")
end

-- Generate joker calculation ID
function AsyncCore:generate_joker_id(card, context)
    local card_id = card.config and card.config.center and card.config.center.key or "unknown"
    local context_type = context and context.cardarea and context.cardarea.config.type or "unknown"
    return card_id .. "_" .. context_type
end

-- Check if joker is complex (Cryptid jokers typically are)
function AsyncCore:is_complex_joker(card)
    if not card or not card.config then return false end
    
    local key = card.config.center and card.config.center.key
    if not key then return false end
    
    -- Check for Cryptid jokers (they often have "cry_" prefix)
    return string.find(key, "cry_") == 1 or
           string.find(key, "cryptid") or
           string.find(key, "m_") == 1  -- M jokers from Cryptid
end

-- Get placeholder result for immediate return
function AsyncCore:get_placeholder_result(cards, hand, mult, base_mult)
    -- Return safe minimal result structure
    return {
        chips = base_mult or 0,
        mult = mult or 1,
        hand_chips = base_mult or 0,
        level = 1
    }
end

return function()
    return AsyncCore:new()
end
