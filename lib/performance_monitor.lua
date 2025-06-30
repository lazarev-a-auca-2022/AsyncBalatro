-- Performance monitoring and metrics collection
local PerformanceMonitor = {}

function PerformanceMonitor:new()
    local obj = {
        enabled = true,
        frame_times = {},
        max_frame_history = 60,
        performance_threshold = 1/30, -- 30 FPS threshold
        poor_performance_count = 0,
        poor_performance_threshold = 5,
        calculation_times = {},
        total_calculations = 0,
        async_calculations = 0,
        sync_calculations = 0,
        last_report_time = 0,
        report_interval = 30 -- Report every 30 seconds
    }
    setmetatable(obj, {__index = self})
    return obj
end

-- Initialize performance monitoring
function PerformanceMonitor:init()
    self.frame_times = {}
    self.calculation_times = {}
    self.last_report_time = love.timer.getTime()
    
    if AsyncScore.debug then
        print("[AsyncScore] Performance monitoring initialized")
    end
end

-- Update performance metrics
function PerformanceMonitor:update(dt)
    if not self.enabled then return end
    
    -- Record frame time
    self:record_frame_time(dt)
    
    -- Check for poor performance
    self:check_performance()
    
    -- Generate periodic reports
    self:check_report_time()
end

-- Record frame timing
function PerformanceMonitor:record_frame_time(dt)
    table.insert(self.frame_times, dt)
    
    -- Keep only recent frame times
    if #self.frame_times > self.max_frame_history then
        table.remove(self.frame_times, 1)
    end
end

-- Check if performance is poor
function PerformanceMonitor:is_performance_poor()
    if #self.frame_times < 10 then return false end
    
    -- Check recent frame times
    local slow_frames = 0
    local recent_frames = math.min(#self.frame_times, 10)
    
    for i = #self.frame_times - recent_frames + 1, #self.frame_times do
        if self.frame_times[i] > self.performance_threshold then
            slow_frames = slow_frames + 1
        end
    end
    
    return slow_frames >= 3 -- 3 out of 10 frames are slow
end

-- Check performance and update counters
function PerformanceMonitor:check_performance()
    if self:is_performance_poor() then
        self.poor_performance_count = self.poor_performance_count + 1
    else
        self.poor_performance_count = math.max(0, self.poor_performance_count - 1)
    end
end

-- Record calculation timing
function PerformanceMonitor:record_calculation(calc_type, duration, was_async)
    self.total_calculations = self.total_calculations + 1
    
    if was_async then
        self.async_calculations = self.async_calculations + 1
    else
        self.sync_calculations = self.sync_calculations + 1
    end
    
    -- Store calculation time data
    if not self.calculation_times[calc_type] then
        self.calculation_times[calc_type] = {}
    end
    
    table.insert(self.calculation_times[calc_type], {
        duration = duration,
        async = was_async,
        timestamp = love.timer.getTime()
    })
    
    -- Keep only recent calculation times
    local max_calc_history = 100
    if #self.calculation_times[calc_type] > max_calc_history then
        table.remove(self.calculation_times[calc_type], 1)
    end
end

-- Get average frame time
function PerformanceMonitor:get_average_frame_time()
    if #self.frame_times == 0 then return 0 end
    
    local total = 0
    for _, ft in ipairs(self.frame_times) do
        total = total + ft
    end
    
    return total / #self.frame_times
end

-- Get current FPS
function PerformanceMonitor:get_fps()
    local avg_frame_time = self:get_average_frame_time()
    if avg_frame_time <= 0 then return 0 end
    return 1 / avg_frame_time
end

-- Get performance statistics
function PerformanceMonitor:get_stats()
    return {
        fps = self:get_fps(),
        avg_frame_time = self:get_average_frame_time(),
        poor_performance_count = self.poor_performance_count,
        total_calculations = self.total_calculations,
        async_calculations = self.async_calculations,
        sync_calculations = self.sync_calculations,
        async_percentage = self.total_calculations > 0 and 
                          (self.async_calculations / self.total_calculations * 100) or 0
    }
end

-- Check if it's time for a performance report
function PerformanceMonitor:check_report_time()
    local current_time = love.timer.getTime()
    
    if current_time - self.last_report_time >= self.report_interval then
        self:generate_report()
        self.last_report_time = current_time
    end
end

-- Generate performance report
function PerformanceMonitor:generate_report()
    if not AsyncScore.debug then return end
    
    local stats = self:get_stats()
    
    print(string.format("[AsyncScore] Performance Report:"))
    print(string.format("  FPS: %.1f", stats.fps))
    print(string.format("  Avg Frame Time: %.3fms", stats.avg_frame_time * 1000))
    print(string.format("  Total Calculations: %d", stats.total_calculations))
    print(string.format("  Async: %d (%.1f%%)", stats.async_calculations, stats.async_percentage))
    print(string.format("  Sync: %d", stats.sync_calculations))
    print(string.format("  Poor Performance Events: %d", stats.poor_performance_count))
end

-- Start timing a calculation
function PerformanceMonitor:start_timing(calc_id)
    if not self.timing_data then
        self.timing_data = {}
    end
    
    self.timing_data[calc_id] = love.timer.getTime()
end

-- End timing a calculation
function PerformanceMonitor:end_timing(calc_id, calc_type, was_async)
    if not self.timing_data or not self.timing_data[calc_id] then
        return
    end
    
    local duration = love.timer.getTime() - self.timing_data[calc_id]
    self:record_calculation(calc_type, duration, was_async)
    
    self.timing_data[calc_id] = nil
end

-- Get calculation performance for specific type
function PerformanceMonitor:get_calculation_stats(calc_type)
    local calc_data = self.calculation_times[calc_type]
    if not calc_data or #calc_data == 0 then
        return nil
    end
    
    local total_duration = 0
    local async_count = 0
    local sync_count = 0
    
    for _, data in ipairs(calc_data) do
        total_duration = total_duration + data.duration
        if data.async then
            async_count = async_count + 1
        else
            sync_count = sync_count + 1
        end
    end
    
    return {
        count = #calc_data,
        avg_duration = total_duration / #calc_data,
        async_count = async_count,
        sync_count = sync_count,
        async_percentage = async_count / #calc_data * 100
    }
end

return function()
    return PerformanceMonitor:new()
end
