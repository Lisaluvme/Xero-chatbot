import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mirror_api_model.dart';
import '../models/mirror_genset_model.dart';

class MirrorApiService {
  // ✅ Netlify Serverless Functions 的正确路径
  static const String baseUrl = 'https://mirrorapi.netlify.app/.netlify/functions';

  static Future<MirrorApiResponse> sendUserData({
    required String uid,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user'),
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
      print('Mirror API Error (sendUserData): $e');
      return MirrorApiResponse(
        status: 'error',
        message: 'Failed to connect to Mirror API: $e',
      );
    }
  }

  static Future<MirrorApiResponse> getUserData(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$uid'),
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
      print('Mirror API Error (getUserData): $e');
      return MirrorApiResponse(
        status: 'error',
        message: 'Failed to get user data: $e',
      );
    }
  }

  static Future<List<MirrorGenset>> getGensets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/gensets'),
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
      print('Mirror API Error (getGensets): $e');
      return [];
    }
  }

  static Future<MirrorSyncResponse> syncAfterLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return MirrorSyncResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to sync: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Mirror API Sync Error: $e');
      return MirrorSyncResponse(
        success: false,
        message: 'Failed to sync with Mirror API: $e',
        gensetData: null,
      );
    }
  }
}
