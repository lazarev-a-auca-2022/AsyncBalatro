-- English localization for AsyncScore
return {
    descriptions = {
        Mod = {
            AsyncScore = {
                name = "AsyncScore",
                text = {
                    "Asynchronous scoring optimization",
                    "Reduces lag in heavily modded games",
                    "Compatible with {C:attention}Cryptid{} and {C:attention}Talisman{}"
                }
            }
        }
    },
    
    misc = {
        async_score = {
            config_title = "AsyncScore Configuration",
            
            -- Setting names
            complexity_threshold_name = "Async Threshold",
            performance_monitoring_name = "Performance Monitoring", 
            debug_logging_name = "Debug Logging",
            fallback_mode_name = "Fallback Mode",
            cache_enabled_name = "Enable Caching",
            adaptive_threshold_name = "Adaptive Threshold",
            show_overlay_name = "Performance Overlay",
            
            -- Setting descriptions
            complexity_threshold_desc = "Number of jokers before async processing activates",
            performance_monitoring_desc = "Monitor and log performance metrics",
            debug_logging_desc = "Enable detailed debug logging to console",
            fallback_mode_desc = "Automatically fallback to sync calculation if async fails",
            cache_enabled_desc = "Cache calculation results for better performance",
            adaptive_threshold_desc = "Automatically adjust threshold based on performance",
            show_overlay_desc = "Show performance information overlay in-game",
            
            -- Status messages
            status_enabled = "AsyncScore: {C:green}Enabled{}",
            status_disabled = "AsyncScore: {C:red}Disabled{}",
            cryptid_detected = "Cryptid mod: {C:green}Detected{}",
            talisman_detected = "Talisman mod: {C:green}Detected{}",
            mod_not_detected = "Mod: {C:inactive}Not Detected{}",
            
            -- Performance messages
            performance_good = "Performance: {C:green}Good{}",
            performance_poor = "Performance: {C:attention}Poor{}", 
            performance_critical = "Performance: {C:red}Critical{}",
            
            -- Error messages
            error_calculation = "Calculation error in async mode",
            error_compatibility = "Compatibility issue detected",
            error_memory = "Memory limit exceeded",
            
            -- Debug messages
            debug_async_started = "Async calculation started",
            debug_async_completed = "Async calculation completed",
            debug_cache_hit = "Cache hit for calculation",
            debug_cache_miss = "Cache miss for calculation",
            debug_fallback = "Falling back to synchronous calculation",
            
            -- Performance overlay
            overlay_fps = "FPS: {C:attention}#1#{}",
            overlay_frame_time = "Frame: {C:attention}#1#ms{}",
            overlay_async_percent = "Async: {C:attention}#1#%{}",
            overlay_cache_hits = "Cache: {C:attention}#1#%{}",
            overlay_joker_count = "Jokers: {C:attention}#1#{}",
            
            -- Configuration tooltips
            tooltip_complexity = {
                "Lower values = more async processing",
                "Higher values = less async processing",
                "Recommended: 10-15 for most setups"
            },
            
            tooltip_monitoring = {
                "Tracks frame rates and calculation times",
                "Helps identify performance bottlenecks",
                "May slightly impact performance when enabled"
            },
            
            tooltip_fallback = {
                "Ensures calculations always complete",
                "Switches to sync mode if async fails",
                "Recommended to keep enabled"
            },
            
            -- Compatibility info
            compatibility_title = "Mod Compatibility",
            compatibility_cryptid = "Cryptid: Optimized for 100+ jokers",
            compatibility_talisman = "Talisman: BigNum/OmegaNum support",
            compatibility_other = "Other mods: Basic async support",
            
            -- Advanced settings
            advanced_title = "Advanced Settings",
            advanced_warning = "{C:red}Warning:{} Only modify if you understand the impact",
            
            chunk_size_name = "Calculation Chunk Size",
            chunk_size_desc = "Cards processed per async chunk (1-20)",
            
            cache_size_name = "Cache Size Limit", 
            cache_size_desc = "Maximum number of cached results (100-5000)",
            
            memory_management_name = "Memory Management",
            memory_management_desc = "Automatically clean up old calculations",
            
            -- Help text
            help_title = "AsyncScore Help",
            help_text = {
                "AsyncScore reduces lag during scoring by processing",
                "complex joker calculations asynchronously.",
                "",
                "{C:attention}Key Features:{}",
                "• Automatic lag detection and async activation",
                "• Cryptid joker optimization (100+ jokers)",  
                "• Talisman number system compatibility",
                "• Result caching for repeated calculations",
                "• Performance monitoring and reporting",
                "",
                "{C:attention}Recommended Settings:{}",
                "• Async Threshold: 10-15",
                "• Performance Monitoring: Enabled",
                "• Fallback Mode: Enabled",
                "• Caching: Enabled",
                "",
                "{C:attention}Troubleshooting:{}",
                "• If calculations seem incorrect, enable Fallback Mode",
                "• If still experiencing lag, lower Async Threshold",
                "• Enable Debug Logging to diagnose issues",
                "",
                "Visit the AsyncScore documentation for more help."
            }
        }
    }
}
