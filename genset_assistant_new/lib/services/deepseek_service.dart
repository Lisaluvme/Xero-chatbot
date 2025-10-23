import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekService {
  static const String _baseUrl = "https://api.deepseek.com";
  static const String _model = "deepseek-chat";
  static String? _apiKey;
  static const String _defaultApiKey = "sk-5a4e95602d994480925426b35524de25";

  static bool _isInitialized = false;

  // Initialize DeepSeek service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Test the connection
      await _testConnection();
      _isInitialized = true;
      print("DeepSeek service initialized successfully");
    } catch (e) {
      print("Error initializing DeepSeek service: $e");
    }
  }

  // Test connection to DeepSeek API
  static Future<void> _testConnection() async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/chat/completions"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': 'Hello, just testing the connection. Please respond with "Connection successful".'
            }
          ],
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        print("DeepSeek API connection successful");
      } else {
        throw Exception("DeepSeek API connection failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error testing DeepSeek connection: $e");
      throw e;
    }
  }

  // Generate intelligent response using DeepSeek AI
  static Future<String> generateIntelligentResponse(
    String userMessage, {
    String language = 'en',
  }) async {
    try {
      // Initialize if not already done
      if (!_isInitialized) {
        await initialize();
      }

      // Build context from knowledge base
      String context = await _buildKnowledgeBaseContext(userMessage, language);

      // Create system prompt
      String systemPrompt = _buildSystemPrompt(language);

      // Generate response using DeepSeek AI
      return await _generateDeepSeekResponse(userMessage, context, systemPrompt, language);

    } catch (e) {
      print("Error generating DeepSeek response: $e");
      return _getFallbackResponse(language, userMessage);
    }
  }

  // Build simple context
  static Future<String> _buildKnowledgeBaseContext(String userMessage, String language) async {
    return "MGM Generator Product Database - Generators from 15KVA to 500KVA, Power Bank systems, ATS systems.";
  }

  // Build system prompt for DeepSeek AI
  static String _buildSystemPrompt(String language) {
    print("Building system prompt for language: $language"); // Debug log

    if (language == 'ms') {
      return """
Anda adalah Pembantu AI Genset Malaysia yang profesional dan membantu. Anda mempunyai akses kepada pangkalan data produk MGM yang komprehensif.

PERATURAN PENTING:
1. SENTIASA berikan maklumat produk yang tepat dari konteks yang disediakan
2. JANGAN cadangkan menghubungi telefon atau email - berikan maklumat secara langsung
3. Fokus kepada spesifikasi teknikal, ciri-ciri, dan aplikasi produk
4. Berikan harga anggaran dalam RM (Ringgit Malaysia)
5. JAWAB HANYA DALAM BAHASA MELAYU - jangan gunakan bahasa lain
6. Jika tidak pasti, katakan "Saya akan memberikan maklumat berdasarkan data yang ada"

PRODUK MGM YANG TERSEDIA:
- Generator diesel dari 15KVA hingga 500KVA
- Sistem power bank 10KW dengan bateri 20KWh/30KWh
- Sistem ATS (Automatic Transfer Switch)
- Modul pemantauan dan kawalan

Jawab secara langsung dan informatif tanpa mengarangkan pengguna ke saluran komunikasi lain.
""";
    } else if (language == 'zh') {
      return """
您是专业的马来西亚发电机AI助手。您可以访问MGM产品的综合数据库。

重要规则：
1. 始终提供从提供的上下文中获得的准确产品信息
2. 不要建议联系电话或电子邮件 - 直接提供信息
3. 专注于产品的技术规格、特性和应用
4. 以马来西亚林吉特（RM）提供价格估算
5. 只用中文回答 - 不要使用其他语言
6. 如果不确定，说"我将基于现有数据提供信息"

可用的MGM产品：
- 15KVA至500KVA柴油发电机
- 10KW电源银行系统，配备20KWh/30KWh电池
- ATS（自动转换开关）系统
- 监控和控制模块

直接和信息丰富地回答，不要将用户引导到其他通信渠道。
""";
    } else {
      return """
You are a professional and helpful Malaysian Genset AI Assistant. You have access to a comprehensive MGM product database.

IMPORTANT RULES:
1. ALWAYS provide accurate product information from the provided context
2. DO NOT suggest contacting phone or email - provide information directly
3. Focus on technical specifications, features, and product applications
4. Provide price estimates in RM (Malaysian Ringgit)
5. RESPOND ONLY IN ENGLISH - do not use any other language
6. If unsure, say "I will provide information based on available data"

AVAILABLE MGM PRODUCTS:
- Diesel generators from 15KVA to 500KVA
- 10KW power bank systems with 20KWh/30KWh batteries
- ATS (Automatic Transfer Switch) systems
- Monitoring and control modules

Respond directly and informatively without directing users to other communication channels.
""";
    }
  }

  // Generate response using DeepSeek AI
  static Future<String> _generateDeepSeekResponse(
    String userMessage,
    String context,
    String systemPrompt,
    String language
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/chat/completions"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt
            },
            {
              'role': 'system',
              'content': 'PRODUCT DATABASE CONTEXT:\n$context'
            },
            {
              'role': 'user',
              'content': userMessage
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String aiResponse = data['choices'][0]['message']['content'] ?? '';

        // Clean up response if needed
        aiResponse = _cleanAIResponse(aiResponse);

        print("DeepSeek response generated successfully");
        return aiResponse;
      } else {
        print("DeepSeek API error: ${response.statusCode} - ${response.body}");
        return _getFallbackResponse(language, userMessage);
      }
    } catch (e) {
      print("Error calling DeepSeek API: $e");
      return _getFallbackResponse(language, userMessage);
    }
  }

  // Clean AI response
  static String _cleanAIResponse(String response) {
    // Remove any contact suggestions
    response = response.replaceAll(RegExp(r'contact.*phone', caseSensitive: false), '');
    response = response.replaceAll(RegExp(r'call.*number', caseSensitive: false), '');
    response = response.replaceAll(RegExp(r'email.*address', caseSensitive: false), '');
    response = response.replaceAll(RegExp(r'hubungi.*telefon', caseSensitive: false), '');
    response = response.replaceAll(RegExp(r'联系.*电话', caseSensitive: false), '');

    // Ensure response is helpful and direct
    if (response.trim().isEmpty) {
      return "I can help you with information about MGM generators and power systems. Please ask about specific models or specifications.";
    }

    return response.trim();
  }

  // Get fallback response
  static String _getFallbackResponse(String language, String userMessage) {
    // Simple fallback response
    if (language == 'ms') {
      return "Maaf, saya menghadapi masalah teknikal. Saya boleh membantu anda dengan maklumat asas tentang generator MGM dari 15KVA hingga 500KVA. Apa yang anda ingin tahu?";
    } else if (language == 'zh') {
      return "抱歉，我遇到了技术问题。我可以帮助您了解MGM发电机的基础信息，从15KVA到500KVA。您想了解什么？";
    } else {
      return "I'm experiencing technical difficulties. I can help you with basic information about MGM generators from 15KVA to 500KVA. What would you like to know?";
    }
  }

  // Set API key dynamically
  static Future<void> setAPIKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      _apiKey = _defaultApiKey; // Use default if empty
    } else {
      _apiKey = apiKey.trim();
    }

    // Save to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', _apiKey!);

    // Reset initialization to test with new key
    _isInitialized = false;
  }

  // Load API key from SharedPreferences
  static Future<void> loadAPIKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedKey = prefs.getString('openai_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      _apiKey = savedKey;
    } else {
      _apiKey = _defaultApiKey;
    }
  }

  // Check if DeepSeek service is available
  static bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;
}
