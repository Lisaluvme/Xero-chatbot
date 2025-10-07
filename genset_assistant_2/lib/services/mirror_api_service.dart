import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mirror_api_model.dart';
import '../models/mirror_genset_model.dart';

class MirrorApiService {
  static const String baseUrl = 'https://mirrorapi.netlify.app';

  /// Send user data to Mirror API after successful login
  static Future<MirrorApiResponse> sendUserData({
    required String uid,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return MirrorApiResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to send user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Mirror API Error: $e');
      // Return error response
      return MirrorApiResponse(
        status: 'error',
        message: 'Failed to connect to Mirror API: $e',
      );
    }
  }

  /// Get user data from Mirror API by UID
  static Future<MirrorApiResponse> getUserData(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/$uid'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return MirrorApiResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to get user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Mirror API Error: $e');
      return MirrorApiResponse(
        status: 'error',
        message: 'Failed to get user data: $e',
      );
    }
  }

  /// Get gensets data from Mirror API
  static Future<List<MirrorGenset>> getGensets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/gensets'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body) as List;
        return jsonData.map((item) => MirrorGenset.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get gensets: ${response.statusCode}');
      }
    } catch (e) {
      print('Mirror API Error: $e');
      return [];
    }
  }
}
