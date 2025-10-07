import 'dart:convert';
import 'dart:collection';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class ConversationContext {
  final List<String> messages;
  final Map<String, dynamic> contextData;
  final DateTime timestamp;

  ConversationContext({
    required this.messages,
    required this.contextData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'messages': messages,
    'contextData': contextData,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ConversationContext.fromJson(Map<String, dynamic> json) => ConversationContext(
    messages: List<String>.from(json['messages']),
    contextData: Map<String, dynamic>.from(json['contextData']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class KnowledgeBaseService {
  static Map<String, dynamic>? _knowledgeBase;
  static Map<String, dynamic>? _errorCodes;
  static List<ConversationContext> _conversationHistory = [];
  static ConversationContext? _currentContext;
  static Queue<String> _recentTopics = Queue<String>();
  static Map<String, int> _topicFrequency = {};
  static Map<String, dynamic> _conversationMemory = {};
  static List<String> _detectedErrorCodes = [];
  static String _currentIntent = 'general_inquiry';
  static String _detectedLanguage = 'en';

  static Future<void> loadKnowledgeBase() async {
    try {
      String jsonString = await rootBundle.loadString('assets/knowledge_base.json');
      _knowledgeBase = json.decode(jsonString);

      // Load error codes database
      String errorCodesString = await rootBundle.loadString('assets/error_codes.json');
      _errorCodes = json.decode(errorCodesString);

      await _loadConversationHistory();
    } catch (e) {
      print('Error loading knowledge base: $e');
      _knowledgeBase = null;
      _errorCodes = null;
    }
  }

  static Map<String, dynamic>? getKnowledgeBase() {
    return _knowledgeBase;
  }

  static Future<void> _loadConversationHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('conversation_history') ?? [];
      _conversationHistory = history.map((json) =>
        ConversationContext.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      print('Error loading conversation history: $e');
    }
  }

  static Future<void> _saveConversationHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> history = _conversationHistory.map((context) =>
        jsonEncode(context.toJson())).toList();
      await prefs.setStringList('conversation_history', history);
    } catch (e) {
      print('Error saving conversation history: $e');
    }
  }

  static String generateResponse(String userMessage, {String language = 'en'}) {
    print("DEBUG KnowledgeBaseService: generateResponse called with language: $language");
    print("DEBUG KnowledgeBaseService: userMessage: $userMessage");

    if (_knowledgeBase == null) {
      String fallback = "I don't have that data, but our sales team can assist you further.";
      print("DEBUG KnowledgeBaseService: No knowledge base, returning fallback");
      return fallback;
    }

    String message = userMessage.toLowerCase();

    // Update conversation context
    _updateContext(userMessage);

    // Enhanced response generation with context awareness
    String response = _generateContextualResponse(message, language);
    print("DEBUG KnowledgeBaseService: Generated response: ${response.substring(0, 100)}...");

    // Save conversation
    _saveToHistory(userMessage, response);

    return response;
  }

  static Future<String> generateIntelligentResponse(String userMessage, {String language = 'en', List<ChatMessage>? conversationHistory}) async {
    print("DEBUG KnowledgeBaseService: generateIntelligentResponse called with language: $language");
    print("DEBUG KnowledgeBaseService: userMessage: $userMessage");

    if (_knowledgeBase == null) {
      String fallback = _getLocalizedResponse("I'm having trouble accessing my knowledge base. Please try again later.", language);
      print("DEBUG KnowledgeBaseService: No knowledge base, returning fallback");
      return fallback;
    }

    String message = userMessage.toLowerCase();

    // Update conversation context
    _updateContext(userMessage);

    // Analyze conversation context and user intent
    Map<String, dynamic> contextAnalysis = _analyzeConversationContext(userMessage, conversationHistory ?? []);
    print("DEBUG KnowledgeBaseService: Context analysis: $contextAnalysis");

    // Generate intelligent response with enhanced context awareness
    String response = await _generateEnhancedResponse(message, language, contextAnalysis);
    print("DEBUG KnowledgeBaseService: Enhanced response: ${response.substring(0, 100)}...");

    // Save conversation
    _saveToHistory(userMessage, response);

    return response;
  }

  static void _updateContext(String userMessage) {
    // Extract topics from user message
    List<String> topics = _extractTopics(userMessage);

    // Update topic frequency
    for (String topic in topics) {
      _topicFrequency[topic] = (_topicFrequency[topic] ?? 0) + 1;
      if (_recentTopics.length >= 10) {
        _recentTopics.removeFirst();
      }
      _recentTopics.add(topic);
    }

    // Update current context
    if (_currentContext == null) {
      _currentContext = ConversationContext(
        messages: [userMessage],
        contextData: {'topics': topics, 'frequency': _topicFrequency},
        timestamp: DateTime.now(),
      );
    } else {
      _currentContext!.messages.add(userMessage);
      _currentContext!.contextData['topics'] = topics;
      _currentContext!.contextData['frequency'] = _topicFrequency;
    }
  }

  static List<String> _extractTopics(String message) {
    List<String> topics = [];
    message = message.toLowerCase();

    // Product categories
    if (message.contains('generator') || message.contains('genset')) topics.add('generator');
    if (message.contains('power bank') || message.contains('battery')) topics.add('power_bank');
    if (message.contains('ats') || message.contains('transfer switch')) topics.add('ats');
    if (message.contains('avs') || message.contains('voltage stabilizer')) topics.add('avs');
    if (message.contains('oversight') || message.contains('monitoring')) topics.add('oversight');

    // Power ranges
    if (message.contains('kva') || message.contains('kw')) {
      if (message.contains('15kva') || message.contains('15 kw')) topics.add('15kva');
      if (message.contains('30kva') || message.contains('30 kw')) topics.add('30kva');
      if (message.contains('60kva') || message.contains('60 kw')) topics.add('60kva');
      if (message.contains('100kva') || message.contains('100 kw')) topics.add('100kva');
    }

    // Technical terms
    if (message.contains('specification') || message.contains('spec')) topics.add('specifications');
    if (message.contains('price') || message.contains('cost')) topics.add('pricing');
    if (message.contains('application') || message.contains('use')) topics.add('applications');
    if (message.contains('feature')) topics.add('features');
    if (message.contains('installation') || message.contains('setup')) topics.add('installation');

    return topics;
  }

  // Handle direct product queries like "15kva", "30kva", etc.
  static String? _handleDirectProductQuery(String message, String language) {
    String lowerMessage = message.toLowerCase().trim();

    // Handle direct power queries (e.g., "15kva", "30kVA", "15 kva")
    if (lowerMessage.contains('kva') || lowerMessage.contains('kw')) {
      // Extract power numbers
      List<String> powerQueries = [];

      // Check for specific power ratings
      if (lowerMessage.contains('15kva') || lowerMessage.contains('15 kw') ||
          (lowerMessage == '15kva') || (lowerMessage == '15 kw')) {
        powerQueries.add('15kva');
      }
      if (lowerMessage.contains('30kva') || lowerMessage.contains('30 kw') ||
          (lowerMessage == '30kva') || (lowerMessage == '30 kw')) {
        powerQueries.add('30kva');
      }
      if (lowerMessage.contains('60kva') || lowerMessage.contains('60 kw') ||
          (lowerMessage == '60kva') || (lowerMessage == '60 kw')) {
        powerQueries.add('60kva');
      }
      if (lowerMessage.contains('100kva') || lowerMessage.contains('100 kw') ||
          (lowerMessage == '100kva') || (lowerMessage == '100 kw')) {
        powerQueries.add('100kva');
      }
      if (lowerMessage.contains('160kva') || lowerMessage.contains('160 kw') ||
          (lowerMessage == '160kva') || (lowerMessage == '160 kw')) {
        powerQueries.add('160kva');
      }
      if (lowerMessage.contains('250kva') || lowerMessage.contains('250 kw') ||
          (lowerMessage == '250kva') || (lowerMessage == '250 kw')) {
        powerQueries.add('250kva');
      }
      if (lowerMessage.contains('350kva') || lowerMessage.contains('350 kw') ||
          (lowerMessage == '350kva') || (lowerMessage == '350 kw')) {
        powerQueries.add('350kva');
      }
      if (lowerMessage.contains('500kva') || lowerMessage.contains('500 kw') ||
          (lowerMessage == '500kva') || (lowerMessage == '500 kw')) {
        powerQueries.add('500kva');
      }

      // If we found specific power queries, return detailed info
      if (powerQueries.isNotEmpty) {
        return _getDetailedProductInfo(powerQueries.first, language);
      }
    }

  // Handle direct product type queries
  if (lowerMessage == 'power bank' || lowerMessage == 'powerbank' ||
      lowerMessage == 'battery' || lowerMessage == 'solar') {
    // Check if power bank has been discussed before to avoid repetition
    if ((_topicFrequency['power_bank'] ?? 0) > 1) {
      return _getLocalizedResponse("I've already provided information about our power bank systems above. Would you like me to clarify any specific aspect or help you with something else?", language);
    }
    return _getPowerBankInfo(language);
  }

    if (lowerMessage == 'ats' || lowerMessage == 'transfer switch' ||
        lowerMessage == 'automatic transfer') {
      return _getATSInfo(language);
    }

    if (lowerMessage == 'generator' || lowerMessage == 'genset') {
      return _getLocalizedResponse("I have generators ranging from 15KVA to 500KVA. Please specify the power rating you're interested in (e.g., '15kVA', '30kVA', '100kVA').", language);
    }

    // Return null if no direct product query matched
    return null;
  }

  static String _getDetailedProductInfo(String powerQuery, String language) {
    List<dynamic> generators = _knowledgeBase!['generators'];

    for (var generator in generators) {
      if (generator['power'].toLowerCase().contains(powerQuery.toLowerCase()) ||
          generator['name'].toLowerCase().contains(powerQuery.toLowerCase())) {
        return _formatDetailedGensetInfo(generator, language);
      }
    }

    // If no exact match found, try to find similar power ratings
    for (var generator in generators) {
      String generatorPower = generator['power'].toLowerCase();
      if (generatorPower.contains('kva') && powerQuery.contains('kva')) {
        // Extract numbers for comparison
        String genNum = generatorPower.replaceAll(RegExp(r'[^0-9]'), '');
        String queryNum = powerQuery.replaceAll(RegExp(r'[^0-9]'), '');
        if (genNum.isNotEmpty && queryNum.isNotEmpty) {
          int? genPower = int.tryParse(genNum);
          int? queryPower = int.tryParse(queryNum);
          if (genPower != null && queryPower != null) {
            // If within 50KVA range, show as alternative
            if ((genPower - queryPower).abs() <= 50) {
              return _formatDetailedGensetInfo(generator, language) +
                     "\n\n💡 Note: This is the closest match to your ${powerQuery.toUpperCase()} request. For exact specifications, please contact our sales team.";
            }
          }
        }
      }
    }

    return _getLocalizedResponse("I don't have specific information about ${powerQuery.toUpperCase()} generators in my knowledge base. Please try asking about our available models: 15KVA, 30KVA, 60KVA, 100KVA, 160KVA, 250KVA, 350KVA, or 500KVA.", language);
  }

  static String _formatDetailedGensetInfo(Map<String, dynamic> genset, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("📋 ${genset['name']}");
      info.writeln("🔧 Model: ${genset['model']}");
      info.writeln("⚡ Kuasa: ${genset['power']}");
      info.writeln("🏭 Jenama: ${genset['brand']}");
      info.writeln("📦 Kategori: ${genset['category']}");
      info.writeln("");

      Map<String, dynamic> specs = genset['specifications'];
      info.writeln("📊 SPESIFIKASI:");
      if (specs['prime_power'] != null) info.writeln("• Kuasa Perdana: ${specs['prime_power']}");
      if (specs['engine_model'] != null) info.writeln("• Model Enjin: ${specs['engine_model']}");
      if (specs['engine_type'] != null) info.writeln("• Jenis Enjin: ${specs['engine_type']}");
      if (specs['cylinders'] != null) info.writeln("• Silinder: ${specs['cylinders']}");
      if (specs['fuel_consumption'] != null) info.writeln("• Penggunaan Bahan Api: ${specs['fuel_consumption']}");
      if (specs['fuel_tank_capacity'] != null) info.writeln("• Kapasiti Tangki: ${specs['fuel_tank_capacity']}");
      if (specs['dimensions'] != null) info.writeln("• Dimensi: ${specs['dimensions']}");
      if (specs['weight'] != null) info.writeln("• Berat: ${specs['weight']}");
      info.writeln("");

      info.writeln("✨ CIRI UTAMA:");
      List<String> features = List<String>.from(genset['features']);
      for (var feature in features.take(5)) {
        info.writeln("• $feature");
      }
      info.writeln("");

      info.writeln("🏭 APLIKASI:");
      List<String> applications = List<String>.from(genset['applications']);
      for (var application in applications.take(3)) {
        info.writeln("• $application");
      }

    } else if (language == 'zh') {
      info.writeln("📋 ${genset['name']}");
      info.writeln("🔧 型号: ${genset['model']}");
      info.writeln("⚡ 功率: ${genset['power']}");
      info.writeln("🏭 品牌: ${genset['brand']}");
      info.writeln("📦 类别: ${genset['category']}");
      info.writeln("");

      Map<String, dynamic> specs = genset['specifications'];
      info.writeln("📊 规格:");
      if (specs['prime_power'] != null) info.writeln("• 主要功率: ${specs['prime_power']}");
      if (specs['engine_model'] != null) info.writeln("• 引擎型号: ${specs['engine_model']}");
      if (specs['engine_type'] != null) info.writeln("• 引擎类型: ${specs['engine_type']}");
      if (specs['cylinders'] != null) info.writeln("• 气缸数: ${specs['cylinders']}");
      if (specs['fuel_consumption'] != null) info.writeln("• 燃油消耗: ${specs['fuel_consumption']}");
      if (specs['fuel_tank_capacity'] != null) info.writeln("• 油箱容量: ${specs['fuel_tank_capacity']}");
      if (specs['dimensions'] != null) info.writeln("• 尺寸: ${specs['dimensions']}");
      if (specs['weight'] != null) info.writeln("• 重量: ${specs['weight']}");
      info.writeln("");

      info.writeln("✨ 主要特点:");
      List<String> features = List<String>.from(genset['features']);
      for (var feature in features.take(5)) {
        info.writeln("• $feature");
      }
      info.writeln("");

      info.writeln("🏭 应用:");
      List<String> applications = List<String>.from(genset['applications']);
      for (var application in applications.take(3)) {
        info.writeln("• $application");
      }

    } else {
      info.writeln("📋 ${genset['name']}");
      info.writeln("🔧 Model: ${genset['model']}");
      info.writeln("⚡ Power: ${genset['power']}");
      info.writeln("🏭 Brand: ${genset['brand']}");
      info.writeln("📦 Category: ${genset['category']}");
      info.writeln("");

      Map<String, dynamic> specs = genset['specifications'];
      info.writeln("📊 SPECIFICATIONS:");
      if (specs['prime_power'] != null) info.writeln("• Prime Power: ${specs['prime_power']}");
      if (specs['engine_model'] != null) info.writeln("• Engine Model: ${specs['engine_model']}");
      if (specs['engine_type'] != null) info.writeln("• Engine Type: ${specs['engine_type']}");
      if (specs['cylinders'] != null) info.writeln("• Cylinders: ${specs['cylinders']}");
      if (specs['fuel_consumption'] != null) info.writeln("• Fuel Consumption: ${specs['fuel_consumption']}");
      if (specs['fuel_tank_capacity'] != null) info.writeln("• Fuel Tank Capacity: ${specs['fuel_tank_capacity']}");
      if (specs['dimensions'] != null) info.writeln("• Dimensions: ${specs['dimensions']}");
      if (specs['weight'] != null) info.writeln("• Weight: ${specs['weight']}");
      info.writeln("");

      info.writeln("✨ KEY FEATURES:");
      List<String> features = List<String>.from(genset['features']);
      for (var feature in features.take(5)) {
        info.writeln("• $feature");
      }
      info.writeln("");

      info.writeln("🏭 APPLICATIONS:");
      List<String> applications = List<String>.from(genset['applications']);
      for (var application in applications.take(3)) {
        info.writeln("• $application");
      }
    }

    return info.toString();
  }

  static String _getPowerBankInfo(String language) {
    List<dynamic> powerBanks = _knowledgeBase!['power_banks'];

    if (powerBanks.isEmpty) {
      return _getLocalizedResponse("I don't have power bank information available at the moment.", language);
    }

    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("🔋 SISTEM POWER BANK MGM");
      info.writeln("");
      info.writeln("Kami menawarkan sistem power bank 10KW dengan dua pilihan bateri:");
      info.writeln("");

      for (var powerBank in powerBanks) {
        info.writeln("📋 ${powerBank['name']}");
        info.writeln("• Model: ${powerBank['model']}");
        info.writeln("• Kuasa Inverter: ${powerBank['inverter_specifications']['rated_power']}");
        info.writeln("• Kapasiti Bateri: ${powerBank['battery_specifications']['rated_energy']}");
        info.writeln("• Kitaran Hayat: ${powerBank['battery_specifications']['cycle_life']}");
        info.writeln("");
      }

      info.writeln("✨ CIRI-CIRI:");
      info.writeln("• Inverter solar gelombang sinus tulen");
      info.writeln("• Pengecas MPPT terbina dalam");
      info.writeln("• Teknologi bateri LiFePO4 berprestasi tinggi");
      info.writeln("• Pemantauan WiFi pilihan");
      info.writeln("• Berbilang fungsi perlindungan");
      info.writeln("");

      info.writeln("🏭 APLIKASI:");
      info.writeln("• Sandaran kuasa rumah");
      info.writeln("• Bekalan kuasa perniagaan kecil");
      info.writeln("• Penyimpanan tenaga solar");
      info.writeln("• Sistem kuasa off-grid");
      info.writeln("• Sandaran kuasa kecemasan");

    } else if (language == 'zh') {
      info.writeln("🔋 MGM 电源银行系统");
      info.writeln("");
      info.writeln("我们提供10KW电源银行系统，有两种电池选择：");
      info.writeln("");

      for (var powerBank in powerBanks) {
        info.writeln("📋 ${powerBank['name']}");
        info.writeln("• 型号: ${powerBank['model']}");
        info.writeln("• 逆变器功率: ${powerBank['inverter_specifications']['rated_power']}");
        info.writeln("• 电池容量: ${powerBank['battery_specifications']['rated_energy']}");
        info.writeln("• 循环寿命: ${powerBank['battery_specifications']['cycle_life']}");
        info.writeln("");
      }

      info.writeln("✨ 特点:");
      info.writeln("• 纯正弦波太阳能逆变器");
      info.writeln("• 内置MPPT太阳能充电器");
      info.writeln("• 高性能LiFePO4电池技术");
      info.writeln("• 可选WiFi监控功能");
      info.writeln("• 多重保护功能");
      info.writeln("");

      info.writeln("🏭 应用:");
      info.writeln("• 家庭备用电源");
      info.writeln("• 小型企业电源供应");
      info.writeln("• 太阳能储能");
      info.writeln("• 离网电源系统");
      info.writeln("• 应急备用电源");

    } else {
      info.writeln("🔋 MGM POWER BANK SYSTEMS");
      info.writeln("");
      info.writeln("We offer 10KW power bank systems with two battery options:");
      info.writeln("");

      for (var powerBank in powerBanks) {
        info.writeln("📋 ${powerBank['name']}");
        info.writeln("• Model: ${powerBank['model']}");
        info.writeln("• Inverter Power: ${powerBank['inverter_specifications']['rated_power']}");
        info.writeln("• Battery Capacity: ${powerBank['battery_specifications']['rated_energy']}");
        info.writeln("• Cycle Life: ${powerBank['battery_specifications']['cycle_life']}");
        info.writeln("");
      }

      info.writeln("✨ FEATURES:");
      info.writeln("• Pure sine wave solar inverter");
      info.writeln("• Built-in MPPT solar charger");
      info.writeln("• High-performance LiFePO4 battery technology");
      info.writeln("• Optional WiFi monitoring");
      info.writeln("• Multiple protection functions");
      info.writeln("");

      info.writeln("🏭 APPLICATIONS:");
      info.writeln("• Home backup power");
      info.writeln("• Small business power supply");
      info.writeln("• Solar energy storage");
      info.writeln("• Off-grid power systems");
      info.writeln("• Emergency power backup");
    }

    return info.toString();
  }

  static String _getATSInfo(String language) {
    List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];

    if (atsSystems.isEmpty) {
      return _getLocalizedResponse("I don't have ATS system information available at the moment.", language);
    }

    var atsSystem = atsSystems.first; // Get the first (and likely only) ATS system

    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("🔄 ${atsSystem['name']}");
      info.writeln("🏭 Jenama: ${atsSystem['brand']}");
      info.writeln("📦 Kategori: ${atsSystem['category']}");
      info.writeln("");

      info.writeln("📋 PENERANGAN:");
      info.writeln(atsSystem['description']);
      info.writeln("");

      info.writeln("⚙️ SPESIFIKASI:");
      Map<String, dynamic> specs = atsSystem['specifications'];
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
      info.writeln("");

      info.writeln("✨ CIRI UTAMA:");
      List<String> features = List<String>.from(atsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
      info.writeln("");

      info.writeln("🏭 APLIKASI:");
      List<String> applications = List<String>.from(atsSystem['applications']);
      for (var application in applications) {
        info.writeln("• $application");
      }

    } else if (language == 'zh') {
      info.writeln("🔄 ${atsSystem['name']}");
      info.writeln("🏭 品牌: ${atsSystem['brand']}");
      info.writeln("📦 类别: ${atsSystem['category']}");
      info.writeln("");

      info.writeln("📋 描述:");
      info.writeln(atsSystem['description']);
      info.writeln("");

      info.writeln("⚙️ 规格:");
      Map<String, dynamic> specs = atsSystem['specifications'];
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
      info.writeln("");

      info.writeln("✨ 主要功能:");
      List<String> features = List<String>.from(atsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
      info.writeln("");

      info.writeln("🏭 应用:");
      List<String> applications = List<String>.from(atsSystem['applications']);
      for (var application in applications) {
        info.writeln("• $application");
      }

    } else {
      info.writeln("🔄 ${atsSystem['name']}");
      info.writeln("🏭 Brand: ${atsSystem['brand']}");
      info.writeln("📦 Category: ${atsSystem['category']}");
      info.writeln("");

      info.writeln("📋 DESCRIPTION:");
      info.writeln(atsSystem['description']);
      info.writeln("");

      info.writeln("⚙️ SPECIFICATIONS:");
      Map<String, dynamic> specs = atsSystem['specifications'];
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
      info.writeln("");

      info.writeln("✨ KEY FEATURES:");
      List<String> features = List<String>.from(atsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
      info.writeln("");

      info.writeln("🏭 APPLICATIONS:");
      List<String> applications = List<String>.from(atsSystem['applications']);
      for (var application in applications) {
        info.writeln("• $application");
      }
    }

    return info.toString();
  }

  static String _generateContextualResponse(String message, String language) {
    // First, try to find relevant information by searching through all catalogue data
    String? searchResponse = _searchCatalogueForQuery(message, language);
    if (searchResponse != null) {
      return searchResponse;
    }

    // Check for conversation continuation with memory
    if (_isFollowUpQuestion(message)) {
      return _handleFollowUpWithMemory(message, language);
    }

    // Enhanced greeting with context - only if no specific query found
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return _getContextualGreeting(language);
    }

    // Check for help requests
    if (message.contains('help') || message.contains('what can you do')) {
      return _getHelpResponse(language);
    }

  // ERROR CODE DETECTION - Check for error codes first
    List<String> detectedCodes = detectErrorCodes(message);
    if (detectedCodes.isNotEmpty) {
      return _handleErrorCodeQuery(detectedCodes, message, language);
    }

    // TROUBLESHOOTING QUERIES - Check for problems first
    if (message.contains('problem') || message.contains('issue') || message.contains('troubleshoot') ||
        message.contains('not working') || message.contains('won\'t start') || message.contains('fail') ||
        message.contains('error') || message.contains('broken') || message.contains('stop') ||
        message.contains('maintenance') || message.contains('repair') || message.contains('fix')) {
      return _handleTroubleshootingQuery(message, language);
    }

    // DIRECT PRODUCT SEARCH - Check for specific product queries first
    String? directProductResponse = _handleDirectProductQuery(message, language);
    if (directProductResponse != null) {
      return directProductResponse;
    }

    // Check for comparison requests
    if (message.contains('compare') || message.contains('difference') || message.contains('vs')) {
      return _handleComparison(message, language);
    }

    // Check for recommendation requests
    if (message.contains('recommend') || message.contains('suggest') || message.contains('best')) {
      return _handleRecommendation(message, language);
    }

    // Enhanced product queries
    if (message.contains('power') || message.contains('kva') || message.contains('kw') ||
        message.contains('specification') || message.contains('model')) {
      return _findProductInfo(message, language);
    }

    // Enhanced AVS queries
    if (message.contains('avs') || message.contains('voltage stabilizer') || message.contains('vst')) {
      return _findAVSInfo(message, language);
    }

    // Application queries
    if (message.contains('application') || message.contains('use') || message.contains('suitable for')) {
      return _findApplicationInfo(message, language);
    }

    // Features queries
    if (message.contains('feature') || message.contains('include') || message.contains('has')) {
      return _findFeaturesInfo(message, language);
    }

    // Pricing queries
    if (message.contains('price') || message.contains('cost') || message.contains('quotation')) {
      return _handlePricingQuery(message, language);
    }

    // Installation queries
    if (message.contains('install') || message.contains('setup') || message.contains('maintenance')) {
      return _handleInstallationQuery(message, language);
    }

    // Contact queries
    if (message.contains('contact') || message.contains('phone') || message.contains('email') ||
        message.contains('reach') || message.contains('call') || message.contains('talk to')) {
      return _handleContactQuery(message, language);
    }

    // Default contextual response
    return _getContextualFallback(message, language);
  }

  static bool _isFollowUpQuestion(String message) {
    List<String> followUpWords = ['also', 'and', 'what about', 'how about', 'tell me more', 'more details'];
    return followUpWords.any((word) => message.contains(word)) ||
           message.startsWith('what') || message.startsWith('how') || message.startsWith('can you');
  }

  static String _handleFollowUp(String message, String language) {
    if (_currentContext == null) {
      return _getLocalizedResponse("I'd be happy to help! Could you provide more details about what you're looking for?", language);
    }

    // Analyze current context to provide relevant follow-up
    Map<String, dynamic> context = _currentContext!.contextData;
    List<String> topics = context['topics'] ?? [];

    if (topics.contains('generator') && message.contains('price')) {
      return _getLocalizedResponse("For generator pricing, I can help you get a quotation based on the model and specifications you're interested in. Would you like me to prepare a price estimate?", language);
    }

    if (topics.contains('ats') && message.contains('installation')) {
      return _getLocalizedResponse("ATS installation involves connecting the transfer switch between your main power source and generator. I can provide detailed installation guidance if you tell me which ATS model you're considering.", language);
    }

    return _getLocalizedResponse("Based on our conversation, I can provide more specific information. Could you clarify what additional details you need?", language);
  }

  static String _handleFollowUpWithMemory(String message, String language) {
    // Enhanced follow-up handling with conversation memory
    String lowerMessage = message.toLowerCase();

    // Check recent conversation history for context
    if (_conversationHistory.isNotEmpty) {
      // Get the last few conversations for context
      int historyCount = _conversationHistory.length > 3 ? 3 : _conversationHistory.length;
      List<ConversationContext> recentHistory = _conversationHistory.sublist(_conversationHistory.length - historyCount);

      // Analyze what was discussed recently
      Set<String> recentTopics = {};
      for (var context in recentHistory) {
        List<String> topics = context.contextData['topics'] ?? [];
        recentTopics.addAll(topics);
      }

      // Handle specific follow-up patterns
      if (lowerMessage.contains('more') || lowerMessage.contains('tell me more') || lowerMessage.contains('details')) {
        // User wants more information about recent topics
        if (recentTopics.contains('generator')) {
          return _getLocalizedResponse("I'd be happy to provide more details about our generators. What specific aspect would you like to know more about - specifications, pricing, installation, or maintenance?", language);
        } else if (recentTopics.contains('ats')) {
          return _getLocalizedResponse("I can give you more information about our ATS systems. Are you interested in technical specifications, installation procedures, or pricing?", language);
        } else if (recentTopics.contains('power_bank')) {
          return _getLocalizedResponse("Our power bank systems offer excellent energy storage solutions. Would you like to know about battery options, solar integration, or pricing?", language);
        }
      }

      if (lowerMessage.contains('what about') || lowerMessage.contains('how about')) {
        // User is asking about alternatives or related topics
        if (recentTopics.contains('15kva') && lowerMessage.contains('30kva')) {
          return _getDetailedProductInfo('30kVA', language);
        } else if (recentTopics.contains('30kva') && lowerMessage.contains('15kva')) {
          return _getDetailedProductInfo('15kVA', language);
        }
      }

      if (lowerMessage.contains('also') || lowerMessage.contains('and')) {
        // User wants additional information
        if (recentTopics.contains('generator') && !recentTopics.contains('ats')) {
          return _getLocalizedResponse("In addition to generators, we also offer Automatic Transfer Switches (ATS) for seamless power switching. Would you like to know more about ATS systems?", language);
        } else if (recentTopics.contains('ats') && !recentTopics.contains('power_bank')) {
          return _getLocalizedResponse("Besides ATS systems, we have power bank solutions for energy storage. Are you interested in learning about our battery backup systems?", language);
        }
      }
    }

    // Fallback to regular follow-up handling
    return _handleFollowUp(message, language);
  }

  static String _getContextualGreeting(String language) {
    String baseGreeting = _getLocalizedResponse(_knowledgeBase!['responses']['greeting'], language);
    if (_recentTopics.isNotEmpty) {
      String lastTopic = _recentTopics.last;
      return "$baseGreeting I notice we've been discussing $lastTopic. How can I help you further with that?";
    }
    return baseGreeting;
  }

  static String _getHelpResponse(String language) {
    StringBuffer help = StringBuffer();

    if (language == 'ms') {
      help.writeln("🤖 Saya adalah Pembantu Genset anda! Saya boleh membantu anda dengan:");
      help.writeln("");
      help.writeln("📋 Maklumat Produk:");
      help.writeln("• Spesifikasi dan model generator");
      help.writeln("• Sistem power bank");
      help.writeln("• ATS (Automatic Transfer Switch)");
      help.writeln("• AVS (Automatic Voltage Stabilizer)");
      help.writeln("• Modul pemantauan oversight");
      help.writeln("");
      help.writeln("🔍 Ciri-ciri Lanjutan:");
      help.writeln("• Perbandingan produk");
      help.writeln("• Cadangan berdasarkan keperluan anda");
      help.writeln("• Harga dan sebut harga");
      help.writeln("• Panduan pemasangan");
      help.writeln("• Spesifikasi teknikal");
      help.writeln("");
      help.writeln("💬 Tanya saya tentang:");
      help.writeln("• 'Tunjukkan generator 30kVA'");
      help.writeln("• 'Bandingkan model 15kVA vs 30kVA'");
      help.writeln("• 'ATS apa yang saya perlukan untuk generator?'");
      help.writeln("• 'Harga untuk VST10-4 AVS'");
      help.writeln("");
      help.writeln("Apa yang anda ingin tahu tentang produk kami?");
    } else if (language == 'zh') {
      help.writeln("🤖 我是您的发电机助手！我可以帮助您：");
      help.writeln("");
      help.writeln("📋 产品信息：");
      help.writeln("• 发电机规格和型号");
      help.writeln("• 电源银行系统");
      help.writeln("• ATS（自动转换开关）");
      help.writeln("• AVS（自动电压稳定器）");
      help.writeln("• 监督监控模块");
      help.writeln("");
      help.writeln("🔍 高级功能：");
      help.writeln("• 产品比较");
      help.writeln("• 根据您的需求推荐");
      help.writeln("• 定价和报价");
      help.writeln("• 安装指导");
      help.writeln("• 技术规格");
      help.writeln("");
      help.writeln("💬 询问我：");
      help.writeln("• '显示30kVA发电机'");
      help.writeln("• '比较15kVA vs 30kVA型号'");
      help.writeln("• '我需要什么ATS来配合发电机？'");
      help.writeln("• 'VST10-4 AVS的价格'");
      help.writeln("");
      help.writeln("您想了解我们产品的什么信息？");
    } else {
      help.writeln("🤖 I'm your Genset Assistant! I can help you with:");
      help.writeln("");
      help.writeln("📋 Product Information:");
      help.writeln("• Generator specifications and models");
      help.writeln("• Power bank systems");
      help.writeln("• ATS (Automatic Transfer Switch)");
      help.writeln("• AVS (Automatic Voltage Stabilizer)");
      help.writeln("• Oversight monitoring modules");
      help.writeln("");
      help.writeln("🔍 Advanced Features:");
      help.writeln("• Product comparisons");
      help.writeln("• Recommendations based on your needs");
      help.writeln("• Pricing and quotations");
      help.writeln("• Installation guidance");
      help.writeln("• Technical specifications");
      help.writeln("");
      help.writeln("💬 Ask me about:");
      help.writeln("• 'Show me 30kVA generators'");
      help.writeln("• 'Compare 15kVA vs 30kVA models'");
      help.writeln("• 'What ATS do I need for my generator?'");
      help.writeln("• 'Price for VST10-4 AVS'");
      help.writeln("");
      help.writeln("What would you like to know about our products?");
    }

    return help.toString();
  }

  static String _getLocalizedResponse(String englishText, String language) {
    // Simple localization - in a real app, you'd use proper i18n packages
    if (language == 'ms') {
      // Bahasa Malaysia translations
      Map<String, String> translations = {
        "Hello! I'm your Genset Assistant. I can help you with information about generators, power banks, ATS systems, AVS (Automatic Voltage Stabilizers), oversight modules, and related products. What would you like to know?":
            "Hello! Saya adalah Pembantu Genset anda. Saya boleh membantu anda dengan maklumat tentang generator, power bank, sistem ATS, AVS (Automatic Voltage Stabilizer), modul oversight, dan produk berkaitan. Apa yang anda ingin tahu?",
        "I'm having trouble accessing my knowledge base. Please try again later.":
            "Saya menghadapi masalah mengakses pangkalan pengetahuan. Sila cuba lagi sebentar.",
        "I'd be happy to help! Could you provide more details about what you're looking for?":
            "Saya dengan senang hati membantu! Bolehkah anda berikan lebih banyak detail tentang apa yang anda cari?",
        "Based on our conversation, I can provide more specific information. Could you clarify what additional details you need?":
            "Berdasarkan perbualan kita, saya boleh memberikan maklumat yang lebih spesifik. Bolehkah anda jelaskan detail tambahan yang anda perlukan?",
        "For generator pricing, I can help you get a quotation based on the model and specifications you're interested in. Would you like me to prepare a price estimate?":
            "Untuk harga generator, saya boleh membantu anda mendapatkan sebut harga berdasarkan model dan spesifikasi yang anda minati. Adakah anda mahu saya menyediakan anggaran harga?",
        "ATS installation involves connecting the transfer switch between your main power source and generator. I can provide detailed installation guidance if you tell me which ATS model you're considering.":
            "Pemasangan ATS melibatkan penyambungan suis pemindahan antara sumber kuasa utama dan generator anda. Saya boleh memberikan panduan pemasangan terperinci jika anda beritahu model ATS yang anda pertimbangkan.",
        "I can compare different models for you. Please specify which models you'd like to compare, such as 'compare 15kVA vs 30kVA generators'.":
            "Saya boleh membandingkan model yang berbeza untuk anda. Sila nyatakan model yang anda ingin bandingkan, seperti 'bandingkan generator 15kVA vs 30kVA'.",
        "Which specific product are you interested in? I have information about generators (6kVA-350kVA), power banks, ATS systems, AVS (Automatic Voltage Stabilizers) with models from 3KVA to 150KVA, oversight modules, and Zone 2 certified equipment.":
            "Produk spesifik yang manakah anda minati? Saya mempunyai maklumat tentang generator (6kVA-350kVA), power bank, sistem ATS, AVS (Automatic Voltage Stabilizer) dengan model dari 3KVA hingga 150KVA, modul oversight, dan peralatan bersertifikasi Zone 2.",
        "What will you be using the system for? Common applications include backup power, remote monitoring, automatic transfer switching, voltage stabilization, or multi-site management.":
            "Untuk apa anda akan menggunakan sistem ini? Aplikasi biasa termasuk kuasa sandaran, pemantauan jauh, suis pemindahan automatik, penstabilan voltan, atau pengurusan berbilang tapak.",
        "Please specify which product you'd like to know about.":
            "Sila nyatakan produk yang anda ingin tahu.",
        "For pricing information, I recommend contacting our sales team directly. They can provide you with current pricing, promotions, and customized quotations based on your specific requirements. Would you like their contact information?":
            "Untuk maklumat harga, saya cadangkan menghubungi pasukan jualan kami secara langsung. Mereka boleh memberikan harga semasa, promosi, dan sebut harga tersuai berdasarkan keperluan spesifik anda. Adakah anda mahu maklumat hubungan mereka?",
        "I understand you're interested in pricing. Our products are competitively priced, and I can help you understand the value proposition. Would you like me to explain the features and benefits first, or would you prefer to contact our sales team for a quotation?":
            "Saya faham anda berminat dengan harga. Produk kami berharga kompetitif, dan saya boleh membantu anda memahami nilai produk. Adakah anda mahu saya jelaskan ciri dan faedah dahulu, atau anda lebih suka menghubungi pasukan jualan kami untuk sebut harga?",
        "For delivery times and availability, I recommend contacting our sales team who can check current stock levels and provide accurate delivery estimates based on your location and requirements.":
            "Untuk masa penghantaran dan ketersediaan, saya cadangkan menghubungi pasukan jualan kami yang boleh menyemak tahap stok semasa dan memberikan anggaran penghantaran yang tepat berdasarkan lokasi dan keperluan anda.",
        "Our products come with comprehensive warranties. Generator warranties typically range from 1-2 years depending on the model, with extended warranty options available. Would you like details for a specific product?":
            "Produk kami disertakan dengan waranti komprehensif. Waranti generator biasanya antara 1-2 tahun bergantung pada model, dengan pilihan waranti lanjutan tersedia. Adakah anda mahu detail untuk produk spesifik?",
      };

      return translations[englishText] ?? englishText;
    } else if (language == 'zh') {
      // Chinese translations
      Map<String, String> translations = {
        "Hello! I'm your Genset Assistant. I can help you with information about generators, power banks, ATS systems, AVS (Automatic Voltage Stabilizers), oversight modules, and related products. What would you like to know?":
            "您好！我是您的发电机助手。我可以帮助您了解发电机、电源银行、ATS系统、AVS（自动电压稳定器）、监督模块和相关产品的信息。您想了解什么？",
        "I'm having trouble accessing my knowledge base. Please try again later.":
            "我无法访问知识库。请稍后再试。",
        "I'd be happy to help! Could you provide more details about what you're looking for?":
            "我很乐意帮忙！您能提供更多关于您要找什么的细节吗？",
        "Based on our conversation, I can provide more specific information. Could you clarify what additional details you need?":
            "基于我们的对话，我可以提供更具体的信息。您能澄清您还需要什么额外细节吗？",
        "For generator pricing, I can help you get a quotation based on the model and specifications you're interested in. Would you like me to prepare a price estimate?":
            "对于发电机定价，我可以根据您感兴趣的型号和规格帮助您获取报价。您想让我准备价格估算吗？",
        "ATS installation involves connecting the transfer switch between your main power source and generator. I can provide detailed installation guidance if you tell me which ATS model you're considering.":
            "ATS安装涉及在主电源和发电机之间连接转换开关。如果您告诉我您正在考虑的ATS型号，我可以提供详细的安装指导。",
        "I can compare different models for you. Please specify which models you'd like to compare, such as 'compare 15kVA vs 30kVA generators'.":
            "我可以为您比较不同的型号。请指定您想比较的型号，例如'比较15kVA vs 30kVA发电机'。",
        "Which specific product are you interested in? I have information about generators (6kVA-350kVA), power banks, ATS systems, AVS (Automatic Voltage Stabilizers) with models from 3KVA to 150KVA, oversight modules, and Zone 2 certified equipment.":
            "您对哪个特定产品感兴趣？我有关于发电机（6kVA-350kVA）、电源银行、ATS系统、AVS（自动电压稳定器）型号从3KVA到150KVA、监督模块和Zone 2认证设备的信息。",
        "What will you be using the system for? Common applications include backup power, remote monitoring, automatic transfer switching, voltage stabilization, or multi-site management.":
            "您将把系统用于什么用途？常见应用包括备用电源、远程监控、自动转换开关、电压稳定或多站点管理。",
        "Please specify which product you'd like to know about.":
            "请指定您想了解的产品。",
        "For pricing information, I recommend contacting our sales team directly. They can provide you with current pricing, promotions, and customized quotations based on your specific requirements. Would you like their contact information?":
            "对于定价信息，我建议直接联系我们的销售团队。他们可以根据您的具体要求提供当前定价、促销和定制报价。您想要他们的联系信息吗？",
        "I understand you're interested in pricing. Our products are competitively priced, and I can help you understand the value proposition. Would you like me to explain the features and benefits first, or would you prefer to contact our sales team for a quotation?":
            "我理解您对定价感兴趣。我们的产品定价具有竞争力，我可以帮助您了解价值主张。您想让我先解释功能和优势，还是更喜欢联系我们的销售团队获取报价？",
        "For delivery times and availability, I recommend contacting our sales team who can check current stock levels and provide accurate delivery estimates based on your location and requirements.":
            "对于交货时间和可用性，我建议联系我们的销售团队，他们可以检查当前库存水平，并根据您的位置和要求提供准确的交货估算。",
        "Our products come with comprehensive warranties. Generator warranties typically range from 1-2 years depending on the model, with extended warranty options available. Would you like details for a specific product?":
            "我们的产品都有全面的保修。发电机保修通常为1-2年，具体取决于型号，还有延长保修选项可用。您想了解特定产品的细节吗？",
      };

      return translations[englishText] ?? englishText;
    }

    return englishText;
  }

  static String _handleComparison(String message, String language) {
    // Extract models to compare
    List<String> models = [];
    if (message.contains('15kva') || message.contains('15 kw')) models.add('15kVA');
    if (message.contains('30kva') || message.contains('30 kw')) models.add('30kVA');
    if (message.contains('60kva') || message.contains('60 kw')) models.add('60kVA');

    if (models.length >= 2) {
      return _compareModels(models, language);
    }

    return _getLocalizedResponse("I can compare different models for you. Please specify which models you'd like to compare, such as 'compare 15kVA vs 30kVA generators'.", language);
  }

  static String _compareModels(List<String> models, String language) {
    StringBuffer comparison = StringBuffer();

    if (language == 'ms') {
      comparison.writeln("🔍 Perbandingan: ${models.join(' vs ')}");
      comparison.writeln("");

      List<dynamic> generators = _knowledgeBase!['generators'];
      Map<String, Map<String, dynamic>> modelSpecs = {};

      for (String model in models) {
        for (var generator in generators) {
          if (generator['power'].toLowerCase().contains(model.toLowerCase()) ||
              generator['name'].toLowerCase().contains(model.toLowerCase())) {
            modelSpecs[model] = generator;
            break;
          }
        }
      }

      if (modelSpecs.length >= 2) {
        comparison.writeln("📊 Spesifikasi Utama:");
        List<String> specsToCompare = ['engine_model', 'fuel_consumption', 'dimensions', 'weight'];

        for (String spec in specsToCompare) {
          comparison.writeln("\n$spec:");
          for (String model in models) {
            if (modelSpecs.containsKey(model)) {
              var value = modelSpecs[model]!['specifications'][spec];
              if (value != null && value.toString().isNotEmpty) {
                comparison.writeln("  $model: $value");
              }
            }
          }
        }

        comparison.writeln("\n🏭 Aplikasi:");
        for (String model in models) {
          if (modelSpecs.containsKey(model)) {
            List<String> applications = List<String>.from(modelSpecs[model]!['applications']);
            comparison.writeln("\n$model:");
            for (String app in applications.take(3)) {
              comparison.writeln("  • $app");
            }
          }
        }
      }
    } else if (language == 'zh') {
      comparison.writeln("🔍 对比: ${models.join(' vs ')}");
      comparison.writeln("");

      List<dynamic> generators = _knowledgeBase!['generators'];
      Map<String, Map<String, dynamic>> modelSpecs = {};

      for (String model in models) {
        for (var generator in generators) {
          if (generator['power'].toLowerCase().contains(model.toLowerCase()) ||
              generator['name'].toLowerCase().contains(model.toLowerCase())) {
            modelSpecs[model] = generator;
            break;
          }
        }
      }

      if (modelSpecs.length >= 2) {
        comparison.writeln("📊 主要规格:");
        List<String> specsToCompare = ['engine_model', 'fuel_consumption', 'dimensions', 'weight'];

        for (String spec in specsToCompare) {
          comparison.writeln("\n$spec:");
          for (String model in models) {
            if (modelSpecs.containsKey(model)) {
              var value = modelSpecs[model]!['specifications'][spec];
              if (value != null && value.toString().isNotEmpty) {
                comparison.writeln("  $model: $value");
              }
            }
          }
        }

        comparison.writeln("\n🏭 应用:");
        for (String model in models) {
          if (modelSpecs.containsKey(model)) {
            List<String> applications = List<String>.from(modelSpecs[model]!['applications']);
            comparison.writeln("\n$model:");
            for (String app in applications.take(3)) {
              comparison.writeln("  • $app");
            }
          }
        }
      }
    } else {
      comparison.writeln("🔍 Comparison: ${models.join(' vs ')}");
      comparison.writeln("");

      List<dynamic> generators = _knowledgeBase!['generators'];
      Map<String, Map<String, dynamic>> modelSpecs = {};

      for (String model in models) {
        for (var generator in generators) {
          if (generator['power'].toLowerCase().contains(model.toLowerCase()) ||
              generator['name'].toLowerCase().contains(model.toLowerCase())) {
            modelSpecs[model] = generator;
            break;
          }
        }
      }

      if (modelSpecs.length >= 2) {
        comparison.writeln("📊 Key Specifications:");
        List<String> specsToCompare = ['engine_model', 'fuel_consumption', 'dimensions', 'weight'];

        for (String spec in specsToCompare) {
          comparison.writeln("\n$spec:");
          for (String model in models) {
            if (modelSpecs.containsKey(model)) {
              var value = modelSpecs[model]!['specifications'][spec];
              if (value != null && value.toString().isNotEmpty) {
                comparison.writeln("  $model: $value");
              }
            }
          }
        }

        comparison.writeln("\n🏭 Applications:");
        for (String model in models) {
          if (modelSpecs.containsKey(model)) {
            List<String> applications = List<String>.from(modelSpecs[model]!['applications']);
            comparison.writeln("\n$model:");
            for (String app in applications.take(3)) {
              comparison.writeln("  • $app");
            }
          }
        }
      }
    }

    return comparison.toString();
  }

  static String _handleRecommendation(String message, String language) {
    StringBuffer recommendation = StringBuffer();

    if (language == 'ms') {
      recommendation.writeln("🎯 Cadangan Personalised");
      recommendation.writeln("");

      if (message.contains('home') || message.contains('residential')) {
        recommendation.writeln("Untuk aplikasi kuasa sandaran rumah, saya cadangkan:");
        recommendation.writeln("🏠 15kVA MGM Premium Generator - Sesuai untuk sandaran rumah");
        recommendation.writeln("   • Kuasa yang boleh diharapkan untuk peralatan rumah penting");
        recommendation.writeln("   • Reka bentuk padat sesuai untuk penggunaan kediaman");
        recommendation.writeln("   • Penyelesaian kos efektif");
      } else if (message.contains('business') || message.contains('commercial')) {
        recommendation.writeln("Untuk aplikasi kuasa komersial, saya cadangkan:");
        recommendation.writeln("🏢 30kVA-60kVA MGM Generator - Ideal untuk perniagaan kecil hingga sederhana");
        recommendation.writeln("   • Kapasiti kuasa yang lebih tinggi untuk keperluan komersial");
        recommendation.writeln("   • Kebolehpercayaan gred profesional");
        recommendation.writeln("   • Sesuai untuk bangunan pejabat dan ruang runcit");
      } else {
        recommendation.writeln("Sila berikan lebih detail tentang keperluan anda untuk cadangan yang lebih tepat.");
      }
    } else if (language == 'zh') {
      recommendation.writeln("🎯 个性化推荐");
      recommendation.writeln("");

      if (message.contains('home') || message.contains('residential')) {
        recommendation.writeln("对于家庭备用电源应用，我推荐：");
        recommendation.writeln("🏠 15kVA MGM Premium Generator - 非常适合家庭备用");
        recommendation.writeln("   • 为基本家用电器提供可靠电源");
        recommendation.writeln("   • 紧凑设计适合住宅使用");
        recommendation.writeln("   • 经济高效的解决方案");
      } else if (message.contains('business') || message.contains('commercial')) {
        recommendation.writeln("对于商业电源应用，我推荐：");
        recommendation.writeln("🏢 30kVA-60kVA MGM Generator - 非常适合中小型企业");
        recommendation.writeln("   • 为商业需求提供更高的电源容量");
        recommendation.writeln("   • 专业级可靠性");
        recommendation.writeln("   • 适合办公楼和零售空间");
      } else {
        recommendation.writeln("请提供更多关于您需求的详细信息以获得更准确的推荐。");
      }
    } else {
      recommendation.writeln("🎯 Personalized Recommendation");
      recommendation.writeln("");

      if (message.contains('home') || message.contains('residential')) {
        recommendation.writeln("For backup power applications, I recommend:");
        recommendation.writeln("🏠 15kVA MGM Premium Generator - Perfect for home backup");
        recommendation.writeln("   • Reliable power for essential home appliances");
        recommendation.writeln("   • Compact design suitable for residential use");
        recommendation.writeln("   • Cost-effective solution");
      } else if (message.contains('business') || message.contains('commercial')) {
        recommendation.writeln("For commercial power applications, I recommend:");
        recommendation.writeln("🏢 30kVA-60kVA MGM Generator - Ideal for small to medium businesses");
        recommendation.writeln("   • Higher power capacity for commercial needs");
        recommendation.writeln("   • Professional-grade reliability");
        recommendation.writeln("   • Suitable for office buildings and retail spaces");
      } else {
        recommendation.writeln("Please provide more details about your requirements for a more accurate recommendation.");
      }
    }

    return recommendation.toString();
  }

  static String _handlePricingQuery(String message, String language) {
    StringBuffer pricing = StringBuffer();

    if (language == 'ms') {
      pricing.writeln("💰 MAKLUMAT HARGA");
      pricing.writeln("");
      pricing.writeln("Harga kompetitif untuk semua produk MGM:");
      pricing.writeln("");
      pricing.writeln("⚡ GENERATOR DIESEL:");
      pricing.writeln("• 15KVA - 30KVA: RM 15,000 - RM 35,000");
      pricing.writeln("• 60KVA - 100KVA: RM 45,000 - RM 75,000");
      pricing.writeln("• 160KVA - 250KVA: RM 85,000 - RM 150,000");
      pricing.writeln("• 350KVA - 500KVA: RM 180,000 - RM 350,000");
      pricing.writeln("");
      pricing.writeln("🔋 POWER BANK 10KW:");
      pricing.writeln("• Dengan bateri 20KWh: RM 25,000 - RM 35,000");
      pricing.writeln("• Dengan bateri 30KWh: RM 35,000 - RM 45,000");
      pricing.writeln("");
      pricing.writeln("🔄 ATS SYSTEM:");
      pricing.writeln("• Automatic Transfer Switch: RM 3,500 - RM 8,000");
      pricing.writeln("");
      pricing.writeln("✨ DISKAUN & PROMOSI:");
      pricing.writeln("• Diskaun 5-15% untuk pembelian pukal");
      pricing.writeln("• Pakej pemasangan percuma untuk generator >100KVA");
      pricing.writeln("• Waranti lanjutan tersedia");
      pricing.writeln("• Servis penyelenggaraan percuma tahun pertama");
      pricing.writeln("");
      pricing.writeln("📋 FAKTOR YANG MEMPENGARUHI HARGA:");
      pricing.writeln("• Spesifikasi teknikal");
      pricing.writeln("• Kuantiti pembelian");
      pricing.writeln("• Keperluan pemasangan");
      pricing.writeln("• Lokasi penghantaran");
      pricing.writeln("");
      pricing.writeln("💡 Untuk sebut harga tepat, sila berikan:");
      pricing.writeln("• Model spesifik yang dikehendaki");
      pricing.writeln("• Kuantiti yang diperlukan");
      pricing.writeln("• Lokasi pemasangan");
      pricing.writeln("• Keperluan khas");

    } else if (language == 'zh') {
      pricing.writeln("💰 价格信息");
      pricing.writeln("");
      pricing.writeln("MGM产品具有竞争力的定价：");
      pricing.writeln("");
      pricing.writeln("⚡ 柴油发电机：");
      pricing.writeln("• 15KVA - 30KVA: RM 15,000 - RM 35,000");
      pricing.writeln("• 60KVA - 100KVA: RM 45,000 - RM 75,000");
      pricing.writeln("• 160KVA - 250KVA: RM 85,000 - RM 150,000");
      pricing.writeln("• 350KVA - 500KVA: RM 180,000 - RM 350,000");
      pricing.writeln("");
      pricing.writeln("🔋 10KW电源银行：");
      pricing.writeln("• 20KWh电池: RM 25,000 - RM 35,000");
      pricing.writeln("• 30KWh电池: RM 35,000 - RM 45,000");
      pricing.writeln("");
      pricing.writeln("🔄 ATS系统：");
      pricing.writeln("• 自动转换开关: RM 3,500 - RM 8,000");
      pricing.writeln("");
      pricing.writeln("✨ 折扣和促销：");
      pricing.writeln("• 批量购买享5-15%折扣");
      pricing.writeln("• 100KVA以上发电机免费安装");
      pricing.writeln("• 延长保修服务");
      pricing.writeln("• 第一年免费维护服务");
      pricing.writeln("");
      pricing.writeln("📋 影响价格的因素：");
      pricing.writeln("• 技术规格");
      pricing.writeln("• 购买数量");
      pricing.writeln("• 安装要求");
      pricing.writeln("• 送货地点");
      pricing.writeln("");
      pricing.writeln("💡 要获得准确报价，请提供：");
      pricing.writeln("• 所需的特定型号");
      pricing.writeln("• 所需数量");
      pricing.writeln("• 安装地点");
      pricing.writeln("• 特殊要求");

    } else {
      pricing.writeln("💰 PRICING INFORMATION");
      pricing.writeln("");
      pricing.writeln("Competitive pricing for all MGM products:");
      pricing.writeln("");
      pricing.writeln("⚡ DIESEL GENERATORS:");
      pricing.writeln("• 15KVA - 30KVA: RM 15,000 - RM 35,000");
      pricing.writeln("• 60KVA - 100KVA: RM 45,000 - RM 75,000");
      pricing.writeln("• 160KVA - 250KVA: RM 85,000 - RM 150,000");
      pricing.writeln("• 350KVA - 500KVA: RM 180,000 - RM 350,000");
      pricing.writeln("");
      pricing.writeln("🔋 10KW POWER BANKS:");
      pricing.writeln("• With 20KWh Battery: RM 25,000 - RM 35,000");
      pricing.writeln("• With 30KWh Battery: RM 35,000 - RM 45,000");
      pricing.writeln("");
      pricing.writeln("🔄 ATS SYSTEMS:");
      pricing.writeln("• Automatic Transfer Switch: RM 3,500 - RM 8,000");
      pricing.writeln("");
      pricing.writeln("✨ DISCOUNTS & PROMOTIONS:");
      pricing.writeln("• 5-15% discount for bulk purchases");
      pricing.writeln("• Free installation package for generators >100KVA");
      pricing.writeln("• Extended warranty options available");
      pricing.writeln("• First year free maintenance service");
      pricing.writeln("");
      pricing.writeln("📋 FACTORS AFFECTING PRICE:");
      pricing.writeln("• Technical specifications");
      pricing.writeln("• Quantity required");
      pricing.writeln("• Installation requirements");
      pricing.writeln("• Delivery location");
      pricing.writeln("");
      pricing.writeln("💡 For accurate quotation, please provide:");
      pricing.writeln("• Specific model required");
      pricing.writeln("• Quantity needed");
      pricing.writeln("• Installation location");
      pricing.writeln("• Special requirements");
    }

    return pricing.toString();
  }

  static String _handleInstallationQuery(String message, String language) {
    StringBuffer installation = StringBuffer();

    if (language == 'ms') {
      installation.writeln("🔧 Maklumat Pemasangan");
      installation.writeln("");

      if (message.contains('generator') || message.contains('genset')) {
        installation.writeln("Pemasangan Generator:");
        installation.writeln("• Pemasangan profesional disyorkan");
        installation.writeln("• Memerlukan asas dan pengudaraan yang betul");
        installation.writeln("• Sambungan elektrik mesti mematuhi peraturan tempatan");
        installation.writeln("• Persediaan talian bahan api dan sistem ekzos");
      }

      if (message.contains('ats')) {
        installation.writeln("\nPemasangan ATS:");
        installation.writeln("• Sambung antara kuasa utama dan generator");
        installation.writeln("• Memerlukan juruelektrik berlesen");
        installation.writeln("• Pendawaian dan konfigurasi yang betul penting");
        installation.writeln("• Pengujian fungsi pemindahan automatik");
      }

      if (message.contains('avs')) {
        installation.writeln("\nPemasangan AVS:");
        installation.writeln("• Pasang secara bersiri dengan peralatan yang hendak dilindungi");
        installation.writeln("• Padanan voltan input/output yang betul");
        installation.writeln("• Pengudaraan dan pelepasan yang mencukupi");
        installation.writeln("• Langkah pembumian dan keselamatan");
      }

      installation.writeln("");
      installation.writeln("⚠️ Sentiasa berunding dengan profesional bertauliah untuk pemasangan bagi memastikan keselamatan dan pematuhan dengan peraturan tempatan.");
    } else if (language == 'zh') {
      installation.writeln("🔧 安装信息");
      installation.writeln("");

      if (message.contains('generator') || message.contains('genset')) {
        installation.writeln("发电机安装：");
        installation.writeln("• 建议专业安装");
        installation.writeln("• 需要适当的基础和通风");
        installation.writeln("• 电气连接必须符合当地法规");
        installation.writeln("• 燃料管线和排气系统设置");
      }

      if (message.contains('ats')) {
        installation.writeln("\nATS安装：");
        installation.writeln("• 连接主电源和发电机之间");
        installation.writeln("• 需要持有执照的电工");
        installation.writeln("• 正确的布线和配置至关重要");
        installation.writeln("• 测试自动转换功能");
      }

      if (message.contains('avs')) {
        installation.writeln("\nAVS安装：");
        installation.writeln("• 与要保护的设备串联安装");
        installation.writeln("• 正确的输入/输出电压匹配");
        installation.writeln("• 足够的通风和间隙");
        installation.writeln("• 接地和安全措施");
      }

      installation.writeln("");
      installation.writeln("⚠️ 始终咨询认证专业人士进行安装，以确保安全并符合当地法规。");
    } else {
      installation.writeln("🔧 Installation Information");
      installation.writeln("");

      if (message.contains('generator') || message.contains('genset')) {
        installation.writeln("Generator Installation:");
        installation.writeln("• Professional installation recommended");
        installation.writeln("• Requires proper foundation and ventilation");
        installation.writeln("• Electrical connections must comply with local regulations");
        installation.writeln("• Fuel line and exhaust system setup");
      }

      if (message.contains('ats')) {
        installation.writeln("\nATS Installation:");
        installation.writeln("• Connect between main power and generator");
        installation.writeln("• Requires licensed electrician");
        installation.writeln("• Proper wiring and configuration essential");
        installation.writeln("• Testing of automatic transfer function");
      }

      if (message.contains('avs')) {
        installation.writeln("\nAVS Installation:");
        installation.writeln("• Install in series with equipment to be protected");
        installation.writeln("• Proper input/output voltage matching");
        installation.writeln("• Adequate ventilation and clearance");
        installation.writeln("• Grounding and safety measures");
      }

      installation.writeln("");
      installation.writeln("⚠️ Always consult with certified professionals for installation to ensure safety and compliance with local regulations.");
    }

    return installation.toString();
  }

  static String _handleTroubleshootingQuery(String message, String language) {
    StringBuffer troubleshooting = StringBuffer();

    if (language == 'ms') {
      troubleshooting.writeln("🔧 PENYELESAIAN MASALAH - PANDUAN TEKNIKAL");
      troubleshooting.writeln("");
      troubleshooting.writeln("👨‍🔧 Sebagai juruteknik berpengalaman, saya akan bantu anda menyelesaikan masalah generator ini secara sistematik. Jangan risau, kebanyakan masalah boleh diselesaikan dengan langkah-langkah asas.");
      troubleshooting.writeln("");

      if (message.contains('start') || message.contains('won\'t start') || message.contains('engine')) {
        troubleshooting.writeln("🚫 GENERATOR TIDAK BOLEH HIDUP");
        troubleshooting.writeln("");
        troubleshooting.writeln("Ini masalah biasa yang saya jumpa setiap hari. Mari kita semak secara sistematik:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 SEMAKAN ASAS (Ambil masa 5 minit):");
        troubleshooting.writeln("1) 📊 Periksa paras bahan api - Pastikan tangki penuh dengan diesel berkualiti");
        troubleshooting.writeln("2) 🔋 Bateri - Pastikan dicas sepenuhnya (12.6V+) dan terminal tidak berkarat");
        troubleshooting.writeln("3) 🛑 Pemutus beban - Pastikan SEMUA suis dimatikan sebelum hidupkan");
        troubleshooting.writeln("4) 🚨 Panel kawalan - Lihat untuk kod ralat atau lampu amaran merah");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 LANGKAH TEKNIKAL LANJUT:");
        troubleshooting.writeln("• Bersihkan terminal bateri dengan berus dawai jika berkarat");
        troubleshooting.writeln("• Periksa wayar bateri untuk kerosakan atau sambungan longgar");
        troubleshooting.writeln("• Cuba hidupkan secara manual (bukan auto) untuk ujian");
        troubleshooting.writeln("• Dengar bunyi 'klik' dari starter - jika tiada, bateri lemah");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TIP JURUTEKNIK: Jika bateri baik tapi masih tidak hidup, mungkin masalah starter atau alternator. Jangan cuba buka enjin sendiri - hubungi servis rasmi.");
      } else if (message.contains('power') || message.contains('output') || message.contains('electricity')) {
        troubleshooting.writeln("⚡ TIADA OUTPUT KUASA");
        troubleshooting.writeln("");
        troubleshooting.writeln("Masalah output kuasa adalah kritikal. Mari kita semak dengan teliti:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 SEMAKAN ELEKTRIK (Ambil masa 10 minit):");
        troubleshooting.writeln("1) 🔌 Sambungan output - Pastikan semua plag dan soket kemas");
        troubleshooting.writeln("2) ⚡ Voltan output - Semak pada meter panel kawalan (harus 400V untuk 3 fasa)");
        troubleshooting.writeln("3) 🔄 ATS - Jika ada, pastikan suis pemindahan berfungsi dengan betul");
        troubleshooting.writeln("4) 🏗️ Beban - Pastikan tidak melebihi 80% kapasiti generator");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 DIAGNOSTIK LANJUT:");
        troubleshooting.writeln("• Uji setiap fasa satu persatu dengan multimeter");
        troubleshooting.writeln("• Semak AVR (Automatic Voltage Regulator) untuk kerosakan");
        troubleshooting.writeln("• Periksa stator dan rotor alternator untuk masalah mekanikal");
        troubleshooting.writeln("• Cuba sambung beban kecil (lampu) untuk ujian asas");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TIP JURUTEKNIK: Jika voltan tidak stabil, kemungkinan masalah AVR atau eksitasi. Ini memerlukan alat khas untuk baiki.");
      } else if (message.contains('noise') || message.contains('loud') || message.contains('sound')) {
        troubleshooting.writeln("🔊 GENERATOR TERLALU BISING");
        troubleshooting.writeln("");
        troubleshooting.writeln("Bunyi bising generator boleh jadi tanda masalah mekanikal. Mari kita semak:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 SEMAKAN MEKANIKAL (Ambil masa 15 minit):");
        troubleshooting.writeln("1) 🏗️ Asas pemasangan - Pastikan rata dan stabil, bukan condong");
        troubleshooting.writeln("2) 🔩 Bolt & nut - Semua harus ketat, terutama mounting enjin");
        troubleshooting.writeln("3) 🛡️ Kanopi - Periksa untuk retak atau panel longgar");
        troubleshooting.writeln("4) 🟫 Mounting pad - Getah penebat bunyi tidak pecah atau haus");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 PENYELESAIAN BUNYI:");
        troubleshooting.writeln("• Pasang pada concrete slab tebal minimum 150mm");
        troubleshooting.writeln("• Gunakan spring isolators untuk getaran");
        troubleshooting.writeln("• Tambah acoustic enclosure jika perlu");
        troubleshooting.writeln("• Jauhkan dari dinding untuk echo");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TIP JURUTEKNIK: Bunyi 'ketak ketak' bermakna bearing rosak. Bunyi 'peluit' bermakna tali kipas longgar. Dengar dengan teliti!");
      } else if (message.contains('fuel') || message.contains('consumption') || message.contains('leak')) {
        troubleshooting.writeln("⛽ MASALAH BAHAN API");
        troubleshooting.writeln("");
        troubleshooting.writeln("Masalah bahan api adalah punca utama kerosakan enjin. Mari kita semak:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 SEMAKAN BAHAN API (Ambil masa 10 minit):");
        troubleshooting.writeln("1) 💧 Paras air - Kosongkan air dari tangki bahan api");
        troubleshooting.writeln("2) 🔎 Penapis bahan api - Bersihkan atau ganti jika tersumbat");
        troubleshooting.writeln("3) ⛽ Kualiti diesel - Pastikan diesel segar, bukan basi");
        troubleshooting.writeln("4) 🔧 Sistem suntikan - Periksa untuk kebocoran atau penyumbatan");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 PENYELESAIAN TEKNIKAL:");
        troubleshooting.writeln("• Ganti penapis bahan api setiap 400 jam operasi");
        troubleshooting.writeln("• Gunakan bahan api dengan cetane number tinggi");
        troubleshooting.writeln("• Bersihkan tangki bahan api dari sedimen");
        troubleshooting.writeln("• Semak fuel pump untuk tekanan yang betul");
        troubleshooting.writeln("");
        troubleshooting.writeln("⚠️ AMARAN KESELAMATAN: JANGAN merokok atau gunakan api terbuka berhampiran bahan api. Risiko kebakaran tinggi!");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TIP JURUTEKNIK: Jika penggunaan bahan api tinggi tiba-tiba, mungkin masalah injector atau timing enjin. Perlu servis enjin profesional.");
      } else if (message.contains('maintenance') || message.contains('service') || message.contains('check')) {
        troubleshooting.writeln("🔧 PENYELENGGARAAN RUTIN GENERATOR");
        troubleshooting.writeln("");
        troubleshooting.writeln("Penyelenggaraan yang baik adalah kunci kepada hayat panjang generator. Sebagai juruteknik, saya cadangkan:");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 JADUAL PENYELENGGARAAN HARIAN:");
        troubleshooting.writeln("• Semak paras minyak enjin dan radiator");
        troubleshooting.writeln("• Periksa untuk kebocoran bahan api atau minyak");
        troubleshooting.writeln("• Dengar bunyi tidak normal semasa operasi");
        troubleshooting.writeln("• Semak voltan dan frekuensi output");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 PENYELENGGARAAN MINGGUAN:");
        troubleshooting.writeln("• Bersihkan penapis udara dari habuk");
        troubleshooting.writeln("• Semak paras air bateri");
        troubleshooting.writeln("• Periksa tali kipas untuk ketegangan");
        troubleshooting.writeln("• Bersihkan radiator dari serangga");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 PENYELENGGARAAN BULANAN:");
        troubleshooting.writeln("• Ganti minyak enjin (setiap 50 jam)");
        troubleshooting.writeln("• Bersihkan sistem penyejukan");
        troubleshooting.writeln("• Semak sambungan elektrik");
        troubleshooting.writeln("• Uji fungsi auto-start jika ada");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TIP JURUTEKNIK: Saya cadangkan servis profesional setiap 6 bulan atau 500 jam operasi. Lebih murah baiki daripada ganti enjin baru!");
      } else {
        troubleshooting.writeln("🔧 MASALAH GENERATOR UMUM");
        troubleshooting.writeln("");
        troubleshooting.writeln("Berdasarkan pengalaman saya sebagai juruteknik, berikut adalah masalah paling biasa:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 SEMAKAN ASAS YANG SERING TERLEPAS PANDANG:");
        troubleshooting.writeln("1) 🔋 Bateri - Punca utama masalah 'tidak hidup'");
        troubleshooting.writeln("2) ⛽ Bahan api - Pastikan bersih dan berkualiti");
        troubleshooting.writeln("3) 🔌 Sambungan - Semua wayar dan plag harus kemas");
        troubleshooting.writeln("4) 🏗️ Beban - Jangan overload generator");
        troubleshooting.writeln("5) 🌡️ Suhu - Pastikan sistem penyejukan berfungsi");
        troubleshooting.writeln("6) 🔊 Bunyi - Dengar untuk masalah mekanikal");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 ALAT YANG ANDA PERLU:");
        troubleshooting.writeln("• Multimeter digital untuk ujian elektrik");
        troubleshooting.writeln("• Pressure gauge untuk sistem bahan api");
        troubleshooting.writeln("• Tachometer untuk semak RPM enjin");
        troubleshooting.writeln("• Test lamp untuk ujian litar");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TIP JURUTEKNIK: 80% masalah generator boleh diselesaikan dengan semakan asas. Jika masih tidak berfungsi, masa untuk hubungi servis profesional.");
      }

      troubleshooting.writeln("");
      troubleshooting.writeln("🤝 Saya faham ini menjengkelkan, tapi jangan risau. Jika masalah masih berterusan, saya cadangkan:");
      troubleshooting.writeln("📞 Hubungi teknikal kami: +60 12-968 9816");
      troubleshooting.writeln("📧 Email: technical@genset.com.my");
      troubleshooting.writeln("🏢 Servis di lokasi anda tersedia");
      troubleshooting.writeln("");
      troubleshooting.writeln("⚡ Kami ada stok spare parts lengkap dan juruteknik bertauliah. Boleh selesai dalam sehari untuk masalah biasa!");

    } else if (language == 'zh') {
      troubleshooting.writeln("🔧 故障排除 - 技术指导");
      troubleshooting.writeln("");
      troubleshooting.writeln("👨‍🔧 作为经验丰富的技师，我会系统性地帮您解决发电机问题。别担心，大多数问题都可以通过基本步骤解决。");
      troubleshooting.writeln("");

      if (message.contains('start') || message.contains('won\'t start') || message.contains('engine')) {
        troubleshooting.writeln("🚫 发电机无法启动");
        troubleshooting.writeln("");
        troubleshooting.writeln("这是我每天都会遇到的常见问题。让我们系统地检查：");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 基本检查（需要5分钟）：");
        troubleshooting.writeln("1) 📊 燃油液位 - 确保油箱充满优质柴油");
        troubleshooting.writeln("2) 🔋 电池 - 确保完全充电（12.6V+）且端子无腐蚀");
        troubleshooting.writeln("3) 🛑 负载断路器 - 启动前确保所有开关都关闭");
        troubleshooting.writeln("4) 🚨 控制面板 - 查看是否有错误代码或红色警告灯");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 高级技术步骤：");
        troubleshooting.writeln("• 如果端子腐蚀，用钢丝刷清洁电池端子");
        troubleshooting.writeln("• 检查电池线缆是否有损坏或松动连接");
        troubleshooting.writeln("• 尝试手动启动（非自动）进行测试");
        troubleshooting.writeln("• 倾听启动器的'咔嗒'声 - 如果没有，电池电量不足");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 技师提示：如果电池良好但仍无法启动，可能是启动器或交流发电机问题。不要自己打开发动机 - 联系官方服务。");
      } else if (message.contains('power') || message.contains('output') || message.contains('electricity')) {
        troubleshooting.writeln("⚡ 无电力输出");
        troubleshooting.writeln("");
        troubleshooting.writeln("电力输出问题是关键问题。让我们仔细检查：");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 电气检查（需要10分钟）：");
        troubleshooting.writeln("1) 🔌 输出连接 - 确保所有插头和插座牢固");
        troubleshooting.writeln("2) ⚡ 输出电压 - 在控制面板上用仪表检查（3相应为400V）");
        troubleshooting.writeln("3) 🔄 ATS - 如果有，确保转换开关正常工作");
        troubleshooting.writeln("4) 🏗️ 负载 - 确保不超过发电机容量的80%");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 高级诊断：");
        troubleshooting.writeln("• 用万用表逐一测试每个相位");
        troubleshooting.writeln("• 检查AVR（自动电压调节器）是否有损坏");
        troubleshooting.writeln("• 检查定子和转子是否有机械问题");
        troubleshooting.writeln("• 尝试连接小负载（灯泡）进行基本测试");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 技师提示：如果电压不稳定，可能是AVR或励磁问题。这需要专用工具来修复。");
      } else if (message.contains('noise') || message.contains('loud') || message.contains('sound')) {
        troubleshooting.writeln("🔊 发电机噪音过大");
        troubleshooting.writeln("");
        troubleshooting.writeln("发电机噪音大可能是机械问题的迹象。让我们检查：");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 机械检查（需要15分钟）：");
        troubleshooting.writeln("1) 🏗️ 安装基础 - 确保平坦稳定，不要倾斜");
        troubleshooting.writeln("2) 🔩 螺栓和螺母 - 所有都应紧固，特别是发动机安装");
        troubleshooting.writeln("3) 🛡️ 外罩 - 检查是否有裂缝或松动的面板");
        troubleshooting.writeln("4) 🟫 安装垫 - 橡胶隔音垫没有破损或磨损");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 噪音解决方案：");
        troubleshooting.writeln("• 安装在至少150mm厚的混凝土板上");
        troubleshooting.writeln("• 使用弹簧隔振器减少振动");
        troubleshooting.writeln("• 如需要，添加声学外罩");
        troubleshooting.writeln("• 远离墙壁以减少回声");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 技师提示：'咔哒咔哒'声表示轴承损坏。'哨声'表示风扇皮带松弛。仔细倾听！");
      } else if (message.contains('fuel') || message.contains('consumption') || message.contains('leak')) {
        troubleshooting.writeln("⛽ 燃油问题");
        troubleshooting.writeln("");
        troubleshooting.writeln("燃油问题是发动机损坏的主要原因。让我们检查：");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 燃油检查（需要10分钟）：");
        troubleshooting.writeln("1) 💧 水位 - 从燃油箱中排出水");
        troubleshooting.writeln("2) 🔎 燃油滤清器 - 如果堵塞，清洁或更换");
        troubleshooting.writeln("3) ⛽ 柴油质量 - 确保柴油新鲜，不是变质的");
        troubleshooting.writeln("4) 🔧 喷射系统 - 检查是否有泄漏或堵塞");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 技术解决方案：");
        troubleshooting.writeln("• 每400小时运行更换燃油滤清器");
        troubleshooting.writeln("• 使用高十六烷值燃油");
        troubleshooting.writeln("• 从燃油箱中清除沉淀物");
        troubleshooting.writeln("• 检查燃油泵压力是否正确");
        troubleshooting.writeln("");
        troubleshooting.writeln("⚠️ 安全警告：不要在燃油附近吸烟或使用明火。火灾风险很高！");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 技师提示：如果燃油消耗突然增加，可能是喷油器或发动机正时问题。需要专业发动机服务。");
      } else if (message.contains('maintenance') || message.contains('service') || message.contains('check')) {
        troubleshooting.writeln("🔧 发电机日常维护");
        troubleshooting.writeln("");
        troubleshooting.writeln("良好的维护是延长发电机寿命的关键。作为技师，我建议：");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 日常维护：");
        troubleshooting.writeln("• 检查发动机油位和散热器液位");
        troubleshooting.writeln("• 检查燃油或机油泄漏");
        troubleshooting.writeln("• 倾听运行时的异常声音");
        troubleshooting.writeln("• 检查输出电压和频率");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 每周维护：");
        troubleshooting.writeln("• 从空气滤清器清除灰尘");
        troubleshooting.writeln("• 检查电池液位");
        troubleshooting.writeln("• 检查风扇皮带张力");
        troubleshooting.writeln("• 从散热器清除昆虫");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 每月维护：");
        troubleshooting.writeln("• 更换发动机油（每50小时）");
        troubleshooting.writeln("• 清洁冷却系统");
        troubleshooting.writeln("• 检查电气连接");
        troubleshooting.writeln("• 如果有，测试自动启动功能");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 技师提示：我建议每6个月或500小时运行进行专业服务。维修比更换新发动机更便宜！");
      } else {
        troubleshooting.writeln("🔧 一般发电机问题");
        troubleshooting.writeln("");
        troubleshooting.writeln("根据我作为技师的经验，以下是最常见的问题：");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 经常被忽视的基本检查：");
        troubleshooting.writeln("1) 🔋 电池 - '无法启动'问题的首要原因");
        troubleshooting.writeln("2) ⛽ 燃油 - 确保清洁和优质");
        troubleshooting.writeln("3) 🔌 连接 - 所有电线和插头应牢固");
        troubleshooting.writeln("4) 🏗️ 负载 - 不要超载发电机");
        troubleshooting.writeln("5) 🌡️ 温度 - 确保冷却系统正常工作");
        troubleshooting.writeln("6) 🔊 声音 - 倾听机械问题");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 您需要的工具：");
        troubleshooting.writeln("• 数字万用表用于电气测试");
        troubleshooting.writeln("• 压力表用于燃油系统");
        troubleshooting.writeln("• 转速表用于检查发动机RPM");
        troubleshooting.writeln("• 测试灯用于电路测试");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 技师提示：80%的发电机问题可以通过基本检查解决。如果仍有问题，该联系专业服务了。");
      }

      troubleshooting.writeln("");
      troubleshooting.writeln("🤝 我理解这很令人沮丧，但别担心。如果问题仍然存在，我建议：");
      troubleshooting.writeln("📞 联系我们的技术人员：+60 12-968 9816");
      troubleshooting.writeln("📧 邮箱：technical@genset.com.my");
      troubleshooting.writeln("🏢 可提供上门服务");
      troubleshooting.writeln("");
      troubleshooting.writeln("⚡ 我们有完整的备件库存和认证技师。对于常见问题，可在一天内完成！");

    } else {
      troubleshooting.writeln("🔧 TROUBLESHOOTING GUIDE - TECHNICAL ASSISTANCE");
      troubleshooting.writeln("");
      troubleshooting.writeln("👨‍🔧 As an experienced technician, I'll help you systematically resolve this generator issue. Don't worry, most problems can be solved with basic steps.");
      troubleshooting.writeln("");

      if (message.contains('start') || message.contains('won\'t start') || message.contains('engine')) {
        troubleshooting.writeln("🚫 GENERATOR WON'T START");
        troubleshooting.writeln("");
        troubleshooting.writeln("This is a common problem I encounter every day. Let's check systematically:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 BASIC CHECKS (Takes 5 minutes):");
        troubleshooting.writeln("1) 📊 Fuel level - Ensure tank is full with quality diesel");
        troubleshooting.writeln("2) 🔋 Battery - Ensure fully charged (12.6V+) and terminals corrosion-free");
        troubleshooting.writeln("3) 🛑 Load breakers - Ensure ALL switches are OFF before starting");
        troubleshooting.writeln("4) 🚨 Control panel - Look for error codes or red warning lights");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 ADVANCED TECHNICAL STEPS:");
        troubleshooting.writeln("• Clean battery terminals with wire brush if corroded");
        troubleshooting.writeln("• Check battery cables for damage or loose connections");
        troubleshooting.writeln("• Try manual start (not auto) for testing");
        troubleshooting.writeln("• Listen for 'click' from starter - if none, battery is weak");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TECHNICIAN TIP: If battery is good but still won't start, likely starter or alternator issue. Don't try to open engine yourself - contact authorized service.");
      } else if (message.contains('power') || message.contains('output') || message.contains('electricity')) {
        troubleshooting.writeln("⚡ NO POWER OUTPUT");
        troubleshooting.writeln("");
        troubleshooting.writeln("Power output issues are critical. Let's check carefully:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 ELECTRICAL CHECKS (Takes 10 minutes):");
        troubleshooting.writeln("1) 🔌 Output connections - Ensure all plugs and sockets are secure");
        troubleshooting.writeln("2) ⚡ Output voltage - Check on control panel meter (should be 400V for 3-phase)");
        troubleshooting.writeln("3) 🔄 ATS - If present, ensure transfer switch functions properly");
        troubleshooting.writeln("4) 🏗️ Load - Ensure doesn't exceed 80% of generator capacity");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 ADVANCED DIAGNOSTICS:");
        troubleshooting.writeln("• Test each phase individually with multimeter");
        troubleshooting.writeln("• Check AVR (Automatic Voltage Regulator) for damage");
        troubleshooting.writeln("• Inspect stator and rotor for mechanical issues");
        troubleshooting.writeln("• Try connecting small load (light bulb) for basic test");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TECHNICIAN TIP: If voltage is unstable, likely AVR or excitation problem. Requires special tools to fix.");
      } else if (message.contains('noise') || message.contains('loud') || message.contains('sound')) {
        troubleshooting.writeln("🔊 GENERATOR TOO NOISY");
        troubleshooting.writeln("");
        troubleshooting.writeln("Excessive generator noise can indicate mechanical problems. Let's check:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 MECHANICAL CHECKS (Takes 15 minutes):");
        troubleshooting.writeln("1) 🏗️ Installation base - Ensure level and stable, not tilted");
        troubleshooting.writeln("2) 🔩 Bolts & nuts - All should be tight, especially engine mounts");
        troubleshooting.writeln("3) 🛡️ Canopy - Check for cracks or loose panels");
        troubleshooting.writeln("4) 🟫 Mounting pads - Rubber sound insulation not cracked or worn");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 NOISE SOLUTIONS:");
        troubleshooting.writeln("• Install on thick concrete slab minimum 150mm");
        troubleshooting.writeln("• Use spring isolators for vibration");
        troubleshooting.writeln("• Add acoustic enclosure if needed");
        troubleshooting.writeln("• Keep away from walls to reduce echo");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TECHNICIAN TIP: 'Rattling' sound means bearings damaged. 'Whistling' sound means fan belt loose. Listen carefully!");
      } else if (message.contains('fuel') || message.contains('consumption') || message.contains('leak')) {
        troubleshooting.writeln("⛽ FUEL SYSTEM ISSUES");
        troubleshooting.writeln("");
        troubleshooting.writeln("Fuel problems are the leading cause of engine damage. Let's check:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 FUEL CHECKS (Takes 10 minutes):");
        troubleshooting.writeln("1) 💧 Water level - Drain water from fuel tank");
        troubleshooting.writeln("2) 🔎 Fuel filter - Clean or replace if clogged");
        troubleshooting.writeln("3) ⛽ Diesel quality - Ensure fresh diesel, not degraded");
        troubleshooting.writeln("4) 🔧 Injection system - Check for leaks or blockages");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 TECHNICAL SOLUTIONS:");
        troubleshooting.writeln("• Replace fuel filter every 400 operating hours");
        troubleshooting.writeln("• Use fuel with high cetane number");
        troubleshooting.writeln("• Clean fuel tank from sediment");
        troubleshooting.writeln("• Check fuel pump for correct pressure");
        troubleshooting.writeln("");
        troubleshooting.writeln("⚠️ SAFETY WARNING: DO NOT smoke or use open flames near fuel. High fire risk!");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TECHNICIAN TIP: If fuel consumption suddenly increases, likely injector or engine timing issue. Requires professional engine service.");
      } else if (message.contains('maintenance') || message.contains('service') || message.contains('check')) {
        troubleshooting.writeln("🔧 GENERATOR ROUTINE MAINTENANCE");
        troubleshooting.writeln("");
        troubleshooting.writeln("Good maintenance is key to long generator life. As a technician, I recommend:");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 DAILY MAINTENANCE:");
        troubleshooting.writeln("• Check engine oil and radiator levels");
        troubleshooting.writeln("• Look for fuel or oil leaks");
        troubleshooting.writeln("• Listen for abnormal sounds during operation");
        troubleshooting.writeln("• Check output voltage and frequency");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 WEEKLY MAINTENANCE:");
        troubleshooting.writeln("• Clean air filter from dust");
        troubleshooting.writeln("• Check battery water levels");
        troubleshooting.writeln("• Inspect fan belt tension");
        troubleshooting.writeln("• Clean radiator from insects");
        troubleshooting.writeln("");
        troubleshooting.writeln("📅 MONTHLY MAINTENANCE:");
        troubleshooting.writeln("• Change engine oil (every 50 hours)");
        troubleshooting.writeln("• Clean cooling system");
        troubleshooting.writeln("• Check electrical connections");
        troubleshooting.writeln("• Test auto-start function if present");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TECHNICIAN TIP: I recommend professional service every 6 months or 500 operating hours. Much cheaper to fix than replace a new engine!");
      } else {
        troubleshooting.writeln("🔧 GENERAL GENERATOR PROBLEMS");
        troubleshooting.writeln("");
        troubleshooting.writeln("Based on my experience as a technician, here are the most common issues:");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔍 BASIC CHECKS OFTEN OVERLOOKED:");
        troubleshooting.writeln("1) 🔋 Battery - Primary cause of 'won't start' problems");
        troubleshooting.writeln("2) ⛽ Fuel - Ensure clean and quality fuel");
        troubleshooting.writeln("3) 🔌 Connections - All wires and plugs should be secure");
        troubleshooting.writeln("4) 🏗️ Load - Don't overload the generator");
        troubleshooting.writeln("5) 🌡️ Temperature - Ensure cooling system works");
        troubleshooting.writeln("6) 🔊 Sound - Listen for mechanical problems");
        troubleshooting.writeln("");
        troubleshooting.writeln("🔧 TOOLS YOU NEED:");
        troubleshooting.writeln("• Digital multimeter for electrical testing");
        troubleshooting.writeln("• Pressure gauge for fuel system");
        troubleshooting.writeln("• Tachometer to check engine RPM");
        troubleshooting.writeln("• Test lamp for circuit testing");
        troubleshooting.writeln("");
        troubleshooting.writeln("💡 TECHNICIAN TIP: 80% of generator problems can be solved with basic checks. If still not working, time to call professional service.");
      }

      troubleshooting.writeln("");
      troubleshooting.writeln("🤝 I understand this is frustrating, but don't worry. If the problem persists, I recommend:");
      troubleshooting.writeln("📞 Contact our technical team: +60 12-968 9816");
      troubleshooting.writeln("📧 Email: technical@genset.com.my");
      troubleshooting.writeln("🏢 On-site service available");
      troubleshooting.writeln("");
      troubleshooting.writeln("⚡ We have complete spare parts stock and certified technicians. Can complete common problems within one day!");
    }

    return troubleshooting.toString();
  }

  static String _handleContactQuery(String message, String language) {
    Map<String, dynamic> companyInfo = _knowledgeBase!['contact_info']['company'];
    String phone = companyInfo['phone'];
    String email = companyInfo['email'];

    if (message.contains('boss') || message.contains('manager') || message.contains('owner') ||
        message.contains('peter') || message.contains('discount') || message.contains('special price')) {
      Map<String, dynamic> peterInfo = _knowledgeBase!['contact_info']['peter'];
      String peterName = peterInfo['name'];
      String peterPhone = peterInfo['phone'];
      String peterEmail = peterInfo['email'];

      return _getLocalizedResponse("📞 For inquiries about discounts, special pricing, or to speak with management, please contact $peterName directly:\n📞 Phone: $peterPhone\n📧 Email: $peterEmail", language);
    }

    return _getLocalizedResponse("📞 For general inquiries and support, please contact our company:\n📞 Phone: $phone\n📧 Email: $email\n\nOur team is ready to assist you with any questions about our MGM generator products and services.", language);
  }

  static String _getContextualFallback(String message, String language) {
    // Analyze message for better fallback response
    if (message.contains('price') || message.contains('cost')) {
      return _getLocalizedResponse("I understand you're interested in pricing. Our products are competitively priced, and I can help you understand the value proposition. Would you like me to explain the features and benefits first, or would you prefer to contact our sales team for a quotation?", language);
    }

    if (message.contains('when') || message.contains('delivery') || message.contains('available')) {
      return _getLocalizedResponse("For delivery times and availability, I recommend contacting our sales team who can check current stock levels and provide accurate delivery estimates based on your location and requirements.", language);
    }

    if (message.contains('warranty') || message.contains('guarantee')) {
      return _getLocalizedResponse("Our products come with comprehensive warranties. Generator warranties typically range from 1-2 years depending on the model, with extended warranty options available. Would you like details for a specific product?", language);
    }

    // Enhanced fallback with actual product information
    StringBuffer fallbackResponse = StringBuffer();

    if (language == 'ms') {
      fallbackResponse.writeln("🤖 Saya adalah Pembantu Genset MGM anda!");
      fallbackResponse.writeln("");
      fallbackResponse.writeln("Saya boleh membantu anda dengan maklumat terperinci tentang produk kami:");
      fallbackResponse.writeln("");

      // Show available generator models with key specs
      List<dynamic> generators = _knowledgeBase!['generators'];
      fallbackResponse.writeln("⚡ GENERATOR DIESEL MGM:");
      for (var generator in generators.take(4)) { // Show first 4 models
        fallbackResponse.writeln("• ${generator['name']} - ${generator['power']}");
        fallbackResponse.writeln("  Model: ${generator['model']}");
        if (generator['specifications']['fuel_consumption'] != null) {
          fallbackResponse.writeln("  Penggunaan Bahan Api: ${generator['specifications']['fuel_consumption']}");
        }
        if (generator['specifications']['dimensions'] != null) {
          fallbackResponse.writeln("  Dimensi: ${generator['specifications']['dimensions']}");
        }
        fallbackResponse.writeln("");
      }

      // Show power bank info
      List<dynamic> powerBanks = _knowledgeBase!['power_banks'];
      if (powerBanks.isNotEmpty) {
        fallbackResponse.writeln("🔋 SISTEM POWER BANK:");
        for (var powerBank in powerBanks) {
          fallbackResponse.writeln("• ${powerBank['name']}");
          fallbackResponse.writeln("  Model: ${powerBank['model']}");
          fallbackResponse.writeln("  Kapasiti Bateri: ${powerBank['battery_specifications']['rated_energy']}");
          fallbackResponse.writeln("");
        }
      }

      // Show ATS info
      List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];
      if (atsSystems.isNotEmpty) {
        var atsSystem = atsSystems.first;
        fallbackResponse.writeln("🔄 AUTOMATIC TRANSFER SWITCH (ATS):");
        fallbackResponse.writeln("• ${atsSystem['name']}");
        fallbackResponse.writeln("  ${atsSystem['description']}");
        fallbackResponse.writeln("");
      }

      fallbackResponse.writeln("💬 Tanya saya tentang:");
      fallbackResponse.writeln("• 'Tunjukkan spesifikasi 30kVA'");
      fallbackResponse.writeln("• 'Bandingkan 15kVA vs 30kVA'");
      fallbackResponse.writeln("• 'Power bank 20kWh'");
      fallbackResponse.writeln("• 'ATS untuk generator'");
      fallbackResponse.writeln("");
      fallbackResponse.writeln("Apa yang anda ingin tahu tentang produk kami?");

    } else if (language == 'zh') {
      fallbackResponse.writeln("🤖 我是您的MGM发电机助手！");
      fallbackResponse.writeln("");
      fallbackResponse.writeln("我可以帮助您了解我们产品的详细信息：");
      fallbackResponse.writeln("");

      // Show available generator models with key specs
      List<dynamic> generators = _knowledgeBase!['generators'];
      fallbackResponse.writeln("⚡ MGM柴油发电机：");
      for (var generator in generators.take(4)) { // Show first 4 models
        fallbackResponse.writeln("• ${generator['name']} - ${generator['power']}");
        fallbackResponse.writeln("  型号: ${generator['model']}");
        if (generator['specifications']['fuel_consumption'] != null) {
          fallbackResponse.writeln("  燃油消耗: ${generator['specifications']['fuel_consumption']}");
        }
        if (generator['specifications']['dimensions'] != null) {
          fallbackResponse.writeln("  尺寸: ${generator['specifications']['dimensions']}");
        }
        fallbackResponse.writeln("");
      }

      // Show power bank info
      List<dynamic> powerBanks = _knowledgeBase!['power_banks'];
      if (powerBanks.isNotEmpty) {
        fallbackResponse.writeln("🔋 电源银行系统：");
        for (var powerBank in powerBanks) {
          fallbackResponse.writeln("• ${powerBank['name']}");
          fallbackResponse.writeln("  型号: ${powerBank['model']}");
          fallbackResponse.writeln("  电池容量: ${powerBank['battery_specifications']['rated_energy']}");
          fallbackResponse.writeln("");
        }
      }

      // Show ATS info
      List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];
      if (atsSystems.isNotEmpty) {
        var atsSystem = atsSystems.first;
        fallbackResponse.writeln("🔄 自动转换开关（ATS）：");
        fallbackResponse.writeln("• ${atsSystem['name']}");
        fallbackResponse.writeln("  ${atsSystem['description']}");
        fallbackResponse.writeln("");
      }

      fallbackResponse.writeln("💬 询问我：");
      fallbackResponse.writeln("• '显示30kVA规格'");
      fallbackResponse.writeln("• '比较15kVA vs 30kVA'");
      fallbackResponse.writeln("• '20kWh电源银行'");
      fallbackResponse.writeln("• '发电机ATS'");
      fallbackResponse.writeln("");
      fallbackResponse.writeln("您想了解我们产品的什么信息？");

    } else {
      fallbackResponse.writeln("🤖 I'm your MGM Generator Assistant!");
      fallbackResponse.writeln("");
      fallbackResponse.writeln("I can help you with detailed information about our products:");
      fallbackResponse.writeln("");

      // Show available generator models with key specs
      List<dynamic> generators = _knowledgeBase!['generators'];
      fallbackResponse.writeln("⚡ MGM DIESEL GENERATORS:");
      for (var generator in generators.take(4)) { // Show first 4 models
        fallbackResponse.writeln("• ${generator['name']} - ${generator['power']}");
        fallbackResponse.writeln("  Model: ${generator['model']}");
        if (generator['specifications']['fuel_consumption'] != null) {
          fallbackResponse.writeln("  Fuel Consumption: ${generator['specifications']['fuel_consumption']}");
        }
        if (generator['specifications']['dimensions'] != null) {
          fallbackResponse.writeln("  Dimensions: ${generator['specifications']['dimensions']}");
        }
        fallbackResponse.writeln("");
      }

      // Show power bank info
      List<dynamic> powerBanks = _knowledgeBase!['power_banks'];
      if (powerBanks.isNotEmpty) {
        fallbackResponse.writeln("🔋 POWER BANK SYSTEMS:");
        for (var powerBank in powerBanks) {
          fallbackResponse.writeln("• ${powerBank['name']}");
          fallbackResponse.writeln("  Model: ${powerBank['model']}");
          fallbackResponse.writeln("  Battery Capacity: ${powerBank['battery_specifications']['rated_energy']}");
          fallbackResponse.writeln("");
        }
      }

      // Show ATS info
      List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];
      if (atsSystems.isNotEmpty) {
        var atsSystem = atsSystems.first;
        fallbackResponse.writeln("🔄 AUTOMATIC TRANSFER SWITCH (ATS):");
        fallbackResponse.writeln("• ${atsSystem['name']}");
        fallbackResponse.writeln("  ${atsSystem['description']}");
        fallbackResponse.writeln("");
      }

      fallbackResponse.writeln("💬 Ask me about:");
      fallbackResponse.writeln("• 'Show me 30kVA specifications'");
      fallbackResponse.writeln("• 'Compare 15kVA vs 30kVA'");
      fallbackResponse.writeln("• '20kWh power bank'");
      fallbackResponse.writeln("• 'ATS for generator'");
      fallbackResponse.writeln("");
      fallbackResponse.writeln("What would you like to know about our products?");
    }

    return fallbackResponse.toString();
  }

  static void _saveToHistory(String userMessage, String response) {
    try {
      // Keep only last 50 conversations
      if (_conversationHistory.length >= 50) {
        _conversationHistory.removeAt(0);
      }

      ConversationContext context = ConversationContext(
        messages: [userMessage, response],
        contextData: _currentContext?.contextData ?? {},
        timestamp: DateTime.now(),
      );

      _conversationHistory.add(context);
      _saveConversationHistory();
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  static String _findProductInfo(String message, String language) {
    List<dynamic> generators = _knowledgeBase!['generators'];
    List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];

    // Search in generators
    for (var generator in generators) {
      if (message.contains(generator['power'].toLowerCase()) ||
          message.contains(generator['name'].toLowerCase()) ||
          message.contains(generator['brand'].toLowerCase()) ||
          message.contains(generator['model'].toLowerCase())) {
        return _formatGensetInfo(generator, language);
      }
    }

    // Search in ATS systems
    for (var atsSystem in atsSystems) {
      if (message.contains('ats') ||
          message.contains('automatic transfer') ||
          message.contains('transfer switch') ||
          message.contains(atsSystem['name'].toLowerCase())) {
        return _formatATSInfo(atsSystem, language);
      }
    }

    return _getLocalizedResponse(_knowledgeBase!['responses']['ask_model'], language);
  }

  static String _findAVSInfo(String message, String language) {
    List<dynamic> avsSystems = _knowledgeBase!['avs_systems'];

    // Search in AVS systems
    for (var avsSystem in avsSystems) {
      if (message.contains('avs') ||
          message.contains('voltage stabilizer') ||
          message.contains('automatic voltage') ||
          message.contains(avsSystem['name'].toLowerCase())) {
        return _formatAVSInfo(avsSystem, message, language);
      }
    }

    return _getLocalizedResponse("I have information about Automatic Voltage Stabilizers (AVS). Please ask about specific models like VST3-4, VST10-4, or general AVS specifications.", language);
  }

  static String _findApplicationInfo(String message, String language) {
    List<dynamic> generators = _knowledgeBase!['generators'];

    for (var generator in generators) {
      if (message.contains(generator['power'].toLowerCase()) ||
          message.contains(generator['name'].toLowerCase())) {
        List<String> applications = List<String>.from(generator['applications']);
        return "${generator['name']} is suitable for:\n${applications.map((app) => '• $app').join('\n')}";
      }
    }

    return _getLocalizedResponse(_knowledgeBase!['responses']['ask_application'], language);
  }

  static String _findFeaturesInfo(String message, String language) {
    List<dynamic> generators = _knowledgeBase!['generators'];

    for (var generator in generators) {
      if (message.contains(generator['power'].toLowerCase()) ||
          message.contains(generator['name'].toLowerCase())) {
        List<String> features = List<String>.from(generator['features']);
        return "${generator['name']} features:\n${features.map((feature) => '• $feature').join('\n')}";
      }
    }

    return _getLocalizedResponse("Please specify which product you'd like to know about.", language);
  }

  static String _formatGensetInfo(Map<String, dynamic> genset, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("📋 ${genset['name']}");
      info.writeln("Model: ${genset['model']}");
      info.writeln("Kuasa: ${genset['power']}");
      info.writeln("Jenama: ${genset['brand']}");
      info.writeln("");

      Map<String, dynamic> specs = genset['specifications'];
      info.writeln("📊 Spesifikasi:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
    } else if (language == 'zh') {
      info.writeln("📋 ${genset['name']}");
      info.writeln("型号: ${genset['model']}");
      info.writeln("功率: ${genset['power']}");
      info.writeln("品牌: ${genset['brand']}");
      info.writeln("");

      Map<String, dynamic> specs = genset['specifications'];
      info.writeln("📊 规格:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
    } else {
      info.writeln("📋 ${genset['name']}");
      info.writeln("Model: ${genset['model']}");
      info.writeln("Power: ${genset['power']}");
      info.writeln("Brand: ${genset['brand']}");
      info.writeln("");

      Map<String, dynamic> specs = genset['specifications'];
      info.writeln("📊 Specifications:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
    }

    return info.toString();
  }

  static String _formatPowerBankInfo(Map<String, dynamic> powerBank, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("🔋 ${powerBank['name']}");
      info.writeln("Model: ${powerBank['model']}");
      info.writeln("Kuasa: ${powerBank['power']}");
      info.writeln("");

      Map<String, dynamic> specs = powerBank['specifications'];
      info.writeln("📊 Spesifikasi:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
    } else if (language == 'zh') {
      info.writeln("🔋 ${powerBank['name']}");
      info.writeln("型号: ${powerBank['model']}");
      info.writeln("功率: ${powerBank['power']}");
      info.writeln("");

      Map<String, dynamic> specs = powerBank['specifications'];
      info.writeln("📊 规格:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
    } else {
      info.writeln("🔋 ${powerBank['name']}");
      info.writeln("Model: ${powerBank['model']}");
      info.writeln("Power: ${powerBank['power']}");
      info.writeln("");

      Map<String, dynamic> specs = powerBank['specifications'];
      info.writeln("📊 Specifications:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });
    }

    return info.toString();
  }

  static String _formatZone2Info(Map<String, dynamic> zone2Genset, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("⚠️ ${zone2Genset['name']}");
      info.writeln("Kuasa: ${zone2Genset['power']}");
      info.writeln("Pensijilan: ${zone2Genset['specifications']['certification']}");
      info.writeln("");

      info.writeln("🛡️ Ciri Perlindungan:");
      List<String> protectionFeatures = List<String>.from(zone2Genset['specifications']['protection_features']);
      for (var feature in protectionFeatures) {
        info.writeln("• $feature");
      }

      info.writeln("");
      info.writeln("🚨 Penutupan Keselamatan:");
      List<String> safetyShutdowns = List<String>.from(zone2Genset['specifications']['safety_shutdowns']);
      for (var shutdown in safetyShutdowns) {
        info.writeln("• $shutdown");
      }
    } else if (language == 'zh') {
      info.writeln("⚠️ ${zone2Genset['name']}");
      info.writeln("功率: ${zone2Genset['power']}");
      info.writeln("认证: ${zone2Genset['specifications']['certification']}");
      info.writeln("");

      info.writeln("🛡️ 保护功能:");
      List<String> protectionFeatures = List<String>.from(zone2Genset['specifications']['protection_features']);
      for (var feature in protectionFeatures) {
        info.writeln("• $feature");
      }

      info.writeln("");
      info.writeln("🚨 安全关停:");
      List<String> safetyShutdowns = List<String>.from(zone2Genset['specifications']['safety_shutdowns']);
      for (var shutdown in safetyShutdowns) {
        info.writeln("• $shutdown");
      }
    } else {
      info.writeln("⚠️ ${zone2Genset['name']}");
      info.writeln("Power: ${zone2Genset['power']}");
      info.writeln("Certification: ${zone2Genset['specifications']['certification']}");
      info.writeln("");

      info.writeln("🛡️ Protection Features:");
      List<String> protectionFeatures = List<String>.from(zone2Genset['specifications']['protection_features']);
      for (var feature in protectionFeatures) {
        info.writeln("• $feature");
      }

      info.writeln("");
      info.writeln("🚨 Safety Shutdowns:");
      List<String> safetyShutdowns = List<String>.from(zone2Genset['specifications']['safety_shutdowns']);
      for (var shutdown in safetyShutdowns) {
        info.writeln("• $shutdown");
      }
    }

    return info.toString();
  }

  static String _formatATSInfo(Map<String, dynamic> atsSystem, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("🔄 ${atsSystem['name']}");
      info.writeln("Jenama: ${atsSystem['brand']}");
      info.writeln("Kategori: ${atsSystem['category']}");
      info.writeln("");

      info.writeln("📋 Penerangan:");
      info.writeln(atsSystem['description']);
      info.writeln("");

      Map<String, dynamic> specs = atsSystem['specifications'];
      info.writeln("⚙️ Spesifikasi:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });

      info.writeln("");
      info.writeln("✨ Ciri Utama:");
      List<String> features = List<String>.from(atsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
    } else if (language == 'zh') {
      info.writeln("🔄 ${atsSystem['name']}");
      info.writeln("品牌: ${atsSystem['brand']}");
      info.writeln("类别: ${atsSystem['category']}");
      info.writeln("");

      info.writeln("📋 描述:");
      info.writeln(atsSystem['description']);
      info.writeln("");

      Map<String, dynamic> specs = atsSystem['specifications'];
      info.writeln("⚙️ 规格:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });

      info.writeln("");
      info.writeln("✨ 主要功能:");
      List<String> features = List<String>.from(atsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
    } else {
      info.writeln("🔄 ${atsSystem['name']}");
      info.writeln("Brand: ${atsSystem['brand']}");
      info.writeln("Category: ${atsSystem['category']}");
      info.writeln("");

      info.writeln("📋 Description:");
      info.writeln(atsSystem['description']);
      info.writeln("");

      Map<String, dynamic> specs = atsSystem['specifications'];
      info.writeln("⚙️ Specifications:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });

      info.writeln("");
      info.writeln("✨ Key Features:");
      List<String> features = List<String>.from(atsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
    }

    return info.toString();
  }

  static String _formatOversightInfo(Map<String, dynamic> oversightModule, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("📱 ${oversightModule['name']}");
      info.writeln("Jenama: ${oversightModule['brand']}");
      info.writeln("Kategori: ${oversightModule['category']}");
      info.writeln("");

      info.writeln("📋 Penerangan:");
      info.writeln(oversightModule['description']);
      info.writeln("");

      Map<String, dynamic> specs = oversightModule['specifications'];
      info.writeln("⚙️ Spesifikasi:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        } else if (value is List && value.isNotEmpty) {
          info.writeln("• $key:");
          for (var item in value) {
            info.writeln("  - $item");
          }
        }
      });

      info.writeln("");
      info.writeln("✨ Ciri Utama:");
      List<String> features = List<String>.from(oversightModule['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
    } else if (language == 'zh') {
      info.writeln("📱 ${oversightModule['name']}");
      info.writeln("品牌: ${oversightModule['brand']}");
      info.writeln("类别: ${oversightModule['category']}");
      info.writeln("");

      info.writeln("📋 描述:");
      info.writeln(oversightModule['description']);
      info.writeln("");

      Map<String, dynamic> specs = oversightModule['specifications'];
      info.writeln("⚙️ 规格:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        } else if (value is List && value.isNotEmpty) {
          info.writeln("• $key:");
          for (var item in value) {
            info.writeln("  - $item");
          }
        }
      });

      info.writeln("");
      info.writeln("✨ 主要功能:");
      List<String> features = List<String>.from(oversightModule['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
    } else {
      info.writeln("📱 ${oversightModule['name']}");
      info.writeln("Brand: ${oversightModule['brand']}");
      info.writeln("Category: ${oversightModule['category']}");
      info.writeln("");

      info.writeln("📋 Description:");
      info.writeln(oversightModule['description']);
      info.writeln("");

      Map<String, dynamic> specs = oversightModule['specifications'];
      info.writeln("⚙️ Specifications:");
      specs.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        } else if (value is List && value.isNotEmpty) {
          info.writeln("• $key:");
          for (var item in value) {
            info.writeln("  - $item");
          }
        }
      });

      info.writeln("");
      info.writeln("✨ Key Features:");
      List<String> features = List<String>.from(oversightModule['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }
    }

    return info.toString();
  }

  static String _formatAVSInfo(Map<String, dynamic> avsSystem, String message, String language) {
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("⚡ ${avsSystem['name']}");
      info.writeln("Jenama: ${avsSystem['brand']}");
      info.writeln("Kategori: ${avsSystem['category']}");
      info.writeln("");

      info.writeln("📋 Penerangan:");
      info.writeln(avsSystem['description']);
      info.writeln("");

      Map<String, dynamic> specs = avsSystem['specifications'];
      info.writeln("⚙️ Spesifikasi:");
      specs.forEach((key, value) {
        if (key == 'models_available') {
          info.writeln("• Model Tersedia:");
          List<String> models = List<String>.from(value);
          for (var model in models) {
            info.writeln("  - $model");
          }
        } else if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });

      // Check if user is asking for specific model details
      String lowerMessage = message.toLowerCase();
      List<dynamic> models = avsSystem['models'];

      for (var model in models) {
        if (lowerMessage.contains(model['model'].toLowerCase())) {
          info.writeln("");
          info.writeln("🔍 Butiran Model - ${model['model']}:");
          info.writeln("• Output Kuasa: ${model['power_output_kva']} KVA");
          info.writeln("• Arus Terperingkat: ${model['rated_current_a']} A");
          info.writeln("• Dimensi (H×W×D): ${model['dimensions_mm']['h']}×${model['dimensions_mm']['w']}×${model['dimensions_mm']['d']} mm");
          info.writeln("• Berat: ${model['weight_kg']} kg");
          info.writeln("• Kabinet: ${model['cabinet']}");
          break;
        }
      }

      info.writeln("");
      info.writeln("✨ Ciri Utama:");
      List<String> features = List<String>.from(avsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }

      info.writeln("");
      info.writeln("🏭 Aplikasi:");
      List<String> applications = List<String>.from(avsSystem['applications']);
      for (var application in applications) {
        info.writeln("• $application");
      }
    } else if (language == 'zh') {
      info.writeln("⚡ ${avsSystem['name']}");
      info.writeln("品牌: ${avsSystem['brand']}");
      info.writeln("类别: ${avsSystem['category']}");
      info.writeln("");

      info.writeln("📋 描述:");
      info.writeln(avsSystem['description']);
      info.writeln("");

      Map<String, dynamic> specs = avsSystem['specifications'];
      info.writeln("⚙️ 规格:");
      specs.forEach((key, value) {
        if (key == 'models_available') {
          info.writeln("• 可用型号:");
          List<String> models = List<String>.from(value);
          for (var model in models) {
            info.writeln("  - $model");
          }
        } else if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });

      // Check if user is asking for specific model details
      String lowerMessage = message.toLowerCase();
      List<dynamic> models = avsSystem['models'];

      for (var model in models) {
        if (lowerMessage.contains(model['model'].toLowerCase())) {
          info.writeln("");
          info.writeln("🔍 型号详情 - ${model['model']}:");
          info.writeln("• 功率输出: ${model['power_output_kva']} KVA");
          info.writeln("• 额定电流: ${model['rated_current_a']} A");
          info.writeln("• 尺寸 (H×W×D): ${model['dimensions_mm']['h']}×${model['dimensions_mm']['w']}×${model['dimensions_mm']['d']} mm");
          info.writeln("• 重量: ${model['weight_kg']} kg");
          info.writeln("• 机柜: ${model['cabinet']}");
          break;
        }
      }

      info.writeln("");
      info.writeln("✨ 主要功能:");
      List<String> features = List<String>.from(avsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }

      info.writeln("");
      info.writeln("🏭 应用:");
      List<String> applications = List<String>.from(avsSystem['applications']);
      for (var application in applications) {
        info.writeln("• $application");
      }
    } else {
      info.writeln("⚡ ${avsSystem['name']}");
      info.writeln("Brand: ${avsSystem['brand']}");
      info.writeln("Category: ${avsSystem['category']}");
      info.writeln("");

      info.writeln("📋 Description:");
      info.writeln(avsSystem['description']);
      info.writeln("");

      Map<String, dynamic> specs = avsSystem['specifications'];
      info.writeln("⚙️ Specifications:");
      specs.forEach((key, value) {
        if (key == 'models_available') {
          info.writeln("• Available Models:");
          List<String> models = List<String>.from(value);
          for (var model in models) {
            info.writeln("  - $model");
          }
        } else if (value is String && value.isNotEmpty) {
          info.writeln("• $key: $value");
        }
      });

      // Check if user is asking for specific model details
      String lowerMessage = message.toLowerCase();
      List<dynamic> models = avsSystem['models'];

      for (var model in models) {
        if (lowerMessage.contains(model['model'].toLowerCase())) {
          info.writeln("");
          info.writeln("🔍 Model Details - ${model['model']}:");
          info.writeln("• Power Output: ${model['power_output_kva']} KVA");
          info.writeln("• Rated Current: ${model['rated_current_a']} A");
          info.writeln("• Dimensions (H×W×D): ${model['dimensions_mm']['h']}×${model['dimensions_mm']['w']}×${model['dimensions_mm']['d']} mm");
          info.writeln("• Weight: ${model['weight_kg']} kg");
          info.writeln("• Cabinet: ${model['cabinet']}");
          break;
        }
      }

      info.writeln("");
      info.writeln("✨ Key Features:");
      List<String> features = List<String>.from(avsSystem['features']);
      for (var feature in features) {
        info.writeln("• $feature");
      }

      info.writeln("");
      info.writeln("🏭 Applications:");
      List<String> applications = List<String>.from(avsSystem['applications']);
      for (var application in applications) {
        info.writeln("• $application");
      }
    }

    return info.toString();
  }

  static List<String> getAvailableModels() {
    if (_knowledgeBase == null) return [];

    List<String> models = [];
    List<dynamic> generators = _knowledgeBase!['generators'];
    List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];

    for (var generator in generators) {
      models.add(generator['name']);
    }

    for (var atsSystem in atsSystems) {
      models.add(atsSystem['name']);
    }

    return models;
  }

  // Enhanced intelligence methods
  static Map<String, dynamic> _analyzeConversationContext(String userMessage, List<ChatMessage> conversationHistory) {
    Map<String, dynamic> analysis = {
      'userIntent': detectUserIntent(userMessage),
      'conversationFlow': _analyzeConversationFlow(conversationHistory),
      'emotionalTone': _detectEmotionalTone(userMessage),
      'complexityLevel': _assessComplexity(userMessage),
      'followUpNeeded': _isFollowUpNeeded(userMessage, conversationHistory),
      'topicsDiscussed': _extractTopicsFromHistory(conversationHistory),
    };
    return analysis;
  }

  static String detectUserIntent(String message) {
    String lowerMessage = message.toLowerCase();

    // Error code detection takes priority
    List<String> detectedCodes = detectErrorCodes(message);
    if (detectedCodes.isNotEmpty) {
      return 'error_code_query';
    }

    // Troubleshooting queries
    if (lowerMessage.contains('problem') || lowerMessage.contains('issue') ||
        lowerMessage.contains('troubleshoot') || lowerMessage.contains('not working') ||
        lowerMessage.contains('won\'t start') || lowerMessage.contains('fail') ||
        lowerMessage.contains('error') || lowerMessage.contains('broken') ||
        lowerMessage.contains('stop') || lowerMessage.contains('fix') ||
        lowerMessage.contains('repair') || lowerMessage.contains('fault')) {
      return 'troubleshooting';
    }

    // Maintenance queries
    if (lowerMessage.contains('maintenance') || lowerMessage.contains('service') ||
        lowerMessage.contains('check') || lowerMessage.contains('inspect') ||
        lowerMessage.contains('oil change') || lowerMessage.contains('filter') ||
        lowerMessage.contains('schedule') || lowerMessage.contains('routine')) {
      return 'maintenance_inquiry';
    }

    // Product inquiries
    if (lowerMessage.contains('generator') || lowerMessage.contains('genset') ||
        lowerMessage.contains('power bank') || lowerMessage.contains('battery') ||
        lowerMessage.contains('ats') || lowerMessage.contains('transfer switch') ||
        lowerMessage.contains('avs') || lowerMessage.contains('voltage stabilizer') ||
        lowerMessage.contains('oversight') || lowerMessage.contains('monitoring') ||
        lowerMessage.contains('kva') || lowerMessage.contains('kw') ||
        lowerMessage.contains('specification') || lowerMessage.contains('spec') ||
        lowerMessage.contains('model') || lowerMessage.contains('feature')) {
      return 'product_inquiry';
    }

    // Pricing inquiries
    if (lowerMessage.contains('price') || lowerMessage.contains('cost') ||
        lowerMessage.contains('quotation') || lowerMessage.contains('quote') ||
        lowerMessage.contains('how much') || lowerMessage.contains('budget')) {
      return 'pricing_inquiry';
    }

    // Comparison requests
    if (lowerMessage.contains('compare') || lowerMessage.contains('difference') ||
        lowerMessage.contains('vs') || lowerMessage.contains('versus') ||
        lowerMessage.contains('better') || lowerMessage.contains('which is')) {
      return 'comparison_request';
    }

    // Recommendation requests
    if (lowerMessage.contains('recommend') || lowerMessage.contains('suggest') ||
        lowerMessage.contains('best') || lowerMessage.contains('should i') ||
        lowerMessage.contains('what do you think') || lowerMessage.contains('advice')) {
      return 'recommendation_request';
    }

    // Technical inquiries
    if (lowerMessage.contains('technical') || lowerMessage.contains('detail') ||
        lowerMessage.contains('how does') || lowerMessage.contains('explain') ||
        lowerMessage.contains('work') || lowerMessage.contains('function')) {
      return 'technical_inquiry';
    }

    // Installation inquiries
    if (lowerMessage.contains('install') || lowerMessage.contains('setup') ||
        lowerMessage.contains('mount') || lowerMessage.contains('connect') ||
        lowerMessage.contains('wiring') || lowerMessage.contains('commissioning')) {
      return 'installation_inquiry';
    }

    // Help requests
    if (lowerMessage.contains('help') || lowerMessage.contains('what can you do') ||
        lowerMessage.contains('assist') || lowerMessage.contains('support')) {
      return 'help_request';
    }

    // Greetings
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi') ||
        lowerMessage.contains('hey') || lowerMessage.contains('good morning') ||
        lowerMessage.contains('good afternoon') || lowerMessage.contains('good evening')) {
      return 'greeting';
    }

    // Contact inquiries
    if (lowerMessage.contains('contact') || lowerMessage.contains('phone') ||
        lowerMessage.contains('email') || lowerMessage.contains('reach') ||
        lowerMessage.contains('call') || lowerMessage.contains('talk to') ||
        lowerMessage.contains('speak with')) {
      return 'contact_inquiry';
    }

    return 'general_inquiry';
  }

  static String _analyzeConversationFlow(List<ChatMessage> history) {
    if (history.isEmpty) return 'new_conversation';
    
    int recentMessages = history.length > 5 ? 5 : history.length;
    List<ChatMessage> recent = history.sublist(history.length - recentMessages);
    
    bool userAskingQuestions = recent.where((m) => m.isUser && 
        (m.text.contains('?') || m.text.contains('how') || m.text.contains('what') || m.text.contains('why'))).isNotEmpty;
    
    bool botProvidingInfo = recent.where((m) => !m.isUser && 
        (m.text.contains('•') || m.text.contains('specification') || m.text.contains('feature'))).isNotEmpty;
    
    if (userAskingQuestions && botProvidingInfo) {
      return 'information_seeking';
    } else if (recent.any((m) => m.text.toLowerCase().contains('thank'))) {
      return 'concluding';
    } else {
      return 'ongoing_dialogue';
    }
  }

  static String _detectEmotionalTone(String message) {
    String lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('urgent') || lowerMessage.contains('emergency') || lowerMessage.contains('asap')) {
      return 'urgent';
    } else if (lowerMessage.contains('confused') || lowerMessage.contains('don\'t understand') || lowerMessage.contains('help')) {
      return 'confused';
    } else if (lowerMessage.contains('interested') || lowerMessage.contains('looking for') || lowerMessage.contains('want')) {
      return 'interested';
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('great') || lowerMessage.contains('perfect')) {
      return 'satisfied';
    } else {
      return 'neutral';
    }
  }

  static String _assessComplexity(String message) {
    int wordCount = message.split(' ').length;
    bool hasTechnicalTerms = message.toLowerCase().contains(RegExp(r'(kva|kw|ats|avs|specification|installation|voltage|amperage)'));
    bool hasComparisons = message.toLowerCase().contains(RegExp(r'(compare|vs|difference|versus)'));
    
    if (wordCount > 20 || (hasTechnicalTerms && hasComparisons)) {
      return 'high';
    } else if (wordCount > 10 || hasTechnicalTerms || hasComparisons) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  static bool _isFollowUpNeeded(String message, List<ChatMessage> history) {
    String lowerMessage = message.toLowerCase();
    return lowerMessage.contains('more') || 
           lowerMessage.contains('also') || 
           lowerMessage.contains('what about') ||
           lowerMessage.contains('tell me more') ||
           (history.isNotEmpty && history.last.isUser && lowerMessage.length < 10);
  }

  static List<String> _extractTopicsFromHistory(List<ChatMessage> history) {
    Set<String> topics = {};
    for (var message in history.take(10)) {
      topics.addAll(_extractTopics(message.text));
    }
    return topics.toList();
  }

  // Search through all catalogue data for relevant information
  static String? _searchCatalogueForQuery(String message, String language) {
    String lowerMessage = message.toLowerCase();

    // Search through generators for matching keywords
    List<dynamic> generators = _knowledgeBase!['generators'];
    for (var generator in generators) {
      // Check if message contains generator name, model, or power rating
      if (lowerMessage.contains(generator['name'].toLowerCase()) ||
          lowerMessage.contains(generator['model'].toLowerCase()) ||
          lowerMessage.contains(generator['power'].toLowerCase()) ||
          lowerMessage.contains(generator['brand'].toLowerCase())) {

        // Check if it's a specific request for this generator
        if (lowerMessage.contains('15kva') || lowerMessage.contains('15 kva') ||
            lowerMessage.contains('15kw') || lowerMessage.contains('15 kw')) {
          return _formatDetailedGensetInfo(generator, language);
        }
      }
    }

    // Search through power banks
    List<dynamic> powerBanks = _knowledgeBase!['power_banks'];
    for (var powerBank in powerBanks) {
      if (lowerMessage.contains('power bank') || lowerMessage.contains('battery') ||
          lowerMessage.contains('solar') || lowerMessage.contains('10kw')) {
        return _getPowerBankInfo(language);
      }
    }

    // Search through ATS systems
    List<dynamic> atsSystems = _knowledgeBase!['ats_systems'];
    for (var atsSystem in atsSystems) {
      if (lowerMessage.contains('ats') || lowerMessage.contains('transfer switch') ||
          lowerMessage.contains('automatic transfer')) {
        return _getATSInfo(language);
      }
    }

    // Search for specific technical specifications
    if (lowerMessage.contains('engine') || lowerMessage.contains('alternator') ||
        lowerMessage.contains('control panel') || lowerMessage.contains('specifications')) {
      return _findTechnicalInfo(message, language);
    }

    // Search for application-specific information
    if (lowerMessage.contains('home') || lowerMessage.contains('residential') ||
        lowerMessage.contains('business') || lowerMessage.contains('commercial') ||
        lowerMessage.contains('industrial') || lowerMessage.contains('construction')) {
      return _findApplicationInfo(message, language);
    }

    // Return null if no specific match found
    return null;
  }

  static String _findTechnicalInfo(String message, String language) {
    List<dynamic> generators = _knowledgeBase!['generators'];
    StringBuffer info = StringBuffer();

    if (language == 'ms') {
      info.writeln("🔍 MAKLUMAT TEKNIKAL");
      info.writeln("");

      for (var generator in generators) {
        if (message.toLowerCase().contains(generator['power'].toLowerCase()) ||
            message.toLowerCase().contains(generator['name'].toLowerCase())) {

          info.writeln("📋 ${generator['name']}");
          Map<String, dynamic> specs = generator['specifications'];

          info.writeln("📊 SPESIFIKASI TERPERINCI:");
          if (specs['prime_power'] != null) info.writeln("• Kuasa Perdana: ${specs['prime_power']}");
          if (specs['engine_model'] != null) info.writeln("• Model Enjin: ${specs['engine_model']}");
          if (specs['engine_type'] != null) info.writeln("• Jenis Enjin: ${specs['engine_type']}");
          if (specs['cylinders'] != null) info.writeln("• Silinder: ${specs['cylinders']}");
          if (specs['bore_stroke'] != null) info.writeln("• Bore x Stroke: ${specs['bore_stroke']}");
          if (specs['compression_ratio'] != null) info.writeln("• Nisbah Mampatan: ${specs['compression_ratio']}");
          if (specs['displacement'] != null) info.writeln("• Anjakan: ${specs['displacement']}");
          if (specs['rated_power'] != null) info.writeln("• Kuasa Terperingkat: ${specs['rated_power']}");
          if (specs['rated_speed'] != null) info.writeln("• Kelajuan Terperingkat: ${specs['rated_speed']}");
          if (specs['fuel_consumption'] != null) info.writeln("• Penggunaan Bahan Api: ${specs['fuel_consumption']}");
          if (specs['fuel_tank_capacity'] != null) info.writeln("• Kapasiti Tangki Bahan Api: ${specs['fuel_tank_capacity']}");
          if (specs['cooling_system'] != null) info.writeln("• Sistem Penyejukan: ${specs['cooling_system']}");
          if (specs['starting_method'] != null) info.writeln("• Kaedah Penghidupan: ${specs['starting_method']}");
          if (specs['alternator_model'] != null) info.writeln("• Model Alternator: ${specs['alternator_model']}");
          if (specs['exciter_type'] != null) info.writeln("• Jenis Exciter: ${specs['exciter_type']}");
          if (specs['voltage'] != null) info.writeln("• Voltan: ${specs['voltage']}");
          if (specs['frequency'] != null) info.writeln("• Frekuensi: ${specs['frequency']}");
          if (specs['power_factor'] != null) info.writeln("• Faktor Kuasa: ${specs['power_factor']}");
          if (specs['phase'] != null) info.writeln("• Fasa: ${specs['phase']}");
          if (specs['voltage_regulation'] != null) info.writeln("• Pengawalan Voltan: ${specs['voltage_regulation']}");
          if (specs['insulation_grade'] != null) info.writeln("• Gred Penebatan: ${specs['insulation_grade']}");
          if (specs['dimensions'] != null) info.writeln("• Dimensi: ${specs['dimensions']}");
          if (specs['weight'] != null) info.writeln("• Berat: ${specs['weight']}");
          info.writeln("");
          break;
        }
      }

    } else if (language == 'zh') {
      info.writeln("🔍 技术信息");
      info.writeln("");

      for (var generator in generators) {
        if (message.toLowerCase().contains(generator['power'].toLowerCase()) ||
            message.toLowerCase().contains(generator['name'].toLowerCase())) {

          info.writeln("📋 ${generator['name']}");
          Map<String, dynamic> specs = generator['specifications'];

          info.writeln("📊 详细规格:");
          if (specs['prime_power'] != null) info.writeln("• 主要功率: ${specs['prime_power']}");
          if (specs['engine_model'] != null) info.writeln("• 引擎型号: ${specs['engine_model']}");
          if (specs['engine_type'] != null) info.writeln("• 引擎类型: ${specs['engine_type']}");
          if (specs['cylinders'] != null) info.writeln("• 气缸数: ${specs['cylinders']}");
          if (specs['bore_stroke'] != null) info.writeln("• 缸径x冲程: ${specs['bore_stroke']}");
          if (specs['compression_ratio'] != null) info.writeln("• 压缩比: ${specs['compression_ratio']}");
          if (specs['displacement'] != null) info.writeln("• 排量: ${specs['displacement']}");
          if (specs['rated_power'] != null) info.writeln("• 额定功率: ${specs['rated_power']}");
          if (specs['rated_speed'] != null) info.writeln("• 额定转速: ${specs['rated_speed']}");
          if (specs['fuel_consumption'] != null) info.writeln("• 燃油消耗: ${specs['fuel_consumption']}");
          if (specs['fuel_tank_capacity'] != null) info.writeln("• 油箱容量: ${specs['fuel_tank_capacity']}");
          if (specs['cooling_system'] != null) info.writeln("• 冷却系统: ${specs['cooling_system']}");
          if (specs['starting_method'] != null) info.writeln("• 启动方式: ${specs['starting_method']}");
          if (specs['alternator_model'] != null) info.writeln("• 发电机型号: ${specs['alternator_model']}");
          if (specs['exciter_type'] != null) info.writeln("• 励磁类型: ${specs['exciter_type']}");
          if (specs['voltage'] != null) info.writeln("• 电压: ${specs['voltage']}");
          if (specs['frequency'] != null) info.writeln("• 频率: ${specs['frequency']}");
          if (specs['power_factor'] != null) info.writeln("• 功率因数: ${specs['power_factor']}");
          if (specs['phase'] != null) info.writeln("• 相位: ${specs['phase']}");
          if (specs['voltage_regulation'] != null) info.writeln("• 电压调节: ${specs['voltage_regulation']}");
          if (specs['insulation_grade'] != null) info.writeln("• 绝缘等级: ${specs['insulation_grade']}");
          if (specs['dimensions'] != null) info.writeln("• 尺寸: ${specs['dimensions']}");
          if (specs['weight'] != null) info.writeln("• 重量: ${specs['weight']}");
          info.writeln("");
          break;
        }
      }

    } else {
      info.writeln("🔍 TECHNICAL INFORMATION");
      info.writeln("");

      for (var generator in generators) {
        if (message.toLowerCase().contains(generator['power'].toLowerCase()) ||
            message.toLowerCase().contains(generator['name'].toLowerCase())) {

          info.writeln("📋 ${generator['name']}");
          Map<String, dynamic> specs = generator['specifications'];

          info.writeln("📊 DETAILED SPECIFICATIONS:");
          if (specs['prime_power'] != null) info.writeln("• Prime Power: ${specs['prime_power']}");
          if (specs['engine_model'] != null) info.writeln("• Engine Model: ${specs['engine_model']}");
          if (specs['engine_type'] != null) info.writeln("• Engine Type: ${specs['engine_type']}");
          if (specs['cylinders'] != null) info.writeln("• Cylinders: ${specs['cylinders']}");
          if (specs['bore_stroke'] != null) info.writeln("• Bore x Stroke: ${specs['bore_stroke']}");
          if (specs['compression_ratio'] != null) info.writeln("• Compression Ratio: ${specs['compression_ratio']}");
          if (specs['displacement'] != null) info.writeln("• Displacement: ${specs['displacement']}");
          if (specs['rated_power'] != null) info.writeln("• Rated Power: ${specs['rated_power']}");
          if (specs['rated_speed'] != null) info.writeln("• Rated Speed: ${specs['rated_speed']}");
          if (specs['fuel_consumption'] != null) info.writeln("• Fuel Consumption: ${specs['fuel_consumption']}");
          if (specs['fuel_tank_capacity'] != null) info.writeln("• Fuel Tank Capacity: ${specs['fuel_tank_capacity']}");
          if (specs['cooling_system'] != null) info.writeln("• Cooling System: ${specs['cooling_system']}");
          if (specs['starting_method'] != null) info.writeln("• Starting Method: ${specs['starting_method']}");
          if (specs['alternator_model'] != null) info.writeln("• Alternator Model: ${specs['alternator_model']}");
          if (specs['exciter_type'] != null) info.writeln("• Exciter Type: ${specs['exciter_type']}");
          if (specs['voltage'] != null) info.writeln("• Voltage: ${specs['voltage']}");
          if (specs['frequency'] != null) info.writeln("• Frequency: ${specs['frequency']}");
          if (specs['power_factor'] != null) info.writeln("• Power Factor: ${specs['power_factor']}");
          if (specs['phase'] != null) info.writeln("• Phase: ${specs['phase']}");
          if (specs['voltage_regulation'] != null) info.writeln("• Voltage Regulation: ${specs['voltage_regulation']}");
          if (specs['insulation_grade'] != null) info.writeln("• Insulation Grade: ${specs['insulation_grade']}");
          if (specs['dimensions'] != null) info.writeln("• Dimensions: ${specs['dimensions']}");
          if (specs['weight'] != null) info.writeln("• Weight: ${specs['weight']}");
          info.writeln("");
          break;
        }
      }
    }

    String result = info.toString();
    return result.isNotEmpty ? result : "No information available.";
  }

  static Future<String> _generateEnhancedResponse(String message, String language, Map<String, dynamic> contextAnalysis) async {
    String userIntent = contextAnalysis['userIntent'];
    String emotionalTone = contextAnalysis['emotionalTone'];
    String complexityLevel = contextAnalysis['complexityLevel'];
    bool followUpNeeded = contextAnalysis['followUpNeeded'];
    
    // Add processing delay for natural feel
    await Future.delayed(Duration(milliseconds: 300 + (complexityLevel == 'high' ? 500 : complexityLevel == 'medium' ? 300 : 100)));
    
    // Generate base response
    String baseResponse = _generateContextualResponse(message, language);
    
    // Enhance based on context analysis
    String enhancedResponse = _enhanceResponseWithContext(baseResponse, contextAnalysis, language);
    
    // Add follow-up suggestions if needed
    if (followUpNeeded && _recentTopics.isNotEmpty) {
      enhancedResponse += _generateFollowUpSuggestions(contextAnalysis, language);
    }
    
    return enhancedResponse;
  }

  static String _enhanceResponseWithContext(String baseResponse, Map<String, dynamic> contextAnalysis, String language) {
    String emotionalTone = contextAnalysis['emotionalTone'];
    String userIntent = contextAnalysis['userIntent'];
    String complexityLevel = contextAnalysis['complexityLevel'];
    
    // Add emotional intelligence
    if (emotionalTone == 'urgent') {
      baseResponse = _getLocalizedResponse("I understand this is urgent. ", language) + baseResponse;
    } else if (emotionalTone == 'confused') {
      baseResponse = _getLocalizedResponse("Let me help clarify this for you. ", language) + baseResponse;
    } else if (emotionalTone == 'interested') {
      baseResponse = _getLocalizedResponse("Great question! ", language) + baseResponse;
    }
    
    // Adjust complexity based on user level
    if (complexityLevel == 'low' && userIntent == 'technical_inquiry') {
      baseResponse = _simplifyTechnicalResponse(baseResponse, language);
    } else if (complexityLevel == 'high' && userIntent != 'technical_inquiry') {
      baseResponse = _addTechnicalDetails(baseResponse, contextAnalysis, language);
    }
    
    // Add contextual references
    if (_recentTopics.isNotEmpty && userIntent != 'greeting') {
      String lastTopic = _recentTopics.last;
      if (!baseResponse.toLowerCase().contains(lastTopic.toLowerCase())) {
        baseResponse = _getLocalizedResponse("Building on our discussion about $lastTopic, ", language) + baseResponse;
      }
    }
    
    return baseResponse;
  }

  static String _simplifyTechnicalResponse(String response, String language) {
    // Simplify technical jargon for easier understanding
    Map<String, String> simplifications = {
      'KVA': 'kilovolt-ampere (power unit)',
      'ATS': 'Automatic Transfer Switch (automatically switches power)',
      'AVS': 'Automatic Voltage Stabilizer (maintains stable voltage)',
      'specifications': 'technical details',
      'fuel consumption': 'how much fuel it uses',
    };
    
    String simplified = response;
    simplifications.forEach((complex, simple) {
      simplified = simplified.replaceAll(complex, simple);
    });
    
    return simplified;
  }

  static String _addTechnicalDetails(String response, Map<String, dynamic> contextAnalysis, String language) {
    // Add additional technical details for complex queries
    List<String> topics = contextAnalysis['topicsDiscussed'] ?? [];
    
    if (topics.contains('generator')) {
      response += _getLocalizedResponse("\n\n🔧 Technical Note: All our generators come with SmartGen or Deep Sea Electronics control systems for advanced monitoring and control.", language);
    } else if (topics.contains('ats')) {
      response += _getLocalizedResponse("\n\n🔧 Technical Note: Our ATS systems support dual generator configurations for 24/7 power availability.", language);
    }
    
    return response;
  }

  static String _generateFollowUpSuggestions(Map<String, dynamic> contextAnalysis, String language) {
    String userIntent = contextAnalysis['userIntent'];
    List<String> topics = contextAnalysis['topicsDiscussed'] ?? [];
    
    String followUpText = _getLocalizedResponse("\n\n💡 You might also be interested in:", language);
    
    if (topics.contains('generator')) {
      followUpText += _getLocalizedResponse("\n• Installation requirements", language);
      followUpText += _getLocalizedResponse("\n• Maintenance schedules", language);
      followUpText += _getLocalizedResponse("\n• ATS compatibility", language);
    } else if (topics.contains('ats')) {
      followUpText += _getLocalizedResponse("\n• Generator pairing options", language);
      followUpText += _getLocalizedResponse("\n• Installation guidelines", language);
      followUpText += _getLocalizedResponse("\n• Technical specifications", language);
    }
    
    return followUpText;
  }

  // Error code detection and handling methods
  static List<String> detectErrorCodes(String message) {
    if (_errorCodes == null) return [];

    List<String> detectedCodes = [];
    String lowerMessage = message.toLowerCase();

    // Check for error codes in the message
    Map<String, dynamic> errorCodes = _errorCodes!['error_codes'];
    errorCodes.forEach((code, data) {
      // Check for exact code matches
      if (lowerMessage.contains(code.toLowerCase())) {
        detectedCodes.add(code);
      }

      // Check for common variations and descriptions
      String description = (data['description'] ?? '').toLowerCase();
      if (lowerMessage.contains(description)) {
        detectedCodes.add(code);
      }
    });

    // Remove duplicates
    return detectedCodes.toSet().toList();
  }

  static String _handleErrorCodeQuery(List<String> errorCodes, String message, String language) {
    if (_errorCodes == null) {
      return _getLocalizedResponse("I'm having trouble accessing the error code database. Please try again later.", language);
    }

    StringBuffer response = StringBuffer();

    if (language == 'ms') {
      response.writeln("🔧 ANALISIS KOD KESALAHAN");
      response.writeln("");
      response.writeln("Saya telah mengesan kod kesalahan berikut dalam mesej anda:");
      response.writeln("");
    } else if (language == 'zh') {
      response.writeln("🔧 故障代码分析");
      response.writeln("");
      response.writeln("我在您的消息中检测到以下故障代码：");
      response.writeln("");
    } else {
      response.writeln("🔧 ERROR CODE ANALYSIS");
      response.writeln("");
      response.writeln("I've detected the following error codes in your message:");
      response.writeln("");
    }

    // Process each detected error code
    Map<String, dynamic> errorCodesData = _errorCodes!['error_codes'];
    for (String code in errorCodes) {
      if (errorCodesData.containsKey(code)) {
        Map<String, dynamic> errorData = errorCodesData[code];

        if (language == 'ms') {
          response.writeln("🚨 **KOD: $code**");
          response.writeln("📋 Penerangan: ${errorData['description']}");
          response.writeln("⚠️ Keparahan: ${errorData['severity']}");
          response.writeln("🛑 Tindakan Segera: ${errorData['immediate_action']}");
          response.writeln("");

          response.writeln("🔍 Punca Berpotensi:");
          List<String> causes = List<String>.from(errorData['causes']);
          for (int i = 0; i < causes.length; i++) {
            response.writeln("${i + 1}. ${causes[i]}");
          }
          response.writeln("");

          response.writeln("🛠️ Penyelesaian:");
          List<String> solutions = List<String>.from(errorData['solutions']);
          for (int i = 0; i < solutions.length; i++) {
            response.writeln("${i + 1}. ${solutions[i]}");
          }
          response.writeln("");

          response.writeln("👨‍🔧 Catatan Juruteknik: ${errorData['technician_notes']}");
          response.writeln("");
        } else if (language == 'zh') {
          response.writeln("🚨 **代码: $code**");
          response.writeln("📋 描述: ${errorData['description']}");
          response.writeln("⚠️ 严重程度: ${errorData['severity']}");
          response.writeln("🛑 立即行动: ${errorData['immediate_action']}");
          response.writeln("");

          response.writeln("🔍 潜在原因:");
          List<String> causes = List<String>.from(errorData['causes']);
          for (int i = 0; i < causes.length; i++) {
            response.writeln("${i + 1}. ${causes[i]}");
          }
          response.writeln("");

          response.writeln("🛠️ 解决方案:");
          List<String> solutions = List<String>.from(errorData['solutions']);
          for (int i = 0; i < solutions.length; i++) {
            response.writeln("${i + 1}. ${solutions[i]}");
          }
          response.writeln("");

          response.writeln("👨‍🔧 技术员备注: ${errorData['technician_notes']}");
          response.writeln("");
        } else {
          response.writeln("🚨 **CODE: $code**");
          response.writeln("📋 Description: ${errorData['description']}");
          response.writeln("⚠️ Severity: ${errorData['severity']}");
          response.writeln("🛑 Immediate Action: ${errorData['immediate_action']}");
          response.writeln("");

          response.writeln("🔍 Potential Causes:");
          List<String> causes = List<String>.from(errorData['causes']);
          for (int i = 0; i < causes.length; i++) {
            response.writeln("${i + 1}. ${causes[i]}");
          }
          response.writeln("");

          response.writeln("🛠️ Solutions:");
          List<String> solutions = List<String>.from(errorData['solutions']);
          for (int i = 0; i < solutions.length; i++) {
            response.writeln("${i + 1}. ${solutions[i]}");
          }
          response.writeln("");

          response.writeln("👨‍🔧 Technician Notes: ${errorData['technician_notes']}");
          response.writeln("");
        }
      }
    }

    // Add follow-up questions
    if (language == 'ms') {
      response.writeln("❓ Soalan Susulan:");
      response.writeln("• Adakah generator masih berjalan?");
      response.writeln("• Bilakah kod kesalahan ini muncul?");
      response.writeln("• Adakah terdapat sebarang gejala lain?");
      response.writeln("• Adakah anda telah cuba sebarang penyelesaian?");
      response.writeln("");
      response.writeln("📞 **Untuk bantuan segera, hubungi teknikal kami:**");
      response.writeln("• Telefon: +60 12-968 9816");
      response.writeln("• WhatsApp: +60 12-968 9816");
      response.writeln("");
      response.writeln("⚠️ **PENTING:** Jika kod kesalahan menunjukkan 'CRITICAL' atau 'HIGH', hentikan generator dengan segera untuk mengelakkan kerosakan yang lebih teruk.");
    } else if (language == 'zh') {
      response.writeln("❓ 后续问题:");
      response.writeln("• 发电机还在运行吗？");
      response.writeln("• 这个故障代码是什么时候出现的？");
      response.writeln("• 是否有其他症状？");
      response.writeln("• 您是否已经尝试过任何解决方案？");
      response.writeln("");
      response.writeln("📞 **如需紧急帮助，请联系我们的技术人员:**");
      response.writeln("• 电话: +60 12-968 9816");
      response.writeln("• WhatsApp: +60 12-968 9816");
      response.writeln("");
      response.writeln("⚠️ **重要:** 如果故障代码显示'CRITICAL'或'HIGH'，请立即停止发电机以避免更严重的损坏。");
    } else {
      response.writeln("❓ Follow-up Questions:");
      response.writeln("• Is the generator still running?");
      response.writeln("• When did this error code appear?");
      response.writeln("• Are there any other symptoms?");
      response.writeln("• Have you tried any solutions already?");
      response.writeln("");
      response.writeln("📞 **For immediate assistance, contact our technical team:**");
      response.writeln("• Phone: +60 12-968 9816");
      response.writeln("• WhatsApp: +60 12-968 9816");
      response.writeln("");
      response.writeln("⚠️ **IMPORTANT:** If the error code shows 'CRITICAL' or 'HIGH' severity, stop the generator immediately to prevent further damage.");
    }

    return response.toString();
  }
}

// ChatMessage class for conversation history
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? image; // Optional image path for product images

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.image,
  });
}
