import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/generator_model.dart';
import '../models/genset_model.dart';
import 'airtable_service.dart';

class ApiService {
  static const String baseUrl = 'https://backendmirror.netlify.app';

  /// 获取当前用户的 utoken 从 Airtable
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

  /// 获取当前用户的 utoken 从 Airtable (向后兼容)
  static Future<String?> getCurrentUserUtoken() async {
    final tokens = await getCurrentUserUtokens();
    return tokens?.first;
  }

  /// 获取发电机状态
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

  /// 获取保养记录
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

  /// ✅ 获取 genset 列表（已修正 Mirror API 格式）
  Future<List<Genset>> getGensetList(String utoken) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.smartgencloudplus.com/yewu/third/genset/list?utoken=$utoken&page=1&per_page=10',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('🛰️ API Response: $jsonData'); // 调试输出

        // ✅ 修正：Mirror API 的数据在 data.list
        if (jsonData['data'] != null && jsonData['data']['list'] is List) {
          final list = jsonData['data']['list'] as List;
          return list.map((item) => Genset.fromJson(item)).toList();
        } else {
          throw Exception('Invalid response format: Missing data.list');
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
