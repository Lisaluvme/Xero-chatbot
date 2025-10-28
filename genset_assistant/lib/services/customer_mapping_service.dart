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
      // Single token field from Database table - may contain comma-separated values
      var tokenValue = json['Token'].toString();
      if (tokenValue.contains(',')) {
        tokens = tokenValue.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      } else {
        tokens = [tokenValue];
      }
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

    // Remove duplicates and filter out empty tokens
    tokens = tokens.where((token) => token.isNotEmpty).toSet().toList();

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

  // Default email to use when user is not authenticated
  static const String _defaultEmail = 'jincai2004@gmail.com';

  static Future<CustomerMapping?> fetchCustomerMappingByEmail({bool forceRefresh = false}) async {
    try {
      // Check if user is authenticated and get their email
      final user = FirebaseAuth.instance.currentUser;
      String email;

      if (user != null && user.email != null && user.email!.isNotEmpty) {
        email = user.email!;
        print('🔍 [Flutter] Searching for customer mapping with authenticated user email: "$email"');
      } else {
        // User not authenticated, use default email for demo
        email = _defaultEmail;
        print('🔍 [Flutter] User not authenticated, using default email: "$email"');
      }

      print('🔄 [Flutter] Fetching fresh data from Database table for email: $email');

      final url = 'https://api.airtable.com/v0/$_baseId/$_tableName?filterByFormula=${Uri.encodeComponent('{email}="$email"')}';

      print('🔗 [Flutter] Airtable Database API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print('❌ [Flutter] Database table API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load customer mapping: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final records = data['records'] as List;

      if (records.isEmpty) {
        print('❌ [Flutter] No records found in Database table for email: $email');
        print('🔍 [Flutter] This could mean:');
        print('  1. The email in the database doesn\'t exactly match: $email');
        print('  2. The email field name in Airtable is different');
        print('  3. The record might be in a different table');

        // Try a more flexible search (case-insensitive, trimmed)
        final flexibleUrl = 'https://api.airtable.com/v0/$_baseId/$_tableName?filterByFormula=${Uri.encodeComponent('LOWER(TRIM({email}))=LOWER(TRIM("$email"))')}';

        print('🔄 [Flutter] Trying flexible email search in Database table: $flexibleUrl');

        final flexibleResponse = await http.get(
          Uri.parse(flexibleUrl),
          headers: {'Authorization': 'Bearer $_apiKey'},
        );

        if (flexibleResponse.statusCode == 200) {
          final flexibleData = jsonDecode(flexibleResponse.body);
          final flexibleRecords = flexibleData['records'] as List;

          if (flexibleRecords.isNotEmpty) {
            print('✅ [Flutter] Found ${flexibleRecords.length} records with flexible search');
            records.addAll(flexibleRecords);
          }
        }

        if (records.isEmpty) {
          print('⚠️ [Flutter] No records found for email: $email in Database table');
          return null; // No mapping found for this email
        }
      }

      print('✅ [Flutter] Found ${records.length} records in Database table');

      // Combine tokens from all records for this email
      Set<String> allTokens = {};
      List<String> allGensetNames = [];

      for (var record in records) {
        final fields = record['fields'];
        print('📋 [Flutter] Database record fields: $fields');

        // Extract tokens from this record
        List<String> recordTokens = [];

        // Try different possible field names for tokens
        if (fields['Token'] != null) {
          var tokenValue = fields['Token'];
          if (tokenValue is String && tokenValue.isNotEmpty) {
            // Check if token contains comma-separated values
            var trimmedValue = tokenValue.trim();
            if (trimmedValue.contains(',')) {
              // Split comma-separated tokens
              recordTokens.addAll(trimmedValue.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty));
            } else {
              recordTokens.add(trimmedValue);
            }
          } else if (tokenValue != null) {
            recordTokens.add(tokenValue.toString().trim());
          }
        } else if (fields['Tokens'] != null) {
          var tokensValue = fields['Tokens'];
          if (tokensValue is List) {
            recordTokens = tokensValue
                .map((t) => t.toString().trim())
                .where((t) => t.isNotEmpty)
                .toList();
          } else {
            recordTokens.add(tokensValue.toString().trim());
          }
        } else if (fields['Token (from Table 1)'] != null) {
          var tokenValue = fields['Token (from Table 1)'];
          if (tokenValue is List && tokenValue.isNotEmpty) {
            recordTokens.add(tokenValue[0].toString().trim());
          } else if (tokenValue != null) {
            recordTokens.add(tokenValue.toString().trim());
          }
        }

        // Also try alternative field names
        for (var fieldName in ['token', 'Token ID', 'Genset Token', 'Device Token']) {
          if (fields[fieldName] != null) {
            var tokenValue = fields[fieldName];
            if (tokenValue is String && tokenValue.isNotEmpty) {
              recordTokens.add(tokenValue.trim());
            } else if (tokenValue != null) {
              recordTokens.add(tokenValue.toString().trim());
            }
          }
        }

        print('🔑 [Flutter] Extracted tokens from Database record: $recordTokens');

        // Add non-empty tokens to the set (to avoid duplicates)
        allTokens.addAll(recordTokens.where((token) => token.isNotEmpty));

        // Collect genset names for logging
        if (fields['Genset Name'] != null) {
          allGensetNames.add(fields['Genset Name'].toString());
        }
      }

      final combinedTokens = allTokens.toList();
      print('🔑 [Flutter] Final tokens from Database table: $combinedTokens');
      print('📋 [Flutter] Genset names found: $allGensetNames');
      print('🎯 [Flutter] Database table returned ${combinedTokens.length} tokens for email: $email');

      return CustomerMapping(
        email: email,
        tokens: combinedTokens,
      );
    } catch (e) {
      print('❌ [Flutter] Error fetching from Database table: $e');
      throw Exception('Failed to fetch customer mapping: $e');
    }
  }
}
