import 'package:flutter/foundation.dart';

/// API Configuration - Automatically selects correct backend URL
/// based on environment (development, production, etc.)
class ApiConfig {
  // ✅ Production server deployed on Render.com
  // Backend API: https://learnease-community-platform.onrender.com
  // MongoDB: Connected and persistent
  // Users: 8 migrated users ready
  static const String _productionBaseUrl = 'https://learnease-community-platform.onrender.com';
  
  // Development/Local URLs
  static const String _developmentBaseUrl = 'http://localhost:8080';
  
  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    // TEMPORARY: Always use production for testing
    // This ensures the app connects to Render server even in debug mode
    return _productionBaseUrl;
    
    // ORIGINAL CODE (uncomment for local development):
    // if (kDebugMode) {
    //   return _developmentBaseUrl;
    // }
    // return _productionBaseUrl;
  }
  
  /// Alternative: Check if running on web (Firebase)
  /// Returns production URL for web, localhost for debug
  static String get webBaseUrl {
    // For Firebase Hosting (web), always use production
    // For local development, use localhost
    if (kDebugMode) {
      return _developmentBaseUrl;
    }
    return _productionBaseUrl;
  }
  
  /// Health check endpoint
  static String get healthCheck => '$baseUrl/health';
  
  /// Validate if production URL is properly configured
  static bool get isProductionConfigured {
    return _productionBaseUrl != 'https://api.learnease.com' &&
           !_productionBaseUrl.contains('ngrok') &&
           _productionBaseUrl.startsWith('https://');
  }
}

