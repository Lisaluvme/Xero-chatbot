import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MirrorApiService {
  // Uses the configured Ngrok URL from ApiConfig
  static String get baseUrl => ApiConfig.gensetApiUrl;

  Future<List<dynamic>?> fetchGensetList() async {
    final uri = Uri.parse(baseUrl);

    // Debug logging
    print('🔍 [MirrorApiService] Sending GET request to: $baseUrl');

    try {
      final client = http.Client();
      try {
        var currentUri = uri;

        // Handle redirects manually (up to 5 redirects)
        for (var i = 0; i < 5; i++) {
          print('🔄 [MirrorApiService] Attempt ${i + 1}: ${currentUri}');

          final request = http.Request('GET', currentUri);

          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);

          print('📥 [MirrorApiService] Response status: ${response.statusCode}');
          print('📥 [MirrorApiService] Response headers: ${response.headers}');

          // Handle redirects
          if (response.statusCode == 301 || response.statusCode == 302 ||
              response.statusCode == 307 || response.statusCode == 308) {
            final location = response.headers['location'];
            if (location != null) {
              currentUri = currentUri.resolve(location);
              print('🔀 [MirrorApiService] Following redirect to: $currentUri');
              continue; // Try again with new URL
            } else {
              print('❌ [MirrorApiService] Redirect without location header');
              return null;
            }
          }

          // Handle successful response
          if (response.statusCode == 200) {
            print('📄 [MirrorApiService] Response body: ${response.body}');
            final data = jsonDecode(response.body) as List<dynamic>;
            print('✅ [MirrorApiService] Successfully parsed ${data.length} gensets');
            return data;
          } else {
            print('❌ [MirrorApiService] Failed with status: ${response.statusCode} - ${response.body}');
            return null;
          }
        }

        print('❌ [MirrorApiService] Too many redirects');
        return null;

      } finally {
        client.close();
      }
    } catch (e) {
      print('⚠️ [MirrorApiService] Error fetching genset list: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchGensetDataByUtoken(String utoken) async {
    final uri = Uri.parse(baseUrl);

    // Debug logging
    print('🔍 [MirrorApiService] Sending request to: $baseUrl');
    print('🔍 [MirrorApiService] Request body: {"utoken": "$utoken"}');

    try {
      final client = http.Client();
      try {
        var currentUri = uri;
        var requestBody = jsonEncode({'utoken': utoken});
        var headers = {'Content-Type': 'application/json'};

        // Handle redirects manually (up to 5 redirects)
        for (var i = 0; i < 5; i++) {
          print('🔄 [MirrorApiService] Attempt ${i + 1}: ${currentUri}');

          final request = http.Request('POST', currentUri)
            ..headers.addAll(headers)
            ..body = requestBody;

          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);

          print('📥 [MirrorApiService] Response status: ${response.statusCode}');
          print('📥 [MirrorApiService] Response headers: ${response.headers}');

          // Handle redirects
          if (response.statusCode == 301 || response.statusCode == 302 ||
              response.statusCode == 307 || response.statusCode == 308) {
            final location = response.headers['location'];
            if (location != null) {
              currentUri = currentUri.resolve(location);
              print('🔀 [MirrorApiService] Following redirect to: $currentUri');
              continue; // Try again with new URL
            } else {
              print('❌ [MirrorApiService] Redirect without location header');
              return null;
            }
          }

          // Handle successful response
          if (response.statusCode == 200) {
            print('📄 [MirrorApiService] Response body: ${response.body}');
            final data = jsonDecode(response.body);
            return data;
          } else {
            print('❌ [MirrorApiService] Failed with status: ${response.statusCode} - ${response.body}');
            return null;
          }
        }

        print('❌ [MirrorApiService] Too many redirects');
        return null;

      } finally {
        client.close();
      }
    } catch (e) {
      print('⚠️ [MirrorApiService] Error fetching genset: $e');
      return null;
    }
  }
}
