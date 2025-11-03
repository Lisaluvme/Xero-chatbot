// API Configuration for different environments
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

enum Environment {
  local,
  staging,
  production,
}

class ApiConfig {
  // Current environment - change this to switch environments
  static Environment currentEnvironment = Environment.local;

  // 🔧 MEGA GENSET MIRROR API - Local Development Server
  static const String _localBaseUrl = 'http://localhost:3002/';

  // 🔧 ALTERNATIVE LOCAL BACKEND - Your custom local server (for mobile testing)
  // Use your computer's IP address instead of localhost for mobile devices
  static const String _alternativeLocalUrl = 'http://192.168.50.241:3002/'; // Your computer's IP address and correct port

  // 🔧 STAGING BACKEND - Staging Environment
  static const String _stagingBaseUrl = 'https://backendmirror-staging.netlify.app/.netlify/functions';

  // 🔧 PRODUCTION BACKEND - Production Environment
  static const String _productionBaseUrl = 'https://backendmirror.netlify.app/.netlify/functions';

  // API Key for authentication
  static const String apiKey = 'MegaGenset2025!';

  // Fallback configuration
  static bool _netlifyFailed = false;
  static bool _autoFallbackEnabled = true;

  // Get base URL based on current environment with fallback logic
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.local:
        return _getLocalUrlForDevice();
      case Environment.staging:
        return _getStagingUrlWithFallback();
      case Environment.production:
        return _getProductionUrlWithFallback();
    }
  }

  // Smart fallback for staging - try Netlify first, fallback to local
  static String _getStagingUrlWithFallback() {
    if (_autoFallbackEnabled && _netlifyFailed) {
      debugPrint('🔄 Netlify failed, using local fallback for staging');
      return _alternativeLocalUrl;
    }
    return _stagingBaseUrl;
  }

  // Smart fallback for production - try Netlify first, fallback to local
  static String _getProductionUrlWithFallback() {
    if (_autoFallbackEnabled && _netlifyFailed) {
      debugPrint('🔄 Netlify failed, using local fallback for production');
      return _alternativeLocalUrl;
    }
    return _productionBaseUrl;
  }

  // Detect if running on physical device and use appropriate local URL
  static String _getLocalUrlForDevice() {
    // Check if running on Android/iOS (physical device or emulator)
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile devices, use the computer's IP address
      debugPrint('📱 Running on mobile device, using computer IP: $_alternativeLocalUrl');
      return _alternativeLocalUrl;
    } else {
      // For desktop/emulator, use localhost
      debugPrint('💻 Running on desktop/emulator, using localhost: $_localBaseUrl');
      return _localBaseUrl;
    }
  }

  // Full URLs for mirror API
  static String get gensetApiUrl => baseUrl;

  // Backend service URLs (for Netlify functions or local server)
  static String get backendUrl {
    switch (currentEnvironment) {
      case Environment.local:
        return _getLocalUrlForDevice();
      case Environment.staging:
        return _getStagingUrlWithFallback();
      case Environment.production:
        return _getProductionUrlWithFallback();
    }
  }

  // Environment-specific configurations
  static bool get isLocal => currentEnvironment == Environment.local;
  static bool get isStaging => currentEnvironment == Environment.staging;
  static bool get isProduction => currentEnvironment == Environment.production;

  // Debug information
  static String get environmentName {
    switch (currentEnvironment) {
      case Environment.local:
        return 'LOCAL';
      case Environment.staging:
        return 'STAGING';
      case Environment.production:
        return 'PRODUCTION';
    }
  }

  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Retry configurations
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Fallback control methods
  static void enableAutoFallback() {
    _autoFallbackEnabled = true;
    debugPrint('✅ Auto fallback to local server enabled');
  }

  static void disableAutoFallback() {
    _autoFallbackEnabled = false;
    debugPrint('❌ Auto fallback to local server disabled');
  }

  static void markNetlifyFailed() {
    _netlifyFailed = true;
    debugPrint('❌ Netlify marked as failed - will use local fallback');
  }

  static void resetNetlifyStatus() {
    _netlifyFailed = false;
    debugPrint('🔄 Netlify status reset');
  }

  // Test Netlify connectivity
  static Future<bool> testNetlifyConnectivity() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(_productionBaseUrl));
      final response = await request.close();

      final success = response.statusCode == 200;
      client.close();

      if (success) {
        resetNetlifyStatus();
        debugPrint('✅ Netlify is reachable');
      } else {
        markNetlifyFailed();
        debugPrint('❌ Netlify returned status ${response.statusCode}');
      }

      return success;
    } catch (e) {
      markNetlifyFailed();
      debugPrint('❌ Netlify connectivity test failed: $e');
      return false;
    }
  }

  // Print current configuration (for debugging)
  static void printConfig() {
    debugPrint('🚀 API Config - Environment: $environmentName');
    debugPrint('🌐 Base URL: $baseUrl');
    debugPrint('🔧 Backend URL: $backendUrl');
    debugPrint('🔄 Auto Fallback: ${_autoFallbackEnabled ? 'ENABLED' : 'DISABLED'}');
    debugPrint('📡 Netlify Status: ${_netlifyFailed ? 'FAILED' : 'OK'}');
    debugPrint('🔑 API Key: ${apiKey.substring(0, 8)}...');
  }

  // Get all available URLs for debugging
  static Map<String, String> getAllUrls() {
    return {
      'local': _localBaseUrl,
      'alternative_local': _alternativeLocalUrl,
      'staging': _stagingBaseUrl,
      'production': _productionBaseUrl,
      'current_base': baseUrl,
      'current_backend': backendUrl,
    };
  }

  // Helper method to get network IP address for current machine
  static Future<String?> getCurrentNetworkIP() async {
    try {
      // Try to find the local network IP
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Look for IPv4 addresses that are not localhost
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting network IP: $e');
      return null;
    }
  }

  // Update the alternative local URL with detected IP
  static Future<bool> updateNetworkIP() async {
    final ip = await getCurrentNetworkIP();
    if (ip != null) {
      // Note: This would require making _alternativeLocalUrl non-const
      // For now, we'll just log the detected IP
      debugPrint('🔍 Detected network IP: $ip');
      debugPrint('💡 Update _alternativeLocalUrl to: http://$ip:3002/');
      return true;
    }
    return false;
  }
}
