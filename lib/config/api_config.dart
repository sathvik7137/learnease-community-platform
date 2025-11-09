import 'package:flutter/foundation.dart';

/// API Configuration - Automatically selects correct backend URL
/// based on environment (development, production, etc.)
class ApiConfig {
  // ⚠️ CRITICAL: Replace with your REAL production server URL
  // DO NOT use ngrok in production! Options:
  // 1. Deploy to Railway: https://railway.app
  // 2. Deploy to Render: https://render.com
  // 3. Deploy to DigitalOcean: https://www.digitalocean.com
  // 4. Deploy to AWS EC2/Lightsail
  static const String _productionBaseUrl = 'https://api.learnease.com'; // ⚠️ CHANGE THIS!
  
  // Development/Local URLs
  static const String _developmentBaseUrl = 'http://localhost:8080';
  
  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    // In debug mode, use localhost for development
    if (kDebugMode) {
      return _developmentBaseUrl;
    }
    
    // In release mode, use production server
    return _productionBaseUrl;
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

