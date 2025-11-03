// Test script for the fallback mechanism
import '../services/api_config.dart';
import '../services/backend_service.dart';

class FallbackTester {
  static Future<void> testFallbackMechanism() async {
    print('🧪 Testing Fallback Mechanism...');
    print('================================');

    // Test 1: Initial state
    print('\n1️⃣ Initial Configuration:');
    ApiConfig.printConfig();

    // Test 2: Test Netlify connectivity
    print('\n2️⃣ Testing Netlify Connectivity:');
    final isReachable = await ApiConfig.testNetlifyConnectivity();
    print('Netlify reachable: $isReachable');

    // Test 3: Get backend URL (should trigger connectivity test)
    print('\n3️⃣ Getting Backend URL:');
    final backendUrl = await BackendService.getBackendUrl();
    print('Backend URL: $backendUrl');

    // Test 4: Force fallback
    print('\n4️⃣ Forcing Local Fallback:');
    ApiConfig.markNetlifyFailed();
    final fallbackUrl = await BackendService.getBackendUrl();
    print('Fallback URL: $fallbackUrl');

    // Test 5: Reset and try again
    print('\n5️⃣ Resetting Netlify Status:');
    ApiConfig.resetNetlifyStatus();
    final resetUrl = await BackendService.getBackendUrl();
    print('Reset URL: $resetUrl');

    // Test 6: Show all URLs
    print('\n6️⃣ All Available URLs:');
    final allUrls = ApiConfig.getAllUrls();
    allUrls.forEach((key, value) {
      print('  $key: $value');
    });

    print('\n✅ Fallback Test Complete!');
  }

  static Future<void> simulateNetlifyFailure() async {
    print('💥 Simulating Netlify Failure...');

    // Force mark Netlify as failed
    ApiConfig.markNetlifyFailed();

    // Try to get backend URL - should use fallback
    final url = await BackendService.getBackendUrl();
    print('URL with forced fallback: $url');

    // Test connectivity again
    final reachable = await ApiConfig.testNetlifyConnectivity();
    print('Netlify reachable after reset: $reachable');
  }

  static void showUsageInstructions() {
    print('📖 Fallback System Usage:');
    print('========================');
    print('1. Normal operation: App tries Netlify first');
    print('2. If Netlify fails: Automatically switches to local server');
    print('3. Local server URL: http://localhost:8000/');
    print('4. To force fallback: ApiConfig.markNetlifyFailed()');
    print('5. To reset: ApiConfig.resetNetlifyStatus()');
    print('6. Check status: ApiConfig.printConfig()');
  }
}
