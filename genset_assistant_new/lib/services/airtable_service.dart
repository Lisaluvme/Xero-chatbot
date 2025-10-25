import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/genset_model.dart';

class AirtableService {

  static String get _baseId => dotenv.env['AIRTABLE_BASE_ID']!;
  static String get _apiKey => dotenv.env['AIRTABLE_API_KEY']!;
  static String get _tableName => dotenv.env['AIRTABLE_TABLE_NAME']!;

  static String get _baseUrl => 'https://api.airtable.com/v0/$_baseId/$_tableName';

  /// 📨 根据 Email 获取客户资料（支持多个 Token）
  static Future<CustomerRecord?> getCustomerByEmail(String email) async {
    try {
      final cleanEmail = email.trim();
      final filterFormula = 'Email="$cleanEmail"';
      final encodedFormula = Uri.encodeComponent(filterFormula);
      final url = '$_baseUrl?filterByFormula=$encodedFormula';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List?;

        if (records != null && records.isNotEmpty) {
          return CustomerRecord.fromJson(records.first);
        } else {
          print('❌ No token found for email: $cleanEmail');
          return null;
        }
      } else {
        throw Exception('Failed to query Airtable: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔥 Airtable query error: $e');
      throw Exception('Failed to query customer data: $e');
    }
  }

  /// 📊 Fetch gensets from SmartGen API and sync to Airtable
  static Future<List<Genset>> fetchGensetsFromSmartGen() async {
    try {
      // Get master token from environment
      final masterToken = dotenv.env['SMARTGEN_UTOKEN'];
      if (masterToken == null || masterToken.isEmpty) {
        throw Exception('No SMARTGEN_UTOKEN found in environment');
      }

      print('🔄 [Airtable] Fetching real data from SmartGen API...');

      // Fetch real data from SmartGen API
      final smartGenUrl = 'https://www.smartgencloudplus.com/yewu/third/genset/list?utoken=$masterToken&page=1&per_page=10';

      final response = await http.get(Uri.parse(smartGenUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🛰️ [SmartGen] API Response: $data');

        // Check if SmartGen API returned success
        if (data['code'] == 200 && data['data'] != null && data['data']['list'] is List) {
          final list = data['data']['list'] as List;
          print('✅ [SmartGen] Successfully fetched ${list.length} real gensets');

          // Convert SmartGen data to Genset models
          List<Genset> gensets = [];
          for (var item in list) {
            final genset = Genset.fromJson(item as Map<String, dynamic>);
            gensets.add(genset);
          }

          // TODO: Optionally sync this data to Airtable for caching
          // await _syncToAirtable(gensets);

          print('📱 [SmartGen] Real gensets: ${gensets.map((g) => '${g.name} (${g.power})').toList()}');
          return gensets;
        } else {
          throw Exception('SmartGen API returned error: ${data['msg'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch from SmartGen API: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching gensets from SmartGen: $e');
      throw Exception('Failed to fetch real genset data: $e');
    }
  }

  /// 📊 Legacy method - fetch static data from Airtable (for backward compatibility)
  static Future<List<Genset>> fetchGensets() async {
    print('⚠️ [Airtable] Using static Airtable data (not real SmartGen data)');
    return fetchGensetsFromSmartGen(); // Redirect to real data
  }

  /// ➕ 添加 utoken 到用户的 tokens 数组
  static Future<void> addUtokenToUser(String email, String utoken) async {
    try {
      // 首先获取用户记录
      final customer = await getCustomerByEmail(email);
      if (customer == null) {
        throw Exception('User not found in Airtable');
      }

      // 添加新 token 到现有 tokens
      final updatedTokens = List<String>.from(customer.tokens)..add(utoken);

      // 更新记录
      final updateUrl = '$_baseUrl/${customer.id}';
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fields': {
            'Email': customer.email,
            'Customer Name': customer.customerName,
            'Genset Name': customer.gensetName,
            'Token': updatedTokens.join(','), // Airtable 存储为逗号分隔字符串
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user tokens: ${response.statusCode} - ${response.body}');
      }

      print('✅ Successfully added utoken to user: $email');
    } catch (e) {
      print('🔥 Error adding utoken to user: $e');
      throw Exception('Failed to add utoken: $e');
    }
  }

  /// 🔄 设置用户的 tokens 数组（用于撤销操作）
  static Future<void> setUtokensForUser(String email, List<String> utokens) async {
    try {
      // 首先获取用户记录
      final customer = await getCustomerByEmail(email);
      if (customer == null) {
        throw Exception('User not found in Airtable');
      }

      // 更新记录
      final updateUrl = '$_baseUrl/${customer.id}';
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fields': {
            'Email': customer.email,
            'Customer Name': customer.customerName,
            'Genset Name': customer.gensetName,
            'Token': utokens.join(','), // Airtable 存储为逗号分隔字符串
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set user tokens: ${response.statusCode} - ${response.body}');
      }

      print('✅ Successfully set utokens for user: $email');
    } catch (e) {
      print('🔥 Error setting utokens for user: $e');
      throw Exception('Failed to set utokens: $e');
    }
  }
}

/// 🧾 Customer record model supporting multiple tokens
class CustomerRecord {
  final String id;
  final String email;
  final String customerName;
  final String gensetName;
  final List<String> tokens;

  CustomerRecord({
    required this.id,
    required this.email,
    required this.customerName,
    required this.gensetName,
    required this.tokens,
  });

  factory CustomerRecord.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    final tokenField = fields['Token'];

    List<String> tokenList = [];
    if (tokenField != null) {
      if (tokenField is String) {
        tokenList = tokenField
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (tokenField is List) {
        tokenList = tokenField.map((e) => e.toString().trim()).toList();
      }
    }

    return CustomerRecord(
      id: json['id'] ?? '',
      email: fields['Email'] ?? '',
      customerName: fields['Customer Name'] ?? '',
      gensetName: fields['Genset Name'] ?? '',
      tokens: tokenList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'customerName': customerName,
      'gensetName': gensetName,
      'tokens': tokens,
    };
  }

  bool get hasValidTokens => tokens.isNotEmpty;
}
