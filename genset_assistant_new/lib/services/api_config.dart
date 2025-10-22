// API Configuration for different environments
class ApiConfig {
  // 🔧 MEGA GENSET MIRROR API - Deployed on Netlify
  static const String baseUrl = 'https://backendmirror.netlify.app';

  // API endpoints (Netlify functions)
  static const String gensetEndpoint = '/.netlify/functions/gensets';

  // API Key for authentication
  static const String apiKey = 'MegaGenset2025!';

  // Full URLs
  static String get gensetApiUrl => '$baseUrl$gensetEndpoint';
}
