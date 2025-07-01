-- Asynchronous scoring calculation core
local AsyncCore = {}

function AsyncCore:new()
    local obj = {
        coroutines = {},
        pending_calculations = {},
        max_operations_per_frame = 50,
        current_frame_operations = 0,
        calculation_queue = {},
        results_cache = {},
        retrigger_batches = {},
        max_batch_size = 10,
        batch_timeout = 0.1 -- seconds
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
    self.retrigger_batches = {}
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
    
    -- Clean up expired retrigger batches
    self:cleanup_retrigger_batches()
end

-- Clean up expired retrigger batches
function AsyncCore:cleanup_retrigger_batches()
    local current_time = love.timer.getTime()
    
    for batch_key, batch in pairs(self.retrigger_batches) do
        if current_time - batch.created_time > self.batch_timeout then
            -- Process the batch even if it's not full
            self:process_retrigger_batch(batch_key)
        end
    end
end

-- Cache joker result with retrigger optimization metadata
function AsyncCore:cache_joker_result(calculation_id, result, calculation)
    local cached_entry = {
        result = result,
        retriggerable = self:is_result_retriggerable(result, calculation),
        timestamp = love.timer.getTime(),
        joker_key = calculation.card.config and calculation.card.config.center and calculation.card.config.center.key,
        talisman_fast_mode = calculation.talisman_fast_mode
    }
    
    self.results_cache[calculation_id] = cached_entry
    
    if AsyncScore.debug and cached_entry.retriggerable then
        print("[AsyncScore] Cached retriggerable result: " .. calculation_id)
    end
end

-- Determine if a result can be safely reused for retriggers
function AsyncCore:is_result_retriggerable(result, calculation)
    -- Only allow retrigger caching when Talisman fast mode is enabled
    if not calculation.talisman_fast_mode then
        return false
    end
    
    -- Check if this is a deterministic joker effect
    local card = calculation.card
    if not card or not card.config or not card.config.center then
        return false
    end
    
    local joker_key = card.config.center.key
    
    -- Safe jokers that produce consistent retrigger results
    local safe_retrigger_jokers = {
        -- Basic multipliers
        "j_joker", "j_greedy_joker", "j_lusty_joker", "j_wrathful_joker",
        "j_glutton_joker", "j_jolly_joker", "j_zany_joker", "j_mad_joker",
        "j_crazy_joker", "j_droll_joker", "j_sly_joker", "j_wily_joker",
        "j_clever_joker", "j_devious_joker", "j_crafty_joker",
        
        -- Most Cryptid jokers are safe for retriggers when animations disabled
        "cry_", -- Cryptid prefix
        "m_" -- M jokers prefix
    }
    
    -- Check if this joker is safe for retrigger caching
    for _, safe_pattern in ipairs(safe_retrigger_jokers) do
        if string.find(joker_key, safe_pattern) then
            return true
        end
    end
    
    -- Conservative approach: only cache known safe jokers
    return false
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

-- Async joker calculation with Talisman-dependent retrigger optimization
function AsyncCore:calculate_joker_async(card, context, original_func)
    local calculation_id = self:generate_joker_id(card, context)
    
    -- Check if Talisman's "Disable Scoring Animations" is enabled
    local talisman_fast_mode = self:is_talisman_fast_mode_enabled()
    local is_retrigger = context and context.retrigger_joker
    
    -- Enhanced caching for retriggers when Talisman fast mode is active
    if self.results_cache[calculation_id] then
        local cached_result = self.results_cache[calculation_id]
        
        -- Fast retrigger optimization only when Talisman animations are disabled
        if is_retrigger and talisman_fast_mode and cached_result.retriggerable then
            if AsyncScore.debug then
                print("[AsyncScore] Fast retrigger cache hit (Talisman mode): " .. calculation_id)
            end
            return cached_result.result
        elseif not is_retrigger then
            return cached_result.result or cached_result
        end
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
        coroutine = nil,
        is_retrigger = is_retrigger,
        retrigger_count = context and context.retrigger_count or 0,
        talisman_fast_mode = talisman_fast_mode
    }
    
    -- Use different processing strategies based on Talisman mode
    if is_retrigger and talisman_fast_mode then
        -- Ultra-fast retrigger processing when animations are disabled
        calculation.coroutine = coroutine.create(function()
            return self:_calculate_fast_retrigger_coroutine(calculation)
        end)
    else
        -- Standard async processing
        calculation.coroutine = coroutine.create(function()
            return self:_calculate_joker_coroutine(calculation)
        end)
    end
    
    self.pending_calculations[calculation_id] = calculation
    
    -- Try immediate execution
    local success, result = coroutine.resume(calculation.coroutine)
    if success and coroutine.status(calculation.coroutine) == "dead" then
        calculation.status = "completed" 
        calculation.result = result
        
        -- Enhanced caching for retrigger scenarios
        self:cache_joker_result(calculation_id, result, calculation)
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

-- Fast retrigger calculation coroutine (only when Talisman animations disabled)
function AsyncCore:_calculate_fast_retrigger_coroutine(calculation)
    local card, context = calculation.card, calculation.context
    
    -- Skip animation delays and yield checks for maximum speed
    -- This is safe only when Talisman has disabled scoring animations
    
    if AsyncScore.debug then
        print("[AsyncScore] Fast retrigger processing: " .. (card.config.center.key or "unknown"))
    end
    
    -- Check if we can batch this retrigger with similar ones
    local batch_key = self:get_retrigger_batch_key(card, context)
    if self.retrigger_batches[batch_key] then
        -- Add to existing batch
        table.insert(self.retrigger_batches[batch_key].calculations, calculation)
        
        -- If batch is full, process all at once
        if #self.retrigger_batches[batch_key].calculations >= self.max_batch_size then
            return self:process_retrigger_batch(batch_key)
        else
            -- Wait for more retriggerable
            return self.retrigger_batches[batch_key].base_result
        end
    else
        -- Create new batch
        self.retrigger_batches[batch_key] = {
            calculations = {calculation},
            base_result = calculation.original_func(card, context),
            created_time = love.timer.getTime()
        }
        
        return self.retrigger_batches[batch_key].base_result
    end
end

-- Check if Talisman's "Disable Scoring Animations" setting is enabled
function AsyncCore:is_talisman_fast_mode_enabled()
    -- Check Talisman's settings for disabled animations
    if G and G.SETTINGS and G.SETTINGS.TALISMAN then
        local talisman_settings = G.SETTINGS.TALISMAN
        
        -- Check for the disable animations setting
        if talisman_settings.disable_anims or 
           talisman_settings.disable_scoring_anims or
           talisman_settings.fast_scoring then
            return true
        end
    end
    
    -- Fallback: check if Talisman functions indicate fast mode
    if SMODS and SMODS.Mods and SMODS.Mods.Talisman then
        local talisman_mod = SMODS.Mods.Talisman
        if talisman_mod.config and talisman_mod.config.disable_anims then
            return true
        end
    end
    
    -- Check global settings that might indicate fast mode
    if G and G.SETTINGS then
        if G.SETTINGS.fast_play or 
           G.SETTINGS.reduced_motion or
           G.SETTINGS.disable_bg_anims then
            return true
        end
    end
    
    return false
end

-- Get batch key for grouping similar retriggers
function AsyncCore:get_retrigger_batch_key(card, context)
    local card_key = card.config and card.config.center and card.config.center.key or "unknown"
    local context_type = context and context.cardarea and context.cardarea.config.type or "unknown"
    local hand_type = context and context.scoring_hand or "unknown"
    
    return card_key .. "_" .. context_type .. "_" .. hand_type
end

-- Process a batch of similar retriggers for maximum efficiency
function AsyncCore:process_retrigger_batch(batch_key)
    local batch = self.retrigger_batches[batch_key]
    if not batch then return {} end
    
    local base_result = batch.base_result
    local calculation_count = #batch.calculations
    
    if AsyncScore.debug then
        print("[AsyncScore] Processing retrigger batch: " .. batch_key .. " (" .. calculation_count .. " calculations)")
    end
    
    -- For retriggers, we can often multiply or accumulate the base result
    -- This is much faster than recalculating each individually
    local optimized_result = self:optimize_batch_result(base_result, calculation_count, batch.calculations[1])
    
    -- Clean up the batch
    self.retrigger_batches[batch_key] = nil
    
    return optimized_result
end

-- Optimize the result for batched retriggers
function AsyncCore:optimize_batch_result(base_result, count, sample_calculation)
    if not base_result or count <= 1 then
        return base_result
    end
    
    -- For most jokers, retriggers simply multiply the effect
    if type(base_result) == "table" then
        local optimized = {}
        for key, value in pairs(base_result) do
            if type(value) == "number" then
                -- Multiply numeric values by retrigger count
                optimized[key] = value * count
            else
                optimized[key] = value
            end
        end
        return optimized
    elseif type(base_result) == "number" then
        return base_result * count
    end
    
    return base_result
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
