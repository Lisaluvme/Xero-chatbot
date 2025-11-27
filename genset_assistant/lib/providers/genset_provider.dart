import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/genset_model.dart';
import '../services/airtable_service.dart';
import '../services/api_service.dart';
import '../services/customer_mapping_service.dart';
import '../services/watch_service.dart';

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
        // Send data to watch only if account actually has gensets
        _sendDataToWatch();
        // Update widget with latest genset data
        _updateWidgetData();
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

  // Check if we're in development simulator mode where mock data should be used
  bool _isDevelopmentSimulatorMode() {
    // Temporary: Always return true for testing watch functionality on simulator
    // This will load mock genset data for watch testing
    // TODO: In production, this should check for actual simulator environment
    return !kIsWeb;
  }

  bool _isIOSSimulator() {
    // Check if running on iOS simulator based on platform info
    // This is a heuristic - in production this wouldn't reliably detect simulator
    try {
      final platform = Platform.isIOS;
      final deviceInfo = '';
      return platform && deviceInfo.toLowerCase().contains('simulator');
    } catch (_) {
      return false;
    }
  }

  bool _isExplicitTestingMode() {
    // This allows explicit enabling for testing via environment variable
    return const bool.fromEnvironment('ENABLE_MOCK_GENSETS', defaultValue: false);
  }

  // Load mock gensets for development/testing when no real API access is available
  Future<void> _loadMockGensetsForTesting() async {
    print('🔧 [Flutter] Loading mock genset data for development testing...');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create realistic mock genset data
    _gensets = [
      Genset(
        id: 'mock-gen-001',
        gensetId: 'GEN-001',
        gsname: '30KVA MAIN GEN A1',
        statusName: 'Running',
        longitude: 103.8198,
        latitude: 1.3521,
        totaltime: '1425h30min',
        daytime: '450h15min',
        token: 'mock-token-001',
        source: 'Mock Data',
      ),
      Genset(
        id: 'mock-gen-002',
        gensetId: 'GEN-002',
        gsname: '60KVA BACKUP GEN B2',
        statusName: 'Standby',
        longitude: 103.8200,
        latitude: 1.3523,
        totaltime: '876h45min',
        daytime: '200h30min',
        token: 'mock-token-002',
        source: 'Mock Data',
      ),
      Genset(
        id: 'mock-gen-003',
        gensetId: 'GEN-003',
        gsname: '100KVA MOBILE GEN C3',
        statusName: 'Offline',
        longitude: 103.8195,
        latitude: 1.3518,
        totaltime: '2103h12min',
        daytime: '890h25min',
        token: 'mock-token-003',
        source: 'Mock Data',
      ),
    ];

    _error = '';
    print('✅ [Flutter] Loaded ${gensets.length} mock gensets for testing');
    print('📱 [Flutter] Mock Gensets: ${gensets.map((g) => '${g.name} (${g.power})').toList()}');

    // Send mock data to watch for testing
    _sendDataToWatch();

    _isLoading = false;
    notifyListeners();
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
      // Sync to watch with updated data
      _sendDataToWatch();
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
        print('✅ [Flutter] Genset updated successfully');
        // Sync updated data to watch
        _sendDataToWatch();
      }
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
      // Sync updated data to watch (after deletion)
      if (_gensets.isNotEmpty) {
        _sendDataToWatch();
      }
    } catch (e) {
      print('❌ [Flutter] Error deleting genset: $e');
      rethrow;
    }
  }

  // Refresh gensets data
  Future<void> refreshGensets() async {
    await fetchGensets();
  }

  // Sync current data to watch (for initialization or manual sync)
  void syncToWatch() {
    _sendDataToWatch();
    print('📱 Manually syncing current genset data to watch');
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

  // Reset provider state (useful for logout) - also clear watch data
  void reset() {
    _gensets = [];
    _isLoading = false;
    _error = '';
    // Clear watch data when user logs out
    _clearWatchData();
    notifyListeners();
  }

  // Clear watch data (when user has no gensets or logs out)
  void _clearWatchData() {
    print('📱 Clearing watch data - no gensets available');
    // We don't send anything to watch when clearing - it will keep whatever it had
    // or be empty if account never had gensets
  }

  // Send genset data to watch
  void _sendDataToWatch() {
    if (_gensets.isNotEmpty) {
      // Convert genset data to the format expected by the watch
      final gensetArray = _gensets.map((genset) => {
        'id': genset.id,
        'gsname': genset.gsname,
        'status_name': genset.statusName,
        'totaltime': genset.totaltime ?? '',
        'daytime': genset.daytime ?? '',
        'alarm_num': genset.alarmNum ?? 0,
        'isOnline': genset.statusName.toLowerCase().contains('running') ||
                   genset.statusName.toLowerCase().contains('online'),
        'longitude': genset.longitude,
        'latitude': genset.latitude,
      }).toList();

      // Send the full array of genset data to watch
      WatchService.instance.sendGensetDataToWatchBulk(gensetArray);

      print('📱 Sent ${gensetArray.length} gensets to watch');
    } else {
      // Clear watch data when no gensets
      WatchService.instance.sendGensetDataToWatchBulk([]);
      print('📱 Cleared watch data - no gensets available');
    }
  }

  // Update widget with current genset data
  void _updateWidgetData() {
    if (_gensets.isNotEmpty) {
      final firstGenset = _gensets.first;

      // Get structured data for widget
      final widgetData = _getStructuredGensetDataForWatch();

      WatchService.instance.updateWidgetData(
        gensetName: firstGenset.gsname ?? 'Generator 1',
        status: firstGenset.statusName,
        power: firstGenset.power,
        fuelLevel: '78%', // This would come from API in real implementation
        runtime: firstGenset.totaltime ?? '0h',
        nextMaintenance: '2024-02-15', // This would come from API
        location: firstGenset.location ?? 'Main Building',
      );

      print('📱 Updated widget with genset data');
    } else {
      // Send empty data to clear widget
      WatchService.instance.updateWidgetData(
        gensetName: 'No Gensets',
        status: 'Offline',
        power: '0 kW',
        fuelLevel: '--',
        runtime: '0h',
        location: 'Unknown',
      );
      print('📱 Cleared widget data - no gensets available');
    }
  }

  // Get structured genset data for watch display
  Map<String, String> _getStructuredGensetDataForWatch() {
    if (_gensets.isEmpty) {
      return {
        'status': 'No gensets',
        'power': '0 kVA',
        'location': 'N/A',
        'maintenanceStatus': 'N/A',
      };
    }

    final totalGensets = _gensets.length;
    final runningGensets = runningGensetsCount;
    final firstGenset = _gensets.first;

    // Determine overall status
    String overallStatus = _gensets.isEmpty ? 'No data' :
                         runningGensets > 0 ? 'Running (${runningGensets}/${totalGensets})' :
                         _gensets.length > 0 ? 'Ready' :
                         'Standby';

    // Calculate total power of running gensets
    double totalPower = 0.0;
    for (var genset in _gensets) {
      if (genset.status.toLowerCase().contains('running') ||
          genset.status.toLowerCase().contains('online') ||
          genset.status.toLowerCase().contains('active')) {
        // Extract numeric value from power string (e.g., "15.5 kVA" -> 15.5)
        final powerMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(genset.power);
        if (powerMatch != null) {
          final powerValue = double.tryParse(powerMatch.group(1) ?? '0') ?? 0.0;
          totalPower += powerValue;
        }
      }
    }

    String totalPowerString = totalPower > 0 ? '${totalPower.toStringAsFixed(1)} kVA' : '-- kVA';

    // Get maintenance status
    String maintenanceMsg = gensetsWithMaintenanceIssues.isNotEmpty
        ? '${gensetsWithMaintenanceIssues.length} due'
        : 'All OK';

    return {
      'status': overallStatus,
      'power': totalPowerString,
      'location': firstGenset.location ?? 'Main Building',
      'maintenanceStatus': maintenanceMsg,
    };
  }
}
