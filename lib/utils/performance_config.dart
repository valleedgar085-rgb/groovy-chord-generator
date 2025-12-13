/// Groovy Chord Generator
/// Performance Configuration
/// Optimized for Motorola devices and lower-end hardware

/// Performance constants for optimizing the app on lower-end devices
class PerformanceConfig {
  // List caching and rendering optimization
  static const double listCacheExtent = 100.0;
  // Grid caching (currently unified with listCacheExtent via getCacheExtent())
  static const double gridCacheExtent = 100.0;
  
  // Maximum items to keep in memory (for future implementation)
  // TODO: Implement history trimming when count exceeds maxHistoryItems
  static const int maxHistoryItems = 20;
  // TODO: Implement pagination when favorites exceed maxFavoritesDisplayed
  static const int maxFavoritesDisplayed = 50;
  
  // Animation optimization flags (for future conditional rendering)
  // TODO: Use these flags to conditionally enable/disable heavy animations
  static const bool enableHeavyAnimations = true; // Set to false on very low-end devices
  static const bool enableShadows = true; // Set to false to reduce GPU load
  
  // Memory optimization flags (currently applied unconditionally)
  // These flags document the optimization strategy for reference
  static const bool enableRepaintBoundaries = true;
  static const bool enableCacheExtent = true;
  
  // Determines if the device might be lower-end based on available info
  // This is a simple heuristic - in production you'd use platform channels
  static bool get isLowEndDevice {
    // Default to false, but can be overridden by checking actual device specs
    // via platform channels if needed
    return false;
  }
  
  // Get optimized cache extent based on device capability
  static double getCacheExtent() {
    return isLowEndDevice ? 50.0 : listCacheExtent;
  }
  
  // Get whether to enable heavy animations based on device capability
  static bool shouldEnableHeavyAnimations() {
    return !isLowEndDevice && enableHeavyAnimations;
  }
  
  // Get whether to enable shadows based on device capability
  static bool shouldEnableShadows() {
    return !isLowEndDevice && enableShadows;
  }
}
