import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mirror_api_model.dart';
import '../models/mirror_genset_model.dart';

class MirrorApiService {
  // ✅ Netlify Serverless Functions 路径
  static const String baseUrl = 'https://mirrorapi.netlify.app/.netlify/functions';

  static List<String>? _customerUtokens;
  static List<String>? _customerApiUrls;

  /// ✅ 设置单个客户凭证
  static Future<void> setApiCredentials(String utoken, String apiUrl) async {
    _customerUtokens = [utoken];
    _customerApiUrls = [apiUrl];
    print('🔗 Mirror API credentials set: Utoken=${utoken.substring(0, 8)}..., URL=$apiUrl');
  }

  /// ✅ 设置多个客户凭证
  static Future<void> setMultipleApiCredentials(List<String> utokens, List<String> apiUrls) async {
    _customerUtokens = utokens;
    _customerApiUrls = apiUrls;
    print('🔗 Multiple Mirror credentials set: ${utokens.length} utokens');
  }

  /// ✅ 检查是否已链接
  static bool hasLinkedCredentials() {
    return _customerUtokens != null && _customerUtokens!.isNotEmpty &&
        _customerApiUrls != null && _customerApiUrls!.isNotEmpty;
  }

  /// ✅ 获取 genset 数据
  static Future<List<MirrorGenset>> getGensets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();

      final headers = {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      };

      if (_customerUtokens != null && _customerUtokens!.isNotEmpty) {
        headers['x-customer-utokens'] = jsonEncode(_customerUtokens);
      }
      if (_customerApiUrls != null && _customerApiUrls!.isNotEmpty) {
        headers['x-customer-api-urls'] = jsonEncode(_customerApiUrls);
      }

      final uri = Uri.parse('$baseUrl/gensets');
      print('🌍 [MirrorAPI] Requesting: $uri');
      final response = await http.get(uri, headers: headers);
      print('📦 [MirrorAPI] Status: ${response.statusCode}');
      print('🧩 [MirrorAPI] Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          final data = jsonData['data'];
          if (data is Map && data.containsKey('list')) {
            final List<dynamic> list = data['list'];
            return list.map((item) => MirrorGenset.fromJson(item)).toList();
          }
        }

        if (jsonData is List) {
          // 兼容旧版返回
          return jsonData.map((item) => MirrorGenset.fromJson(item)).toList();
        }

        print('⚠️ Unexpected data format: $jsonData');
        return [];
      } else {
        print('❌ MirrorAPI gensets failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 MirrorAPI Error (getGensets): $e');
      return [];
    }
  }

  /// ✅ 同步数据 (登录后)
  static Future<MirrorSyncResponse> syncAfterLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      if (_customerUtokens != null && _customerUtokens!.isNotEmpty) {
        headers['x-customer-utokens'] = jsonEncode(_customerUtokens);
      }
      if (_customerApiUrls != null && _customerApiUrls!.isNotEmpty) {
        headers['x-customer-api-urls'] = jsonEncode(_customerApiUrls);
      }

      final uri = Uri.parse('$baseUrl/sync');
      print('🔁 [MirrorAPI] Sync URL: $uri');
      final response = await http.post(uri, headers: headers);

      print('📦 Sync Status: ${response.statusCode}');
      print('🧩 Sync Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MirrorSyncResponse.fromJson(data);
      } else {
        throw Exception('Failed to sync: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 MirrorAPI Sync Error: $e');
      return MirrorSyncResponse(
        success: false,
        message: 'Failed to sync Mirror API: $e',
        gensetData: null,
      );
    }
  }

  // ✅ Send User Data
  static Future<MirrorApiResponse> sendUserData({
    required String uid,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'email': email}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MirrorApiResponse.fromJson(data);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 MirrorAPI Error (sendUserData): $e');
      return MirrorApiResponse(status: 'error', message: '$e');
    }
  }

  // ✅ Get User Data
  static Future<MirrorApiResponse> getUserData(String uid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$uid'));
      if (response.statusCode == 200) {
        return MirrorApiResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 MirrorAPI Error (getUserData): $e');
      return MirrorApiResponse(status: 'error', message: '$e');
    }
  }
}
