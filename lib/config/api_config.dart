import 'package:flutter/foundation.dart';

/// API Configuration - Automatically selects correct backend URL
/// based on environment (development, production, etc.)
class ApiConfig {
  // Production URLs
  static const String _productionBaseUrl = 'https://154d8478032a.ngrok-free.app';
  
  // Development/Local URLs
  static const String _developmentBaseUrl = 'http://localhost:8080';
  
  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    // In debug mode, use localhost for development
    if (kDebugMode) {
      return _developmentBaseUrl;
    }
    
    // In release mode, use production ngrok URL
    return _productionBaseUrl;
  }
  
  /// Alternative: Check if running on web (Firebase)
  /// Returns ngrok URL for web, localhost for debug
  static String get webBaseUrl {
    // For Firebase Hosting (web), always use ngrok
    // For local development, use localhost
    if (kDebugMode) {
      return _developmentBaseUrl;
    }
    return _productionBaseUrl;
  }
  
  /// Update production URL dynamically
  /// Call this if you need to change the ngrok URL at runtime
  static String updateProductionUrl(String newUrl) {
    return newUrl;
  }
}

