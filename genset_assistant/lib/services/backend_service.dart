import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genset_model.dart';
import 'api_config.dart';
import 'airtable_service.dart';
import 'customer_mapping_service.dart';

/// Service for connecting to backend servers with automatic fallback
/// Supports Netlify functions and local development servers
/// Includes SmartGen API caching for improved performance
class BackendService {
  // Track if we've tested connectivity
  static bool _connectivityTested = false;
  static bool _usingFallback = false;

  // Caching configuration
  static const String _cacheKey = 'smartgen_genset_cache';
  static const String _cacheTimestampKey = 'smartgen_cache_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  // SmartGen API endpoint
  static const String _smartGenUrl = 'https://www.smartgencloudplus.com/yewu/third/genset/list';
  static const String _smartGenUtoken = 'bebf6914640ec3ed6bf00398fb7969da';

  // Master token that grants access to all gensets
  static const String _masterToken = 'bebf6914640ec3ed6bf00398fb7969da';

  /// Gets the backend URL with automatic fallback logic
  static Future<String> getBackendUrl() async {
    // Test connectivity on first call
    if (!_connectivityTested) {
      await _testAndSetupBackendConnectivity();
      _connectivityTested = true;
    }

    final url = ApiConfig.backendUrl;
    print('🌐 Using backend URL: $url');
    if (_usingFallback) {
      print('🔄 Using local fallback server (Netlify unavailable)');
    } else {
      print('💡 This URL points to Netlify serverless functions');
    }
    return url;
  }

  /// Test backend connectivity and setup fallback if needed
  static Future<void> _testAndSetupBackendConnectivity() async {
    print('🔍 Testing backend connectivity...');

    // Only test Netlify connectivity if not in local environment
    if (!ApiConfig.isLocal) {
      final netlifyReachable = await ApiConfig.testNetlifyConnectivity();

      if (!netlifyReachable) {
        _usingFallback = true;
        print('⚠️ Netlify is not reachable, switching to local server fallback');
        print('🏠 Local server should be running on: ${ApiConfig.getAllUrls()['alternative_local']}');
      } else {
        _usingFallback = false;
        print('✅ Netlify is reachable, using primary backend');
      }
    } else {
      print('🏠 Using local development environment');
    }
  }

  /// Force refresh backend connectivity test
  static Future<void> refreshConnectivity() async {
    _connectivityTested = false;
    _usingFallback = false;
    await getBackendUrl();
  }

  /// Check if cached data is still valid
  static Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference < _cacheDuration;
    } catch (e) {
      print('❌ Error checking cache validity: $e');
      return false;
    }
  }

  /// Get cached genset data
  static Future<List<Genset>?> _getCachedGensets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) return null;

      final data = jsonDecode(cachedData);
      if (data is List) {
        final gensets = data.map((item) => Genset.fromJson(item)).toList();
        print('📦 Loaded ${gensets.length} gensets from cache');
        return gensets;
      }
      return null;
    } catch (e) {
      print('❌ Error loading cached data: $e');
      return null;
    }
  }

  /// Cache genset data
  static Future<void> _cacheGensets(List<Genset> gensets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = gensets.map((genset) => genset.toJson()).toList();
      final jsonData = jsonEncode(data);

      await prefs.setString(_cacheKey, jsonData);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('💾 Cached ${gensets.length} gensets (expires in ${_cacheDuration.inMinutes} minutes)');
    } catch (e) {
      print('❌ Error caching data: $e');
    }
  }

  /// Clear cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Fetch gensets from SmartGen API directly (with caching)
  static Future<List<Genset>> fetchGensetsFromSmartGen({bool forceRefresh = false}) async {
    try {
      // Check cache first (unless force refresh)
      if (!forceRefresh && await _isCacheValid()) {
        final cachedData = await _getCachedGensets();
        if (cachedData != null) {
          print('⚡ Using cached SmartGen data');
          return cachedData;
        }
      }

      print('🌐 Fetching fresh data from SmartGen API...');
      print('📡 URL: $_smartGenUrl?utoken=$_smartGenUtoken&page=1&per_page=10');

      final response = await http.get(
        Uri.parse('$_smartGenUrl?utoken=$_smartGenUtoken&page=1&per_page=10'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully fetched data from SmartGen API');

        // Parse the SmartGen response format: data.list contains the gensets array
        if (data['data'] != null && data['data']['list'] != null && data['data']['list'] is List) {
          final gensets = (data['data']['list'] as List).map((item) => Genset.fromSmartGenJson(item)).toList();
          print('📊 Parsed ${gensets.length} gensets from SmartGen API');

          // Cache the data
          await _cacheGensets(gensets);

          return gensets;
        } else {
          throw Exception('Invalid SmartGen response format: Expected data.list array');
        }
      } else {
        print('❌ SmartGen API request failed with status ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw _getErrorFromStatusCode(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw Exception('Network connection failed. Please check your internet connection.\nError: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format from SmartGen API. The API may be returning unexpected data.\nError: $e');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error. Please check your network connection.\nError: $e');
    } catch (e) {
      if (e is Exception && e.toString().contains('BackendService')) {
        rethrow;
      }
      throw Exception('Unexpected error occurred while fetching from SmartGen API.\nError: $e');
    }
  }

  /// Makes a GET request to fetch gensets from SmartGen API (with caching)
  /// Filters gensets by user's token from database
  /// Falls back to backend server if SmartGen fails
  static Future<List<Genset>> fetchGensets({bool forceRefresh = false}) async {
    try {
      // Try SmartGen API first (with caching)
      print('🎯 Attempting to fetch gensets from SmartGen API with caching...');
      final smartGenGensets = await fetchGensetsFromSmartGen(forceRefresh: forceRefresh);

      // Filter gensets by user's token from database
      final filteredGensets = await _filterGensetsByUserToken(smartGenGensets);

      print('🎯 Filtered to ${filteredGensets.length} gensets matching user token');

      // If we got data from SmartGen, sync to Airtable in background
      if (filteredGensets.isNotEmpty) {
        _syncGensetsToAirtableInBackground(filteredGensets);
      }

      return filteredGensets;
    } catch (smartGenError) {
      print('⚠️ SmartGen API failed: $smartGenError');
      print('🔄 Falling back to backend server...');

      // Fallback to backend server
      try {
        final backendUrl = await getBackendUrl();
        final endpointUrl = '$backendUrl/gensets';

        print('🔄 Fetching gensets from backend: $endpointUrl');

        final response = await http.get(
          Uri.parse(endpointUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Successfully fetched gensets data from backend');

          if (data is List) {
            final gensets = data.map((item) => Genset.fromJson(item)).toList();
            print('📊 Parsed ${gensets.length} gensets from backend');
            return gensets;
          } else {
            throw Exception('Invalid response format: Expected list of gensets');
          }
        } else {
          print('❌ Backend request failed with status ${response.statusCode}');
          print('📄 Response body: ${response.body}');
          throw _getErrorFromStatusCode(response.statusCode, response.body);
        }
      } catch (backendError) {
        print('❌ Both SmartGen API and backend failed');
        print('SmartGen Error: $smartGenError');
        print('Backend Error: $backendError');
        throw Exception('Failed to fetch gensets from both SmartGen API and backend server.\n'
            'SmartGen Error: $smartGenError\n'
            'Backend Error: $backendError');
      }
    }
  }

  /// Filter gensets by user's token permissions from database
  static Future<List<Genset>> _filterGensetsByUserToken(List<Genset> allGensets) async {
    try {
      // Get current user's customer record from database
      final customer = await _getCurrentUserCustomer();

      if (customer == null) {
        print('⚠️ No customer record found, returning empty list');
        return [];
      }

      print('👤 User ${customer.email} has token: ${customer.tokens.firstOrNull ?? 'none'}');

      // Check if user has the master token (grants access to all gensets)
      if (customer.tokens.contains(_masterToken)) {
        print('🎯 User has MASTER TOKEN - showing ALL gensets');
        return allGensets;
      }

      // Check if user has specific token-based access
      if (customer.tokens.isNotEmpty) {
        print('🔑 Filtering gensets by user tokens: ${customer.tokens}');

        // Filter gensets that match any of the user's tokens
        final filteredGensets = allGensets.where((genset) {
          final gensetToken = genset.token;
          if (gensetToken == null || gensetToken.isEmpty) {
            return false; // Skip gensets without tokens
          }

          // Check if genset token matches any user token
          final matches = customer.tokens.contains(gensetToken);
          if (matches) {
            print('✅ Genset ${genset.gsname} matches token: $gensetToken');
          }
          return matches;
        }).toList();

        print('🎯 Filtered ${allGensets.length} gensets down to ${filteredGensets.length} matching user tokens');
        return filteredGensets;
      }

      // If no tokens, return empty list
      print('⚠️ User has no token permissions');
      return [];

    } catch (e) {
      print('❌ Error filtering gensets by user permissions: $e');
      // Return empty list if filtering fails (safer than showing all)
      return [];
    }
  }

  /// Get current user's customer record from database
  static Future<CustomerRecord?> _getCurrentUserCustomer() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('⚠️ No authenticated user found');
        return null;
      }

      print('🔍 Getting customer record for user: ${user.email}');

      // Get customer data from CustomerMappingService (uses correct table)
      final customerMapping = await CustomerMappingService.fetchCustomerMappingByEmail();
      if (customerMapping == null) {
        print('⚠️ No customer mapping found for email: ${user.email}');
        return null;
      }

      // Convert CustomerMapping to CustomerRecord format
      final customerRecord = CustomerRecord(
        id: '', // Not needed for filtering
        email: customerMapping.email,
        customerName: '', // Not in CustomerMapping
        gensetName: '', // Not in CustomerMapping
        tokens: customerMapping.tokens,
      );

      print('👤 Found customer mapping with ${customerRecord.tokens.length} tokens: ${customerRecord.tokens}');
      return customerRecord;

    } catch (e) {
      print('❌ Error getting user customer record: $e');
      return null;
    }
  }

  /// Get current user's tokens from database
  static Future<List<String>?> _getCurrentUserTokens() async {
    final customer = await _getCurrentUserCustomer();
    return customer?.tokens;
  }

  /// Sync gensets to Airtable in the background
  static Future<void> _syncGensetsToAirtableInBackground(List<Genset> gensets) async {
    try {
      print('🔄 Syncing ${gensets.length} gensets to Airtable in background...');

      // Sync each genset to Airtable
      int successCount = 0;
      for (final genset in gensets) {
        try {
          final success = await syncGensetToAirtable(genset);
          if (success) successCount++;
        } catch (e) {
          print('⚠️ Failed to sync genset ${genset.gsname}: $e');
        }
      }

      print('✅ Successfully synced $successCount/${gensets.length} gensets to Airtable');
    } catch (e) {
      print('❌ Background sync to Airtable failed: $e');
    }
  }

  /// Creates a new genset record in Airtable
  static Future<Genset> createGenset(Map<String, dynamic> fields) async {
    try {
      final backendUrl = await getBackendUrl();
      final endpointUrl = '$backendUrl/sync-to-airtable';

      print('➕ Creating new genset via: $endpointUrl');

      // Get Firebase auth token for authentication
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'records': [{
            'fields': fields
          }]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Successfully created genset');

        // Assuming the response contains the created record
        if (data['records'] != null && data['records'].isNotEmpty) {
          return Genset.fromJson(data['records'][0]);
        } else {
          throw Exception('Invalid response format: No records returned');
        }
      } else {
        throw _getErrorFromStatusCode(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw Exception('Network connection failed. Please check:\n'
          '• Is the backend server running?\n'
          '• Is your device connected to the same network?\n'
          '• Is the backend URL correct? (${await getBackendUrl()})\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error. Please check your network connection.\nError: $e');
    } catch (e) {
      if (e is Exception && e.toString().contains('BackendService')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Unexpected error occurred while creating genset.\nError: $e');
    }
  }

  /// Updates an existing genset record in Airtable
  static Future<Genset> updateGenset(String recordId, Map<String, dynamic> fields) async {
    try {
      final backendUrl = await getBackendUrl();
      final endpointUrl = '$backendUrl/sync-to-airtable/$recordId';

      print('🔄 Updating genset $recordId via: $endpointUrl');

      // Get Firebase auth token for authentication
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.patch(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'fields': fields
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully updated genset');

        // Assuming the response contains the updated record
        return Genset.fromJson(data);
      } else {
        throw _getErrorFromStatusCode(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw Exception('Network connection failed. Please check:\n'
          '• Is the backend server running?\n'
          '• Is your device connected to the same network?\n'
          '• Is the backend URL correct? (${await getBackendUrl()})\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error. Please check your network connection.\nError: $e');
    } catch (e) {
      if (e is Exception && e.toString().contains('BackendService')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Unexpected error occurred while updating genset.\nError: $e');
    }
  }

  /// Deletes a genset record from Airtable
  static Future<void> deleteGenset(String recordId) async {
    try {
      final backendUrl = await getBackendUrl();
      final endpointUrl = '$backendUrl/sync-to-airtable/$recordId';

      print('🗑️ Deleting genset $recordId via: $endpointUrl');

      // Get Firebase auth token for authentication
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.delete(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Successfully deleted genset');
        return;
      } else {
        throw _getErrorFromStatusCode(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw Exception('Network connection failed. Please check:\n'
          '• Is the backend server running?\n'
          '• Is your device connected to the same network?\n'
          '• Is the backend URL correct? (${await getBackendUrl()})\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error. Please check your network connection.\nError: $e');
    } catch (e) {
      if (e is Exception && e.toString().contains('BackendService')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Unexpected error occurred while deleting genset.\nError: $e');
    }
  }

  /// Sync a genset to Airtable using correct field names
  static Future<bool> syncGensetToAirtable(Genset genset) async {
    try {
      final backendUrl = await getBackendUrl();
      final endpointUrl = '$backendUrl/sync-to-airtable';

      print('🔄 Syncing genset ${genset.gsname} to Airtable via: $endpointUrl');

      // Get Firebase auth token for authentication
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'records': [{
            'fields': {
              'Genset ID': genset.gensetId,
              'gsname': genset.gsname,
              'status_name': genset.statusName,
              'longitude': genset.longitude,
              'latitude': genset.latitude,
              'totaltime': genset.totaltime,
              'daytime': genset.daytime,
              'Database Link': genset.databaseLink,
              'Token': genset.token,
            }
          }]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Successfully synced genset to Airtable');
        return true;
      } else {
        print('❌ Failed to sync genset: ${response.statusCode} - ${response.body}');
        return false;
      }
    } on SocketException catch (e) {
      throw Exception('Network connection failed. Please check:\n'
          '• Is the backend server running?\n'
          '• Is your device connected to the same network?\n'
          '• Is the backend URL correct? (${await getBackendUrl()})\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error. Please check your network connection.\nError: $e');
    } catch (e) {
      if (e is Exception && e.toString().contains('BackendService')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Unexpected error occurred while syncing to Airtable.\nError: $e');
    }
  }

  /// Makes a POST request to sync data to Airtable (legacy method)
  static Future<void> syncToAirtable() async {
    try {
      final backendUrl = await getBackendUrl();
      final endpointUrl = '$backendUrl/sync-to-airtable';

      print('🔄 Syncing to Airtable via: $endpointUrl');

      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Successfully synced data to Airtable');
        return;
      } else {
        throw _getErrorFromStatusCode(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw Exception('Network connection failed. Please check:\n'
          '• Is the backend server running?\n'
          '• Is your device connected to the same network?\n'
          '• Is the backend URL correct? (${await getBackendUrl()})\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error. Please check your network connection.\nError: $e');
    } catch (e) {
      if (e is Exception && e.toString().contains('BackendService')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Unexpected error occurred while syncing to Airtable.\nError: $e');
    }
  }

  /// Helper method to create descriptive error messages based on HTTP status codes
  static Exception _getErrorFromStatusCode(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return Exception('Bad Request (400): The request was malformed. Please check the request parameters.');
      case 401:
        return Exception('Unauthorized (401): Authentication failed. Please check your credentials.');
      case 403:
        return Exception('Forbidden (403): Access denied. You may not have permission to access this resource.');
      case 404:
        return Exception('Not Found (404): The requested endpoint was not found. Please check the URL.');
      case 408:
        return Exception('Request Timeout (408): The server timed out waiting for the request.');
      case 429:
        return Exception('Too Many Requests (429): You have exceeded the rate limit. Please try again later.');
      case 500:
        return Exception('Internal Server Error (500): The server encountered an unexpected error.');
      case 502:
        return Exception('Bad Gateway (502): The server received an invalid response from an upstream server.');
      case 503:
        return Exception('Service Unavailable (503): The server is temporarily unable to handle the request.');
      case 504:
        return Exception('Gateway Timeout (504): The server timed out waiting for an upstream response.');
      default:
        return Exception('HTTP Error ($statusCode): ${responseBody.isNotEmpty ? responseBody : 'Unknown error'}');
    }
  }



  /// Gets current backend URL for debugging purposes
  static Future<String> getCurrentBackendUrl() async {
    return await getBackendUrl();
  }

  /// Checks if the backend server is reachable
  static Future<bool> isBackendReachable() async {
    try {
      final backendUrl = await getBackendUrl();
      final response = await http.get(Uri.parse('$backendUrl/gensets')).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Backend reachability check failed: $e');
      return false;
    }
  }
}
