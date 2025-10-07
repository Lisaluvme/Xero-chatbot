import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store user data with UID and utoken
  Future<void> storeUserData(String uid, String email, String utoken) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'utoken': utoken,
      });
    } catch (e) {
      throw Exception('Failed to store user data: $e');
    }
  }

  // Fetch utoken for a given UID
  Future<String?> getUtoken(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['utoken'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch utoken: $e');
    }
  }

  // Create new user document with email as Document ID
  Future<Map<String, dynamic>> createUserDocument(String email) async {
    try {
      final now = DateTime.now().toIso8601String();
      final userData = {
        'role': 'customer',
        'utokens': <String>[], // Empty array initially
        'createdAt': now,
        'updatedAt': now,
      };

      await _firestore.collection('users').doc(email).set(userData);

      return {
        'userEmail': email,
        'generated': <String>[], // Empty array as specified
        'createdAt': now,
        'updatedAt': now,
      };
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Get user document by email
  Future<Map<String, dynamic>?> getUserDocument(String email) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(email).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user document: $e');
    }
  }

  // Add utoken to user's utokens array
  Future<void> addUtokenToUser(String email, String utoken) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'utokens': FieldValue.arrayUnion([utoken]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add utoken: $e');
    }
  }

  // Set utokens array for user (for reverting if needed)
  Future<void> setUtokensForUser(String email, List<String> utokens) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'utokens': utokens,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to set utokens: $e');
    }
  }

  // Log chat interaction with error code detection
  Future<void> logChatInteraction({
    required String userId,
    required String userMessage,
    required String botResponse,
    required String language,
    List<String>? detectedErrorCodes,
    String? intent,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      await _firestore.collection('chat_logs').add({
        'userId': userId,
        'userMessage': userMessage,
        'botResponse': botResponse,
        'language': language,
        'detectedErrorCodes': detectedErrorCodes ?? [],
        'intent': intent ?? 'general_inquiry',
        'contextData': contextData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } catch (e) {
      print('Failed to log chat interaction: $e');
      // Don't throw exception to avoid breaking chat flow
    }
  }

  // Log error code detection specifically
  Future<void> logErrorCodeDetection({
    required String userId,
    required String errorCode,
    required String userMessage,
    required String severity,
    required String description,
    String? intent,
  }) async {
    try {
      await _firestore.collection('error_code_logs').add({
        'userId': userId,
        'errorCode': errorCode,
        'userMessage': userMessage,
        'severity': severity,
        'description': description,
        'intent': intent ?? 'error_code_query',
        'timestamp': FieldValue.serverTimestamp(),
        'resolved': false,
      });
    } catch (e) {
      print('Failed to log error code detection: $e');
    }
  }

  // Get chat history for a user
  Future<List<Map<String, dynamic>>> getChatHistory(String userId, {int limit = 50}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('chat_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Failed to get chat history: $e');
      return [];
    }
  }

  // Get error code statistics
  Future<Map<String, dynamic>> getErrorCodeStats({String? userId, DateTime? startDate}) async {
    try {
      Query query = _firestore.collection('error_code_logs');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      QuerySnapshot querySnapshot = await query.get();

      Map<String, int> errorCodeCounts = {};
      Map<String, int> severityCounts = {};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String errorCode = data['errorCode'] ?? 'unknown';
        String severity = data['severity'] ?? 'unknown';

        errorCodeCounts[errorCode] = (errorCodeCounts[errorCode] ?? 0) + 1;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return {
        'totalErrors': querySnapshot.docs.length,
        'errorCodeCounts': errorCodeCounts,
        'severityCounts': severityCounts,
        'mostCommonError': errorCodeCounts.isNotEmpty
            ? errorCodeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      print('Failed to get error code stats: $e');
      return {
        'totalErrors': 0,
        'errorCodeCounts': {},
        'severityCounts': {},
        'mostCommonError': null,
      };
    }
  }

  // Mark error code as resolved
  Future<void> markErrorCodeResolved(String errorLogId) async {
    try {
      await _firestore.collection('error_code_logs').doc(errorLogId).update({
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to mark error code as resolved: $e');
    }
  }
}
