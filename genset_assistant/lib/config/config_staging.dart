// Staging Environment Configuration
import '../services/api_config.dart';

class ConfigStaging {
  static void setup() {
    // Set environment to staging
    ApiConfig.currentEnvironment = Environment.staging;

    // Staging specific configurations
    const stagingConfig = {
      'debug': true,
      'logLevel': 'info',
      'enableMockData': false,
      'useStagingBackend': true,
      'stagingBackendUrl': 'https://backendmirror-staging.netlify.app/.netlify/functions',
    };

    // Print configuration for debugging
    ApiConfig.printConfig();
    print('🔧 Staging Config: $stagingConfig');
  }

  // Staging environment helpers
  static String getStagingBackendUrl() {
    return 'https://backendmirror-staging.netlify.app/.netlify/functions';
  }

  static String getStagingBackendWithEndpoint(String endpoint) {
    return 'https://backendmirror-staging.netlify.app/.netlify/functions/$endpoint';
  }
}
