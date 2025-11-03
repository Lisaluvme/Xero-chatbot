// Local Development Configuration
import '../services/api_config.dart';

class ConfigLocal {
  static void setup() {
    // Set environment to local
    ApiConfig.currentEnvironment = Environment.local;

    // Local development specific configurations
    const localConfig = {
      'debug': true,
      'logLevel': 'verbose',
      'enableMockData': false,
      'useLocalBackend': true,
      'localBackendUrl': 'http://localhost:3002/',
      'localBackendPort': 3002,
    };

    // Print configuration for debugging
    ApiConfig.printConfig();
    print('🔧 Local Config: $localConfig');
  }

  // Local development helpers
  static String getLocalBackendUrl() {
    return 'http://localhost:3002/';
  }

  static String getLocalBackendWithEndpoint(String endpoint) {
    return 'http://localhost:3002/$endpoint';
  }

  // Instructions for setting up local backend
  static const String setupInstructions = '''
  🚀 LOCAL BACKEND SETUP INSTRUCTIONS:

  1. Install Node.js and npm
  2. Clone the backend repository
  3. Install dependencies: npm install
  4. Start the local server: npm start
  5. Server should be running on http://localhost:3002

  📝 If you need to change the port:
  - Update the port in this config file
  - Update the server configuration
  - Restart the Flutter app

  🔧 For mobile testing:
  - Use your computer's IP address instead of localhost
  - Example: http://192.168.1.100:3002
  - Make sure your phone and computer are on the same network
  ''';
}
