import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mirror_genset_model.dart';
import '../services/mirror_api_service.dart';

class GensetProvider with ChangeNotifier {
  List<MirrorGenset> _gensets = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<MirrorGenset> get gensets => _gensets;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  bool get isEmpty => _gensets.isEmpty && !_isLoading && !_hasError;

  bool get _hasError => _error.isNotEmpty;

  // Fetch gensets from backend API
  Future<void> fetchGensets() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Call MirrorApiService to get genset list
      final mirrorApiService = MirrorApiService();
      final gensetList = await mirrorApiService.fetchGensetList();

      if (gensetList != null && gensetList.isNotEmpty) {
        // Print the returned genset list in console
        print('🔍 [Flutter] Genset list received: ${gensetList.length} items');

        // Convert the list to MirrorGenset objects
        final gensets = gensetList.map((e) => MirrorGenset.fromJson(e as Map<String, dynamic>)).toList();
        _gensets = gensets;
        _error = '';
        print('✅ [Flutter] Successfully loaded ${gensets.length} gensets');
      } else {
        _gensets = [];
        _error = 'No gensets found';
        print('⚠️ [Flutter] No gensets found in response');
      }
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
  MirrorGenset? getGenset(int index) {
    if (index >= 0 && index < _gensets.length) {
      return _gensets[index];
    }
    return null;
  }

  // Get running gensets count
  int get runningGensetsCount {
    return _gensets.where((genset) =>
      genset.statusName.toLowerCase().contains('running') ||
      genset.statusName.toLowerCase().contains('online')
    ).length;
  }

  // Get gensets with alarms
  List<MirrorGenset> get gensetsWithAlarms {
    return _gensets.where((genset) => genset.alarmList.isNotEmpty).toList();
  }

  // Helper method to format error messages
  String _getErrorMessage(String error) {
    if (error.contains('User not authenticated')) {
      return 'Please log in to view your gensets';
    } else if (error.contains('User email not available')) {
      return 'Your account email is not available. Please try logging out and back in.';
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
