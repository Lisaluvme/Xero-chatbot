// Configuration Manager for Environment Setup
import 'package:flutter/foundation.dart';
import 'config_local.dart';
import 'config_staging.dart';
import 'config_production.dart';
import '../services/api_config.dart';

class ConfigManager {
  // Initialize configuration based on environment
  static void initialize({Environment? environment}) {
    // If no environment specified, try to determine from build mode
    if (environment == null) {
      // In debug mode, default to local
      // In profile/release mode, default to production
      if (kDebugMode) {
        environment = Environment.local;
      } else {
        environment = Environment.production;
      }
    }

    // Setup the appropriate configuration
    switch (environment) {
      case Environment.local:
        ConfigLocal.setup();
        break;
      case Environment.staging:
        ConfigStaging.setup();
        break;
      case Environment.production:
        ConfigProduction.setup();
        break;
    }

    // Print setup complete message
    print('✅ Configuration initialized for ${ApiConfig.environmentName} environment');
  }

  // Quick setup methods for different environments
  static void setupLocal() => initialize(environment: Environment.local);
  static void setupStaging() => initialize(environment: Environment.staging);
  static void setupProduction() => initialize(environment: Environment.production);

  // Get current configuration info
  static Map<String, dynamic> getCurrentConfig() {
    return {
      'environment': ApiConfig.environmentName,
      'baseUrl': ApiConfig.baseUrl,
      'backendUrl': ApiConfig.backendUrl,
      'isLocal': ApiConfig.isLocal,
      'isStaging': ApiConfig.isStaging,
      'isProduction': ApiConfig.isProduction,
      'apiKey': '${ApiConfig.apiKey.substring(0, 8)}...',
    };
  }

  // Print current configuration
  static void printCurrentConfig() {
    final config = getCurrentConfig();
    print('📋 Current Configuration:');
    config.forEach((key, value) {
      print('  $key: $value');
    });
  }

  // Environment switching utilities
  static void switchToLocal() {
    print('🔄 Switching to LOCAL environment...');
    setupLocal();
  }

  static void switchToStaging() {
    print('🔄 Switching to STAGING environment...');
    setupStaging();
  }

  static void switchToProduction() {
    print('🔄 Switching to PRODUCTION environment...');
    setupProduction();
  }

  // Fallback control utilities
  static void enableNetlifyFallback() {
    ApiConfig.enableAutoFallback();
  }

  static void disableNetlifyFallback() {
    ApiConfig.disableAutoFallback();
  }

  static Future<bool> testNetlifyConnection() async {
    return await ApiConfig.testNetlifyConnectivity();
  }

  static void forceLocalFallback() {
    ApiConfig.markNetlifyFailed();
    print('🔄 Forced local fallback - all requests will use local server');
  }

  static void resetNetlifyStatus() {
    ApiConfig.resetNetlifyStatus();
    print('🔄 Netlify status reset - will try Netlify again on next request');
  }

  // Get all available URLs
  static Map<String, String> getAllAvailableUrls() {
    return ApiConfig.getAllUrls();
  }

  // Quick setup for your specific use case
  static void setupWithLocalFallback() {
    // Setup staging/production with automatic fallback to local
    if (const bool.fromEnvironment('dart.vm.product')) {
      // Production build
      setupProduction();
    } else {
      // Debug build - use staging with fallback
      setupStaging();
    }

    // Enable fallback by default
    enableNetlifyFallback();

    print('🎯 Configured with automatic fallback to local server');
    print('💡 If Netlify fails, will automatically switch to: ${ApiConfig.getAllUrls()['alternative_local']}');
  }
}
