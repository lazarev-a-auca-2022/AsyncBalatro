# AsyncScore - Asynchronous Scoring Optimization for Balatro

## Overview

AsyncScore is a performance optimization mod for the card game Balatro that implements asynchronous scoring calculations to reduce lag in heavily modded games. The mod is built using Lua and integrates with the Steamodded modding framework. It's specifically designed to work alongside popular mods like Cryptid and Talisman while maintaining compatibility with any Steamodded-based modification.

## System Architecture

### Core Framework
- **Language**: Lua scripting for Balatro game engine
- **Modding Framework**: Steamodded-based architecture
- **Processing Model**: Coroutine-based asynchronous execution
- **Priority System**: Low priority (-1000) to ensure other mods load first

### Performance Architecture
- **Adaptive Processing**: Intelligent threshold detection that switches between sync/async modes
- **Non-blocking Calculations**: Coroutine implementation prevents main thread blocking
- **Dynamic Performance Monitoring**: Real-time FPS and timing analysis
- **Fallback Safety**: Automatic reversion to synchronous processing when issues occur

## Key Components

### 1. Asynchronous Scoring Engine
- **Purpose**: Handles complex scoring calculations without blocking gameplay
- **Implementation**: Lua coroutines for smooth execution
- **Trigger**: Automatically activates when performance degrades below thresholds

### 2. Mod Compatibility Layer
- **Cryptid Integration**: Optimized for 100+ overpowered jokers
- **Talisman Support**: Full BigNum and OmegaNum scoring system compatibility
- **Universal Design**: Works with any Steamodded-based mod

### 3. Performance Monitoring System
- **Real-time Metrics**: FPS tracking and calculation timing
- **Debug Logging**: Comprehensive logging for troubleshooting
- **Performance Reports**: Periodic analysis and optimization recommendations

### 4. Configuration Interface
- **In-game UI**: Easy-to-use configuration management
- **Dynamic Settings**: Runtime adjustment of performance parameters
- **User Preferences**: Customizable threshold and behavior settings

## Data Flow

1. **Game State Monitoring**: Continuous monitoring of game performance metrics
2. **Threshold Detection**: Automated detection when scoring calculations impact performance
3. **Async Activation**: Switch to coroutine-based processing when thresholds are exceeded
4. **Score Calculation**: Non-blocking execution of complex scoring logic
5. **Result Integration**: Seamless integration of async results back into game state
6. **Performance Feedback**: Continuous monitoring and adjustment of processing mode

## External Dependencies

### Required Dependencies
- **Lovely Injector**: Core injection framework (version.dll)
- **Steamodded**: Primary modding framework (minimum v1.0.0)

### Recommended Dependencies
- **Talisman**: Extended number system support for large scores
- **Cryptid**: Popular joker expansion mod (primary optimization target)

### Compatibility
- **Universal Mod Support**: Designed to work with any Steamodded-based modification
- **No Conflicts**: Architecture designed to avoid conflicts with other mods

## Deployment Strategy

### Installation Process
1. **File Placement**: Extract to `%AppData%/Balatro/Mods/AsyncScore/`
2. **Directory Structure**: Maintains organized folder hierarchy with lib/ and localization/ subdirectories
3. **Load Order**: Low priority (-1000) ensures other mods initialize first
4. **Verification**: In-game mod menu confirmation of successful installation

### Configuration Management
- **Default Settings**: Sensible defaults for immediate functionality
- **Runtime Configuration**: In-game UI for user customization
- **Performance Profiles**: Adaptive settings based on system capabilities

## Changelog

```
Changelog:
- June 30, 2025. Initial setup
- June 30, 2025. Fixed module instantiation crash - properly implemented constructor pattern for core modules
- June 30, 2025. Fixed localization crash - restructured mod description format for Balatro compatibility
```

## User Preferences

```
Preferred communication style: Simple, everyday language.
```