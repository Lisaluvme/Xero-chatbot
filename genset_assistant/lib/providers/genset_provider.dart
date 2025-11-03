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

  // Fetch gensets from Node.js backend server
  Future<void> fetchGensets() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('🔄 [Flutter] Fetching gensets from backend server...');
      final gensets = await ApiService.fetchGensetsFromBackend();

      if (gensets.isEmpty) {
        print('ℹ️ [Flutter] Backend returned no gensets (this is normal)');
        _gensets = [];
        _error = '';
        print('🎯 [Flutter] No gensets to display');
      } else {
        print('✅ [Flutter] Backend returned ${gensets.length} gensets');
        print('📱 [Flutter] Gensets: ${gensets.map((g) => '${g.name} (${g.power})').toList()}');

        _gensets = gensets;
        _error = '';
        print('🎯 [Flutter] Displaying ${gensets.length} gensets in Live Status');
      }

    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _gensets = [];
      print('❌ [Flutter] Error fetching gensets from backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sync data to Airtable via backend server
  Future<void> syncToAirtable() async {
    try {
      print('🔄 [Flutter] Syncing data to Airtable via backend...');
      await ApiService.syncToAirtable();
      print('✅ [Flutter] Sync to Airtable successful');
    } catch (e) {
      print('❌ [Flutter] Error syncing to Airtable: $e');
      rethrow;
    }
  }

  // Create a new genset
  Future<void> createGenset(Map<String, dynamic> fields) async {
    try {
      print('➕ [Flutter] Creating new genset...');
      final newGenset = await ApiService.createGenset(fields);
      _gensets.add(newGenset);
      notifyListeners();
      print('✅ [Flutter] Genset created successfully');
    } catch (e) {
      print('❌ [Flutter] Error creating genset: $e');
      rethrow;
    }
  }

  // Update an existing genset
  Future<void> updateGenset(String recordId, Map<String, dynamic> fields) async {
    try {
      print('🔄 [Flutter] Updating genset $recordId...');
      final updatedGenset = await ApiService.updateGenset(recordId, fields);
      final index = _gensets.indexWhere((g) => g.id == recordId);
      if (index != -1) {
        _gensets[index] = updatedGenset;
        notifyListeners();
      }
      print('✅ [Flutter] Genset updated successfully');
    } catch (e) {
      print('❌ [Flutter] Error updating genset: $e');
      rethrow;
    }
  }

  // Delete a genset
  Future<void> deleteGenset(String recordId) async {
    try {
      print('🗑️ [Flutter] Deleting genset $recordId...');
      await ApiService.deleteGenset(recordId);
      _gensets.removeWhere((g) => g.id == recordId);
      notifyListeners();
      print('✅ [Flutter] Genset deleted successfully');
    } catch (e) {
      print('❌ [Flutter] Error deleting genset: $e');
      rethrow;
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
