import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/generator_model.dart';
import '../models/genset_model.dart';

class ApiService {

  static const String baseUrl = 'https://mirrorapi.netlify.app';


  Future<GeneratorStatus> getGeneratorStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/genset'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);


        if (jsonData is Map<String, dynamic>) {
          return GeneratorStatus.fromJson(jsonData);
        } else if (jsonData is List && jsonData.isNotEmpty) {
          return GeneratorStatus.fromJson(jsonData[0]);
        } else {
          throw Exception('No generator data available');
        }
      } else {
        throw Exception('Failed to load generator status');
      }
    } catch (e) {
      print('Error fetching generator status: $e');
      rethrow;
    }
  }


  Future<List<ServiceRecordModel>> getServiceRecords() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/service-records'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        return jsonData
            .map((item) => ServiceRecordModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load service records');
      }
    } catch (e) {
      print('Error fetching service records: $e');
      return [];
    }
  }


  Future<void> saveServiceRecord(ServiceRecordModel record) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/service-records'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(record.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to save service record');
      }
    } catch (e) {
      print('Error saving service record: $e');
    }
  }

  Future<List<Genset>> getGensetList(String utoken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.smartgencloudplus.com/yewu/third/genset/list?utoken=$utoken&page=1&per_page=10'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Assuming the response has a 'data' field with list of gensets
        if (jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((item) => Genset.fromJson(item))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load genset list');
      }
    } catch (e) {
      print('Error fetching genset list: $e');
      return [];
    }
  }
}
