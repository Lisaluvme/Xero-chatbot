// Production Environment Configuration
import '../services/api_config.dart';

class ConfigProduction {
  static void setup() {
    // Set environment to production
    ApiConfig.currentEnvironment = Environment.production;

    // Production specific configurations
    const productionConfig = {
      'debug': false,
      'logLevel': 'error',
      'enableMockData': false,
      'useProductionBackend': true,
      'productionBackendUrl': 'https://backendmirror.netlify.app/.netlify/functions',
    };

    // Print configuration for debugging (only in debug mode)
    if (ApiConfig.isProduction) {
      print('🔧 Production Config: $productionConfig');
    }
    ApiConfig.printConfig();
  }

  // Production environment helpers
  static String getProductionBackendUrl() {
    return 'https://backendmirror.netlify.app/.netlify/functions';
  }

  static String getProductionBackendWithEndpoint(String endpoint) {
    return 'https://backendmirror.netlify.app/.netlify/functions/$endpoint';
  }
}
