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
      // Ensure API key is loaded
      if (_apiKey == null || _apiKey!.isEmpty) {
        await loadAPIKey();
      }

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

  // Build comprehensive knowledge base context
  static Future<String> _buildKnowledgeBaseContext(String userMessage, String language) async {
    String lowerMessage = userMessage.toLowerCase();

    // Comprehensive MGM Generator Knowledge Base
    String knowledgeBase = """
MGM GENERATOR COMPREHENSIVE PRODUCT DATABASE - MALAYSIA'S LEADING POWER SOLUTIONS PROVIDER

GENERATOR MODELS & SPECIFICATIONS:

1. 15KVA MGM GENERATOR:
   - Prime Power: 15KVA / 12KW
   - Engine: Diesel, 4-cylinder, water-cooled
   - Fuel Consumption: 3.5 L/hr at 75% load
   - Dimensions: 1800mm x 800mm x 1200mm
   - Weight: 650kg
   - Applications: Small offices, shops, residential backup
   - Price Range: RM 25,000 - RM 35,000
   - Features: Auto start/stop, digital panel, low noise operation

2. 30KVA MGM GENERATOR:
   - Prime Power: 30KVA / 24KW
   - Engine Options: Perkins, Isuzu, MGM diesel engines
   - Fuel Consumption: 7.2 L/hr at 75% load
   - Dimensions: 2200mm x 900mm x 1400mm
   - Weight: 950kg
   - Applications: Small commercial buildings, construction sites, factories
   - Price Range: RM 45,000 - RM 65,000
   - Features: Multiple engine options, advanced control panel, remote monitoring

3. 60KVA MGM GENERATOR:
   - Prime Power: 60KVA / 48KW
   - Engine: Heavy-duty diesel, 4-cylinder turbocharged
   - Fuel Consumption: 14.5 L/hr at 75% load
   - Dimensions: 2800mm x 1100mm x 1600mm
   - Weight: 1800kg
   - Applications: Medium commercial, hospitals, data centers
   - Price Range: RM 85,000 - RM 120,000
   - Features: Redundant systems, auto transfer switch ready

4. 100KVA MGM GENERATOR:
   - Prime Power: 100KVA / 80KW
   - Engine: Industrial diesel, 6-cylinder
   - Fuel Consumption: 22.8 L/hr at 75% load
   - Dimensions: 3200mm x 1200mm x 1800mm
   - Weight: 2500kg
   - Applications: Large commercial, manufacturing facilities
   - Price Range: RM 145,000 - RM 200,000
   - Features: Parallel operation capable, advanced diagnostics

5. 160KVA MGM GENERATOR:
   - Prime Power: 160KVA / 128KW
   - Engine: High-performance diesel, 6-cylinder turbocharged
   - Fuel Consumption: 36.5 L/hr at 75% load
   - Dimensions: 3800mm x 1400mm x 2000mm
   - Weight: 3800kg
   - Applications: Industrial facilities, large buildings
   - Price Range: RM 220,000 - RM 300,000
   - Features: Multiple voltage options, weather protection

6. 250KVA MGM GENERATOR:
   - Prime Power: 250KVA / 200KW
   - Engine: Heavy industrial diesel
   - Fuel Consumption: 56.8 L/hr at 75% load
   - Dimensions: 4500mm x 1600mm x 2200mm
   - Weight: 5500kg
   - Applications: Large industrial, power plants
   - Price Range: RM 350,000 - RM 480,000
   - Features: Containerized options, extreme environment ready

7. 350KVA MGM GENERATOR:
   - Prime Power: 350KVA / 280KW
   - Engine: Commercial-grade diesel
   - Fuel Consumption: 79.2 L/hr at 75% load
   - Dimensions: 5200mm x 1800mm x 2400mm
   - Weight: 7200kg
   - Applications: Critical infrastructure, large facilities
   - Price Range: RM 480,000 - RM 650,000
   - Features: Redundant cooling, advanced monitoring

8. 500KVA MGM GENERATOR:
   - Prime Power: 500KVA / 400KW
   - Engine: Industrial diesel, multi-cylinder
   - Fuel Consumption: 113.6 L/hr at 75% load
   - Dimensions: 6000mm x 2000mm x 2600mm
   - Weight: 9500kg
   - Applications: Power generation, large industrial complexes
   - Price Range: RM 680,000 - RM 920,000
   - Features: Grid synchronization capable, remote management

POWER BANK SYSTEMS:

1. 10KW POWER BANK WITH 20KWH BATTERY:
   - Output Power: 10KW continuous
   - Battery Capacity: 20KWh Lithium-ion
   - Voltage: 400V 3-phase / 230V single-phase options
   - Dimensions: 800mm x 600mm x 1800mm
   - Weight: 280kg
   - Applications: Solar integration, UPS systems, peak shaving
   - Price Range: RM 45,000 - RM 65,000
   - Features: Fast charging, modular design, smart management

2. 10KW POWER BANK WITH 30KWH BATTERY:
   - Output Power: 10KW continuous
   - Battery Capacity: 30KWh Lithium-ion
   - Voltage: 400V 3-phase / 230V single-phase options
   - Dimensions: 800mm x 600mm x 2000mm
   - Weight: 350kg
   - Applications: Extended backup, solar storage, microgrids
   - Price Range: RM 55,000 - RM 78,000
   - Features: Extended runtime, grid-tie capability, monitoring

AUTOMATIC TRANSFER SWITCH (ATS) SYSTEMS:

1. SINGLE PHASE ATS (63A - 125A):
   - Current Rating: 63A, 100A, 125A
   - Voltage: 230V
   - Transfer Time: < 100ms
   - Applications: Residential, small commercial
   - Price Range: RM 2,500 - RM 5,000
   - Features: Manual override, status indicators

2. THREE PHASE ATS (100A - 630A):
   - Current Rating: 100A, 200A, 400A, 630A
   - Voltage: 400V
   - Transfer Time: < 100ms
   - Applications: Commercial, industrial
   - Price Range: RM 8,000 - RM 25,000
   - Features: Microprocessor control, remote monitoring

MAINTENANCE & TROUBLESHOOTING:

COMMON GENERATOR PROBLEMS & SOLUTIONS:

1. WON'T START:
   - Battery: Check voltage (>12V), terminals clean, water level
   - Fuel: Check fuel level, air locks, fuel filters
   - Starter: Check solenoid, wiring, motor
   - Control Panel: Check fuses, programming, sensors

2. LOW OUTPUT POWER:
   - Load: Check connected load vs generator capacity
   - Fuel: Check fuel quality, filters, injection system
   - Engine: Check oil pressure, cooling system, timing
   - Alternator: Check windings, voltage regulator, brushes

3. HIGH FUEL CONSUMPTION:
   - Maintenance: Check air filters, fuel filters, injectors
   - Load: Operating at optimal load (60-80%)
   - Engine: Check valve clearance, compression, timing

4. OVERHEATING:
   - Coolant: Check level, radiator, water pump
   - Load: Reduce load if excessive
   - Ventilation: Ensure proper airflow around generator
   - Thermostat: Check operation and replacement

5. ELECTRICAL FAULTS:
   - ATS: Check transfer switch operation
   - Wiring: Check connections, insulation, grounding
   - Protection: Check circuit breakers, fuses, relays

MAINTENANCE SCHEDULE:
- Daily: Visual inspection, oil level, coolant level, fuel level
- Weekly: Battery check, control panel test, load test
- Monthly: Oil and filter change, air filter check
- Quarterly: Comprehensive inspection, load bank test
- Annually: Major service, engine tune-up, alternator check

INSTALLATION REQUIREMENTS:
- Ventilation: Adequate airflow, exhaust system
- Fuel System: Tank capacity, piping, filtration
- Electrical: Proper grounding, cable sizing, protection
- Foundation: Level surface, vibration isolation
- Sound Attenuation: Acoustic enclosures if required

WARRANTY & SUPPORT:
- Generator Warranty: 1-2 years depending on model
- Engine Warranty: As per manufacturer (Perkins, Cummins, etc.)
- Parts Availability: 24/7 support for critical components
- Technical Support: On-site service, remote diagnostics
- Training: Operator training programs available

DELIVERY & INSTALLATION:
- Delivery Time: 2-8 weeks depending on model
- Installation: Professional installation service available
- Commissioning: Full system testing and handover
- Documentation: Operation manuals, maintenance schedules
- Training: Operator and maintenance personnel training

CONTACT INFORMATION:
- Support Hotline: +60129689816
- Email: info@mggenset.com.my
- Website: www.mggenset.com.my
- Service Centers: Multiple locations across Malaysia
- Emergency Support: 24/7 technical assistance

This comprehensive database covers all MGM generator products, specifications, pricing, troubleshooting guides, and technical support information. Use this information to provide accurate, helpful responses to customers.
""";

    return knowledgeBase;
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
You are a highly skilled and professional Malaysian Genset AI Assistant with extensive technical expertise. You have access to a comprehensive MGM product database and act like an experienced generator technician.

IMPORTANT RULES:
1. ALWAYS provide accurate, detailed product information from the provided context
2. DO NOT suggest contacting phone or email - provide comprehensive information directly
3. Focus on technical specifications, features, applications, and practical advice
4. Provide realistic price estimates in RM (Malaysian Ringgit) with professional insights
5. RESPOND ONLY IN ENGLISH - maintain professional technical language
6. If unsure, say "Based on MGM's product database, I can provide the following information"
7. Act like an expert technician - use technical terms appropriately, give practical advice
8. Provide comparative analysis when relevant (e.g., "For your application, I'd recommend...")
9. Include maintenance insights and operational tips
10. Be proactive in suggesting related products or considerations

AVAILABLE MGM PRODUCTS:
- Diesel generators from 15KVA to 500KVA (specify engine types, applications, features)
- 10KW power bank systems with 20KWh/30KWh batteries (solar integration, backup power)
- ATS (Automatic Transfer Switch) systems (transfer times, ratings, monitoring)
- Monitoring and control modules (remote management, diagnostics)

Respond with the expertise of a senior technician - be thorough, practical, and solution-oriented. Use phrases like "In my experience..." or "For optimal performance..." to sound like a knowledgeable professional.
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
