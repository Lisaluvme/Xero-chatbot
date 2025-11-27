import 'package:flutter/services.dart';

class WatchService {
  static const MethodChannel _channel = MethodChannel('com.mgm.genset.watch');
  static WatchService? _instance;

  WatchService._();

  static WatchService get instance {
    _instance ??= WatchService._();
    return _instance!;
  }

  /// Send genset data to the paired watch (bulk data for all gensets)
  Future<String> sendGensetDataToWatchBulk(List<Map<String, dynamic>> gensets) async {
    try {
      final result = await _channel.invokeMethod('sendGensetDataToWatch', {
        'bulkGensetData': gensets,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Sent ${gensets.length} gensets to watch');
      return result.toString();
    } on PlatformException catch (e) {
      print('❌ Error sending bulk genset data to watch: ${e.message}');
      return 'Error: ${e.message}';
    }
  }

  /// Send genset data to the paired watch
  Future<String> sendGensetDataToWatch({
    required String status,
    required String power,
    required String location,
    String? maintenanceStatus,
  }) async {
    try {
      // Create structured data to send to watch
      final gensetData = {
        'status': status,
        'power': power,
        'location': location,
        'maintenanceStatus': maintenanceStatus ?? 'OK',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final result = await _channel.invokeMethod('sendGensetDataToWatch', {
        'gensetData': gensetData,
      });

      print('✅ Sent genset data to watch: $gensetData');
      return result.toString();
    } on PlatformException catch (e) {
      print('❌ Error sending data to watch: ${e.message}');
      return 'Error: ${e.message}';
    }
  }

  /// Send simple genset status to watch (compatibility method)
  Future<String> sendSimpleGensetData(String gensetData) async {
    try {
      final result = await _channel.invokeMethod('sendGensetDataToWatch', {
        'gensetData': gensetData,
      });
      return result.toString();
    } on PlatformException catch (e) {
      print('Error sending data to watch: ${e.message}');
      return 'Error: ${e.message}';
    }
  }

  /// Get the latest genset data (for debugging)
  Future<String> getLatestGensetData() async {
    try {
      final result = await _channel.invokeMethod('getLatestGensetData');
      return result.toString();
    } on PlatformException catch (e) {
      print('Error getting latest genset data: ${e.message}');
      return 'No data available';
    }
  }

  /// Check if watch is paired and reachable
  Future<bool> isWatchReachable() async {
    try {
      final result = await _channel.invokeMethod('isWatchReachable');
      return result == true;
    } on PlatformException catch (e) {
      print('Error checking watch reachability: ${e.message}');
      return false;
    }
  }

  /// Send genset data to iOS widget (for home screen widget)
  Future<String> updateWidgetData({
    required String gensetName,
    required String status,
    required String power,
    required String fuelLevel,
    required String runtime,
    String? nextMaintenance,
    String? location,
  }) async {
    try {
      final widgetData = {
        'name': gensetName,
        'status': status,
        'power': power,
        'fuel': fuelLevel,
        'runtime': runtime,
        'nextMaintenance': nextMaintenance,
        'location': location ?? 'Unknown',
      };

      final result = await _channel.invokeMethod('updateWidgetData', {
        'gensetData': widgetData,
      });

      print('📱 Sent genset data to widget: $widgetData');
      return result.toString();
    } on PlatformException catch (e) {
      print('❌ Error sending data to widget: ${e.message}');
      return 'Error: ${e.message}';
    }
  }
}
