// API Configuration for different environments
class ApiConfig {
  // 🔧 MEGA GENSET MIRROR API - Local Development Server
  static const String baseUrl = 'http://localhost:3002/';

  // API Key for authentication
  static const String apiKey = 'MegaGenset2025!';

  // Full URLs for mirror API
  static String get gensetApiUrl => baseUrl;
}
