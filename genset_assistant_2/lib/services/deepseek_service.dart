import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'knowledge_base_service.dart';
import '../features/ai_chat/ai_chat_page.dart';

class DeepSeekService {
  static bool _isInitialized = false;
  static String? _apiKey;
  static const String _defaultModel = "deepseek-chat";
  static const String _baseUrl = "https://api.deepseek.com/v1";
  
  // Initialize DeepSeek with API key
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Try to get API key from secure storage or environment
      _apiKey = await _getAPIKey();
      
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        OpenAI.apiKey = _apiKey!;
        OpenAI.baseUrl = _baseUrl;
        _isInitialized = true;
        print("DeepSeek service initialized successfully");
      } else {
        print("DeepSeek API key not found. Using fallback mode.");
      }
    } catch (e) {
      print("Error initializing DeepSeek: $e");
    }
  }
  
  static Future<String?> _getAPIKey() async {
    try {
      // First try to get from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedKey = prefs.getString('openai_api_key');
      
      if (savedKey != null && savedKey.isNotEmpty) {
        return savedKey;
      }
      
      // For demo purposes, you can set your API key here
      // In production, this should be stored securely
      return 'sk-5a4e95602d994480925426b35524de25';
      
      return null;
    } catch (e) {
      print("Error getting API key: $e");
      return null;
    }
  }
  
  // Set API key (for admin/settings page)
  static Future<void> setAPIKey(String apiKey) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('openai_api_key', apiKey);
      _apiKey = apiKey;
      OpenAI.apiKey = apiKey;
      _isInitialized = true;
      print("OpenAI API key updated successfully");
    } catch (e) {
      print("Error setting API key: $e");
    }
  }
  
  // Generate intelligent response using OpenAI + database
  static Future<String> generateIntelligentResponse(
    String userMessage, {
    String language = 'en',
    List<ChatMessage>? conversationHistory,
  }) async {
    // Initialize if not already done
    await initialize();
    
    // If OpenAI is not available, fallback to knowledge base
    if (!_isInitialized || _apiKey == null) {
      print("OpenAI not available, using fallback response");
      return await _generateFallbackResponse(userMessage, language, conversationHistory);
    }
    
    try {
      // Get relevant database information
      String databaseContext = await _getDatabaseContext(userMessage);
      
      // Build conversation context
      String conversationContext = _buildConversationContext(conversationHistory);
      
      // Create system prompt with database knowledge
      String systemPrompt = _buildSystemPrompt(language, databaseContext);
      
      // Create messages for OpenAI
      List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': systemPrompt,
        },
      ];
      
      // Add conversation history
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        for (var message in conversationHistory.take(10)) { // Limit to last 10 messages
          messages.add({
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          });
        }
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      // Generate response
      OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
        model: _defaultModel,
        messages: messages.map((msg) => OpenAIChatCompletionChoiceMessageModel(
          role: msg['role'] == 'user' ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(msg['content'] ?? ''),
          ],
        )).toList(),
        temperature: 0.7,
        maxTokens: 1000,
      );
      
      String response = chatCompletion.choices.first.message.content?.first?.text ?? "";
      
      // Post-process response to ensure it's helpful and accurate
      response = _postProcessResponse(response, userMessage, language);
      
      return response;
      
    } catch (e) {
      print("Error generating OpenAI response: $e");
      // Fallback to knowledge base if OpenAI fails
      return await _generateFallbackResponse(userMessage, language, conversationHistory);
    }
  }
  
  // Get relevant information from database based on user query
  static Future<String> _getDatabaseContext(String userMessage) async {
    StringBuffer context = StringBuffer();
    
    try {
      // Load knowledge base
      await KnowledgeBaseService.loadKnowledgeBase();
      Map<String, dynamic>? kb = KnowledgeBaseService.getKnowledgeBase();
      
      if (kb == null) return "";
      
      String lowerMessage = userMessage.toLowerCase();
      
      // Extract relevant product information
      context.writeln("=== RELEVANT PRODUCT DATABASE ===");
      
      // Generator information
      if (_containsGeneratorKeywords(lowerMessage)) {
        context.writeln("\n--- GENERATORS ---");
        List<dynamic> generators = kb['generators'] ?? [];
        for (var generator in generators.take(5)) { // Limit to top 5
          if (_isRelevantGenerator(generator, lowerMessage)) {
            context.writeln("${generator['name']} - ${generator['power']}");
            context.writeln("Brand: ${generator['brand']}");
            context.writeln("Model: ${generator['model']}");
            
            // Key specifications
            Map<String, dynamic> specs = generator['specifications'] ?? {};
            context.writeln("Key Specs: Fuel Consumption: ${specs['fuel_consumption'] ?? 'N/A'}, Dimensions: ${specs['dimensions'] ?? 'N/A'}");
            
            // Applications
            List<String> applications = (generator['applications'] as List<dynamic>?)?.map((item) => item.toString()).take(3).toList() ?? [];
            context.writeln("Applications: ${applications.join(', ')}");
            context.writeln("---");
          }
        }
      }
      
      // ATS information
      if (_containsATSKeywords(lowerMessage)) {
        context.writeln("\n--- ATS SYSTEMS ---");
        List<dynamic> atsSystems = kb['ats_systems'] ?? [];
        for (var ats in atsSystems.take(3)) {
          context.writeln("${ats['name']} - ${ats['brand']}");
          context.writeln("Category: ${ats['category']}");
          context.writeln("Description: ${ats['description']?.substring(0, 200) ?? 'N/A'}...");
          context.writeln("---");
        }
      }
      
      // AVS information
      if (_containsAVSKeywords(lowerMessage)) {
        context.writeln("\n--- AVS SYSTEMS ---");
        List<dynamic> avsSystems = kb['avs_systems'] ?? [];
        for (var avs in avsSystems.take(3)) {
          context.writeln("${avs['name']} - ${avs['brand']}");
          context.writeln("Models: ${avs['specifications']?['models_available']?.join(', ') ?? 'N/A'}");
          context.writeln("Applications: ${(avs['applications'] as List<dynamic>?)?.map((item) => item.toString()).take(3).join(', ') ?? 'N/A'}");
          context.writeln("---");
        }
      }
      
      // Power bank information
      if (_containsPowerBankKeywords(lowerMessage)) {
        context.writeln("\n--- POWER BANKS ---");
        List<dynamic> powerBanks = kb['power_banks'] ?? [];
        for (var pb in powerBanks.take(3)) {
          context.writeln("${pb['name']} - ${pb['power']}");
          context.writeln("Capacity: ${pb['specifications']?['capacity'] ?? 'N/A'}");
          context.writeln("Applications: ${(pb['applications'] as List<dynamic>?)?.map((item) => item.toString()).take(3).join(', ') ?? 'N/A'}");
          context.writeln("---");
        }
      }
      
      // Oversight modules
      if (_containsOversightKeywords(lowerMessage)) {
        context.writeln("\n--- OVERSIGHT MODULES ---");
        List<dynamic> oversightModules = kb['oversight_modules'] ?? [];
        for (var om in oversightModules.take(3)) {
          context.writeln("${om['name']} - ${om['brand']}");
          context.writeln("Features: ${(om['features'] as List<dynamic>?)?.map((item) => item.toString()).take(3).join(', ') ?? 'N/A'}");
          context.writeln("---");
        }
      }
      
    } catch (e) {
      print("Error getting database context: $e");
    }
    
    return context.toString();
  }
  
  // Build system prompt for OpenAI
  static String _buildSystemPrompt(String language, String databaseContext) {
    String basePrompt = """
You are an expert assistant for Genset Assistant, a company that specializes in generators, power systems, and related equipment. You have access to a comprehensive database of products and technical information.

Your role is to:
1. Provide accurate, helpful information about generators, ATS systems, AVS systems, power banks, and oversight modules
2. Help customers choose the right products for their needs
3. Explain technical concepts in an accessible way
4. Provide installation and maintenance guidance
5. Handle pricing inquiries by directing to sales team

IMPORTANT GUIDELINES:
- Always base your answers on the provided database information
- If you don't know something, admit it and suggest contacting the sales team
- Be professional, helpful, and customer-focused
- For pricing inquiries, always direct to the sales team for accurate quotes
- For technical questions, provide detailed but understandable explanations
- Consider the user's likely expertise level and adjust your language accordingly

DATABASE CONTEXT:
$databaseContext

RESPONSE LANGUAGE: ${language.toUpperCase()}
""";

    // Add language-specific instructions
    if (language == 'ms') {
      basePrompt += "\n\nTunjukkan respons dalam Bahasa Malaysia dengan sopan dan profesional.";
    } else if (language == 'zh') {
      basePrompt += "\n\n请用专业和礼貌的方式用中文回应。";
    } else {
      basePrompt += "\n\nRespond in professional and helpful English.";
    }
    
    return basePrompt;
  }
  
  // Build conversation context string
  static String _buildConversationContext(List<ChatMessage>? conversationHistory) {
    if (conversationHistory == null || conversationHistory.isEmpty) {
      return "";
    }
    
    StringBuffer context = StringBuffer();
    context.writeln("=== RECENT CONVERSATION ===");
    
    for (var message in conversationHistory.take(5)) { // Last 5 messages
      String role = message.isUser ? "User" : "Assistant";
      context.writeln("$role: ${message.text}");
    }
    
    return context.toString();
  }
  
  // Post-process OpenAI response
  static String _postProcessResponse(String response, String userMessage, String language) {
    // Ensure response is helpful and accurate
    if (response.trim().isEmpty) {
      return _getLocalizedFallback(language);
    }
    
    // Add helpful suggestions if appropriate
    if (userMessage.toLowerCase().contains('help') || userMessage.toLowerCase().contains('what can you do')) {
      response += _getHelpfulSuggestions(language);
    }
    
    // Ensure contact information for pricing inquiries
    if (userMessage.toLowerCase().contains('price') || userMessage.toLowerCase().contains('cost')) {
      response += _getContactInfo(language);
    }
    
    return response;
  }
  
  // Fallback response when OpenAI is not available
  static Future<String> _generateFallbackResponse(
    String userMessage,
    String language,
    List<ChatMessage>? conversationHistory,
  ) async {
    // Use existing knowledge base service as fallback
    return await KnowledgeBaseService.generateIntelligentResponse(
      userMessage,
      language: language,
      conversationHistory: conversationHistory,
    );
  }
  
  // Helper methods for keyword detection
  static bool _containsGeneratorKeywords(String message) {
    return message.contains('generator') || 
           message.contains('genset') || 
           message.contains('kva') || 
           message.contains('kw') ||
           message.contains('power') ||
           message.contains('engine');
  }
  
  static bool _containsATSKeywords(String message) {
    return message.contains('ats') || 
           message.contains('transfer') || 
           message.contains('switch') ||
           message.contains('automatic');
  }
  
  static bool _containsAVSKeywords(String message) {
    return message.contains('avs') || 
           message.contains('voltage') || 
           message.contains('stabilizer') ||
           message.contains('vst');
  }
  
  static bool _containsPowerBankKeywords(String message) {
    return message.contains('power bank') || 
           message.contains('battery') || 
           message.contains('dc power');
  }
  
  static bool _containsOversightKeywords(String message) {
    return message.contains('oversight') || 
           message.contains('monitoring') || 
           message.contains('remote');
  }
  
  static bool _isRelevantGenerator(Map<String, dynamic> generator, String message) {
    String name = (generator['name'] as String? ?? '').toLowerCase();
    String power = (generator['power'] as String? ?? '').toLowerCase();
    String brand = (generator['brand'] as String? ?? '').toLowerCase();
    String model = (generator['model'] as String? ?? '').toLowerCase();
    
    return message.contains(name) || 
           message.contains(power) || 
           message.contains(brand) || 
           message.contains(model) ||
           message.contains('kva') ||
           message.contains('kw');
  }
  
  // Helper methods for localized responses
  static String _getLocalizedFallback(String language) {
    switch (language) {
      case 'ms':
        return "Maaf, saya menghadapi masalah teknikal. Sila cuba lagi atau hubungi pasukan jualan kami.";
      case 'zh':
        return "抱歉，我遇到了技术问题。请再试一次或联系我们的销售团队。";
      default:
        return "I'm experiencing technical difficulties. Please try again or contact our sales team.";
    }
  }
  
  static String _getHelpfulSuggestions(String language) {
    switch (language) {
      case 'ms':
        return "\n\n💡 **Boleh saya bantu anda dengan:**\n• Maklumat produk generator\n• Panduan pemasangan ATS\n• Spesifikasi AVS\n• Cadangan power bank\n• Maklumat modul oversight";
      case 'zh':
        return "\n\n💡 **我可以帮助您：**\n• 发电机产品信息\n• ATS安装指南\n• AVS规格\n• 电源银行建议\n• 监控模块信息";
      default:
        return "\n\n💡 **I can help you with:**\n• Generator product information\n• ATS installation guides\n• AVS specifications\n• Power bank recommendations\n• Oversight module information";
    }
  }
  
  static String _getContactInfo(String language) {
    switch (language) {
      case 'ms':
        return "\n\n📞 **Untuk sebut harga yang tepat, sila hubungi:**\n• Telefon: +6012-3456789\n• Email: sales@gensetassistant.com\n• WhatsApp: +6012-3456789";
      case 'zh':
        return "\n\n📞 **如需准确报价，请联系：**\n• 电话：+6012-3456789\n• 邮箱：sales@gensetassistant.com\n• WhatsApp：+6012-3456789";
      default:
        return "\n\n📞 **For accurate pricing, please contact:**\n• Phone: +6012-3456789\n• Email: sales@gensetassistant.com\n• WhatsApp: +6012-3456789";
    }
  }
  
  // Check if OpenAI is available
  static bool get isAvailable => _isInitialized && _apiKey != null;
  
  // Get current model
  static String get currentModel => _defaultModel;
}
