import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableService {
  // Airtable configuration
  static const String _baseId = 'appVnYHSKVfpjcFtF'; // Your Airtable Base ID
  static const String _apiKey = 'patlLfHPS1UIfd4UB.92e83b6f13030c85333bba2ce32782d6f68342d997019e1bac93d03ec99e7794'; // Your Airtable API Key
  static const String _tableName = 'Genset Customer'; // Your table name

  static const String _baseUrl = 'https://api.airtable.com/v0/$_baseId/$_tableName';

  /// Query Airtable for customer record by email
  static Future<CustomerRecord?> getCustomerByEmail(String email) async {
    try {
      final filterFormula = 'Email="$email"';
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
          return null; // No customer found with this email
        }
      } else {
        throw Exception('Failed to query Airtable: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Airtable query error: $e');
      throw Exception('Failed to query customer data: $e');
    }
  }

  /// Get all customer records (for admin purposes)
  static Future<List<CustomerRecord>> getAllCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List;
        return records.map((record) => CustomerRecord.fromJson(record)).toList();
      } else {
        throw Exception('Failed to fetch customers: ${response.statusCode}');
      }
    } catch (e) {
      print('Airtable fetch error: $e');
      throw Exception('Failed to fetch customer data: $e');
    }
  }
}

class CustomerRecord {
  final String id;
  final String email;
  final String? utoken;
  final String? apiUrl;
  final String? companyName;
  final String? contactName;
  final String? phone;
  final Map<String, dynamic>? fields;

  CustomerRecord({
    required this.id,
    required this.email,
    this.utoken,
    this.apiUrl,
    this.companyName,
    this.contactName,
    this.phone,
    this.fields,
  });

  factory CustomerRecord.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};

    return CustomerRecord(
      id: json['id'] ?? '',
      email: fields['Email'] ?? '',
      utoken: fields['Utoken'],
      apiUrl: fields['API_URL'],
      companyName: fields['Company Name'],
      contactName: fields['Contact Name'],
      phone: fields['Phone'],
      fields: fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'utoken': utoken,
      'apiUrl': apiUrl,
      'companyName': companyName,
      'contactName': contactName,
      'phone': phone,
      'fields': fields,
    };
  }

  bool get hasValidCredentials => utoken != null && utoken!.isNotEmpty && apiUrl != null && apiUrl!.isNotEmpty;
}
