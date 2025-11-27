import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/generator_model.dart';
import '../models/genset_model.dart';
import 'airtable_service.dart';
import 'backend_service.dart';

class ApiService {
  static const String baseUrl = 'https://backendmirror.netlify.app';
  static const String gensetsEndpoint = '$baseUrl/.netlify/functions/gensets';
  static const String syncEndpoint = '$baseUrl/.netlify/functions/sync-to-airtable';

  static Future<List<String>?> getCurrentUserUtokens() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      final customer = await AirtableService.getCustomerByEmail(user.email!);
      if (customer == null || customer.tokens.isEmpty) {
        throw Exception('No utoken found for user');
      }

      // 返回所有 tokens
      print('🔑 [Flutter] Found ${customer.tokens.length} tokens for user: ${customer.tokens}');
      return customer.tokens;
    } catch (e) {
      print('Error fetching user utokens: $e');
      return null;
    }
  }

  static Future<String?> getCurrentUserUtoken() async {
    final tokens = await getCurrentUserUtokens();
    return tokens?.first;
  }

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

  /// 保存保养记录
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

  // REMOVED: Direct SmartGen API calls - now using Netlify backend
  // The backend handles fetching from SmartGen and syncing to Airtable

  /// Fetch gensets from Airtable backend
  /// Returns empty list if no data available (normal behavior)
  static Future<List<Genset>> fetchGensetsFromBackend() async {
    try {
      final gensets = await BackendService.fetchGensets();

      if (gensets.isEmpty) {
        print('ℹ️ No gensets data available from backend (this is normal)');
      } else {
        print('✅ Fetched ${gensets.length} gensets from backend');
      }

      return gensets;
    } catch (e) {
      print('❌ Error fetching gensets from backend: $e');
      // Return empty list instead of throwing - handle gracefully in UI
      return [];
    }
  }

  /// Sync data to Airtable via backend server (using BackendService for dynamic URL)
  static Future<void> syncToAirtable() async {
    return BackendService.syncToAirtable();
  }

  /// Create a new genset record
  static Future<Genset> createGenset(Map<String, dynamic> fields) async {
    return BackendService.createGenset(fields);
  }

  /// Update an existing genset record
  static Future<Genset> updateGenset(String recordId, Map<String, dynamic> fields) async {
    return BackendService.updateGenset(recordId, fields);
  }

  /// Delete a genset record
  static Future<void> deleteGenset(String recordId) async {
    return BackendService.deleteGenset(recordId);
  }

  /// Sync a genset to Airtable using correct field names
  static Future<bool> syncGensetToAirtable(Genset genset) async {
    return BackendService.syncGensetToAirtable(genset);
  }

  /// Delete user account
  static Future<void> deleteUserAccount(String reAuthToken) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'X-Reauth': reAuthToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Success
      } else if (response.statusCode == 400) {
        throw Exception('Missing confirmation');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid token');
      } else if (response.statusCode == 403) {
        throw Exception('Deletion not allowed');
      } else if (response.statusCode == 500) {
        throw Exception('Server error, please retry');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
