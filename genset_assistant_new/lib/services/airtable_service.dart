import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableService {
  // ⚠️  WARNING: This service should not be used in production Flutter apps
  // Airtable API operations should be performed server-side only to keep API keys secure
  // This service is kept for reference/development purposes only

  static const String _baseId = 'appVnYHSKVfpjcFtF'; // Base ID
  // API key removed for security - DO NOT hardcode API keys in client-side code
  static const String _apiKey = ''; // API key should be server-side only
  static const String _tableName = 'Table 1';  // Table name

  static const String _baseUrl = 'https://api.airtable.com/v0/$_baseId/$_tableName';

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
