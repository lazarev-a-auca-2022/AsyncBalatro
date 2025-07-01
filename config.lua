-- AsyncScore Configuration
return {
    -- Performance settings
    complexity_threshold = 1,          -- Number of jokers before async kicks in
    max_operations_per_frame = 50,      -- Max operations per frame in async mode
    performance_monitoring = true,      -- Enable performance monitoring
    
    -- Async processing settings
    chunk_size = 5,                     -- Cards processed per chunk
    async_timeout = 1.0,               -- Max time for async operation (seconds)
    fallback_mode = true,              -- Fallback to sync if async fails
    
    -- Caching settings
    enable_caching = true,             -- Enable result caching
    cache_size_limit = 1000,           -- Max cached results
    cache_ttl = 300,                   -- Cache time-to-live (seconds)
    
    -- Debug settings
    debug_logging = false,             -- Enable debug output
    performance_reports = true,        -- Generate performance reports
    report_interval = 30,              -- Report interval (seconds)
    
    -- Compatibility settings
    cryptid_compatibility = true,      -- Enable Cryptid-specific optimizations
    talisman_compatibility = true,     -- Enable Talisman number system support
    auto_detect_complex_jokers = true, -- Automatically detect complex jokers
    
    -- Advanced settings
    adaptive_threshold = true,         -- Adapt threshold based on performance
    prioritize_calculation = true,     -- Prioritize important calculations
    memory_management = true,          -- Enable memory optimization
    
    -- UI settings
    show_performance_overlay = false,  -- Show performance info overlay
    overlay_position = "top_right",    -- Position of overlay
    
    -- Experimental features
    predictive_caching = false,        -- Predict and pre-cache likely calculations
    distributed_processing = false,    -- Distribute calculations across multiple coroutines
    smart_batching = true             -- Intelligently batch similar calculations
}
