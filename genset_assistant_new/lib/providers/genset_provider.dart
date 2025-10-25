import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/genset_model.dart';
import '../services/airtable_service.dart';
import '../services/api_service.dart';
import '../services/customer_mapping_service.dart';

class GensetProvider with ChangeNotifier {
  List<Genset> _gensets = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Genset> get gensets => _gensets;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  bool get isEmpty => _gensets.isEmpty && !_isLoading && !_hasError;

  bool get _hasError => _error.isNotEmpty;

  // Fetch gensets from SmartGen API - strictly filter by user's assigned tokens only
  Future<void> fetchGensets() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Fetch real gensets from SmartGen API
      print('🔄 [Flutter] Fetching real gensets from SmartGen API...');
      final allGensets = await AirtableService.fetchGensetsFromSmartGen();

      if (allGensets.isEmpty) {
        throw Exception('No gensets found in SmartGen API');
      }

      print('📊 [Flutter] SmartGen API returned ${allGensets.length} total gensets');
      print('📱 [Flutter] All gensets: ${allGensets.map((g) => '${g.name} (${g.power})').toList()}');

      // Filter gensets based on tokens from Database table (even without authentication)
      List<Genset> displayGensets = allGensets;

      try {
        // Try to get user tokens from Database table
        final userTokens = await ApiService.getCurrentUserUtokens();
        if (userTokens != null && userTokens.isNotEmpty) {
          print('🔑 [Flutter] User authenticated with ${userTokens.length} tokens: ${userTokens.map((t) => t.substring(0, 10) + '...').toList()}');

          // Filter gensets to only show those assigned to this user
          displayGensets = allGensets.where((genset) {
            final gensetToken = genset.specifications?['token'] as String?;
            return gensetToken != null && userTokens.contains(gensetToken);
          }).toList();

          print('✅ [Flutter] Filtered to ${displayGensets.length} gensets assigned to user');
          if (displayGensets.isEmpty) {
            print('⚠️ [Flutter] No gensets match user tokens');
            throw Exception('No gensets found matching your assigned tokens. Please contact support.');
          }
        } else {
          // User not authenticated - try to filter using tokens from Database table
          print('🔄 [Flutter] User not authenticated, trying to fetch tokens from Database table...');

          try {
            // Always fetch fresh tokens from Database table
            final customerMapping = await CustomerMappingService.fetchCustomerMappingByEmail(forceRefresh: true);
            if (customerMapping != null && customerMapping.tokens.isNotEmpty) {
              print('🔑 [Flutter] Found ${customerMapping.tokens.length} tokens in Database table: ${customerMapping.tokens.map((t) => t.substring(0, 10) + '...').toList()}');

              displayGensets = allGensets.where((genset) {
                final gensetToken = genset.specifications?['token'] as String?;
                return gensetToken != null && customerMapping.tokens.contains(gensetToken);
              }).toList();

              print('🎯 [Flutter] Filtered to ${displayGensets.length} gensets using Database tokens');
              if (displayGensets.isEmpty) {
                print('⚠️ [Flutter] No gensets match Database tokens');
                throw Exception('No gensets found matching your assigned tokens. Please contact support.');
              }
            } else {
              print('⚠️ [Flutter] No tokens found in Database table');
              throw Exception('No tokens found in Database table. Please contact support.');
            }
          } catch (e) {
            print('⚠️ [Flutter] Could not fetch Database tokens: $e');
            throw Exception('Unable to fetch tokens from Database table. Please contact support.');
          }
        }
      } catch (e) {
        print('ℹ️ [Flutter] Token filtering failed: $e');
        throw Exception('Unable to filter gensets by your assigned tokens. Please contact support.');
      }

      _gensets = displayGensets;
      _error = '';
      print('🎯 [Flutter] Displaying ${displayGensets.length} gensets in Live Status');

    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _gensets = [];
      print('❌ [Flutter] Error fetching gensets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh gensets data
  Future<void> refreshGensets() async {
    await fetchGensets();
  }

  // Clear error state
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Get genset by index (safe access)
  Genset? getGenset(int index) {
    if (index >= 0 && index < _gensets.length) {
      return _gensets[index];
    }
    return null;
  }

  // Get running gensets count
  int get runningGensetsCount {
    return _gensets.where((genset) =>
      genset.status.toLowerCase().contains('running') ||
      genset.status.toLowerCase().contains('online') ||
      genset.status.toLowerCase().contains('active')
    ).length;
  }

  // Get gensets with maintenance issues
  List<Genset> get gensetsWithMaintenanceIssues {
    return _gensets.where((genset) =>
      genset.maintenanceStatus != null &&
      (genset.maintenanceStatus!.toLowerCase().contains('due') ||
       genset.maintenanceStatus!.toLowerCase().contains('overdue'))
    ).toList();
  }

  // Helper method to format error messages
  String _getErrorMessage(String error) {
    if (error.contains('User not authenticated')) {
      return 'Please log in to view your gensets';
    } else if (error.contains('User email not available')) {
      return 'Your account email is not available. Please try logging out and back in.';
    } else if (error.contains('No customer mapping found')) {
      return 'Your account was not found in our database. Please contact support.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Your account was not found in our database. Please contact support.';
    } else if (error.contains('Network error') || error.contains('Connection refused')) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (error.contains('Server error') || error.contains('500')) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else if (error.contains('User not found')) {
      return 'Your account was not found. Please contact support.';
    } else {
      return 'Failed to load genset data. Please try again.';
    }
  }

  // Reset provider state (useful for logout)
  void reset() {
    _gensets = [];
    _isLoading = false;
    _error = '';
    notifyListeners();
  }
}
