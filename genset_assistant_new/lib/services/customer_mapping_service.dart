import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class CustomerMapping {
  final String email;
  final List<String> tokens;

  CustomerMapping({required this.email, required this.tokens});

  factory CustomerMapping.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names for tokens
    List<String> tokens = [];

    if (json['Token'] != null) {
      // Single token field from Database table
      tokens = [json['Token'].toString()];
    } else if (json['Tokens'] != null) {
      // Multiple tokens field (array)
      tokens = List<String>.from(json['Tokens']);
    } else if (json['Token (from Table 1)'] != null) {
      // Token linked from Table 1
      var tokenValue = json['Token (from Table 1)'];
      if (tokenValue is List && tokenValue.isNotEmpty) {
        tokens = [tokenValue[0].toString()];
      } else {
        tokens = [tokenValue.toString()];
      }
    }

    return CustomerMapping(
      email: json['Email'] ?? '',
      tokens: tokens,
    );
  }
}

class CustomerMappingService {
  static final String _baseId = dotenv.env['AIRTABLE_BASE_ID']!;
  static final String _tableName = dotenv.env['AIRTABLE_CUSTOMER_MAPPING_TABLE']!;
  static final String _apiKey = dotenv.env['AIRTABLE_API_KEY']!;

  static Future<CustomerMapping?> fetchCustomerMappingByEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in.");

    final email = user.email!;
    final url =
        'https://api.airtable.com/v0/$_baseId/$_tableName?filterByFormula=${Uri.encodeComponent('{Email}="$email"')}';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode != 200) {
      print('❌ [Flutter] Customer mapping API error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load customer mapping: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final records = data['records'] as List;

    if (records.isEmpty) {
      print('❌ [Flutter] No records found in Database table for email: $email');
      return null; // No mapping found for this email
    }

    print('✅ [Flutter] Found ${records.length} records in Database table');
    print('📋 [Flutter] First record fields: ${records.first['fields']}');

    final mapping = CustomerMapping.fromJson(records.first['fields']);
    print('🔑 [Flutter] Extracted tokens: ${mapping.tokens}');

    return mapping;
  }
}
