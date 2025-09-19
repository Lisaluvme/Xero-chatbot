import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/generator_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.gensetassistant.com'; // Replace with actual API URL

  Future<GeneratorStatus> getGeneratorStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/generator/status'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GeneratorStatus.fromJson(jsonData);
      } else {
        throw Exception('Failed to load generator status');
      }
    } catch (e) {
      // For demo purposes, return mock data if API is not available
      return _getMockGeneratorStatus();
    }
  }

  Future<List<ServiceRecordModel>> getServiceRecords() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/service-records'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        return jsonData.map((item) => ServiceRecordModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load service records');
      }
    } catch (e) {
      // Return empty list if API is not available
      return [];
    }
  }

  Future<void> saveServiceRecord(ServiceRecordModel record) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/service-records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(record.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to save service record');
      }
    } catch (e) {
      // For demo purposes, just print the error
      print('Error saving service record: $e');
    }
  }

  // Mock data for demonstration
  GeneratorStatus _getMockGeneratorStatus() {
    return GeneratorStatus(
      isRunning: true,
      location: 'Main Building - Generator Room',
      runHours: 1247,
      fuelLevel: 75,
      batteryVoltage: 12.6,
      temperature: 72,
      oilPressure: 35,
      faults: ['Low coolant level'], // Empty list for no faults
    );
  }
}
