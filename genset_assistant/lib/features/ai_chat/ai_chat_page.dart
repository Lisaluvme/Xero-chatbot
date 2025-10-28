import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart' as main_app;
import '../../widgets/home_page.dart' show HomePageWidget;

class AiChatPage extends StatefulWidget {
  final String? initialMessage;

  const AiChatPage({super.key, this.initialMessage});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _showHomeShortcut = false;

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  String _currentLanguage = 'en';
  final Map<String, String> _languageNames = {
    'en': 'EN',
    'ms': 'BM',
    'zh': 'CN',
  };

  // Add language change handler
  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage != null && newLanguage != _currentLanguage) {
      print("DEBUG: Language changed from $_currentLanguage to $newLanguage");

      setState(() {
        _currentLanguage = newLanguage;
      });
      _updateTtsLanguage();

      // Show confirmation message in the NEWLY selected language
      String confirmationMessage;
      switch (newLanguage) {
        case 'ms':
          confirmationMessage = 'Bahasa telah ditukar kepada Bahasa Malaysia';
          break;
        case 'zh':
          confirmationMessage = '语言已更改为中文';
          break;
        case 'en':
          confirmationMessage = 'Language changed to English';
          break;
        default:
          confirmationMessage = 'Language changed to English';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmationMessage),
          duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Delay TTS initialization to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoiceFeatures();
    });
  }

  Future<void> _initializeChat() async {
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    _addWelcomeMessage();

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _addMessage(widget.initialMessage!, true);

      // Show typing indicator
      _showTypingIndicator();

      // Generate intelligent response using DeepSeek
      Map<String, dynamic> responseData = await _generateIntelligentResponse(widget.initialMessage!);

      // Remove typing indicator
      _removeTypingIndicator();

      // Add response with typing effect
      _addMessageWithTypingEffect(responseData['text'], false, responseData['image']);
    }
  }

  Future<void> _initializeVoiceFeatures() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await Permission.microphone.request();
  }

  void _addWelcomeMessage() {
    const userName = 'User';

    String welcomeMessage;
    switch (_currentLanguage) {
      case 'ms':
        welcomeMessage =
            'Hello $userName! 👋 Saya adalah Pembantu AI Genset Malaysia anda yang dikuasakan oleh DeepSeek AI.\n\n🤖 Saya boleh membantu anda dengan:\n• Model generator (15KVA - 500KVA)\n• Sistem power bank (10KW dengan 20KWh/30KWh)\n• Sistem ATS (Automatic Transfer Switch)\n• Spesifikasi teknikal & ciri-ciri\n• Panduan harga & pemasangan\n\n💬 Cuba tanya:\n• "15kVA" atau "30kVA" untuk detail generator\n• "power bank" untuk sistem bateri\n• "ATS" untuk maklumat suis pemindahan\n• "bandingkan 15kVA vs 30kVA"\n\nApa yang anda ingin tahu? 😊';
        break;
      case 'zh':
        welcomeMessage =
            '你好 $userName! 👋 我是您的Mega Genset Malaysia助手，由DeepSeek AI提供支持。\n\n🤖 我可以帮助您：\n• 发电机型号（15KVA - 500KVA）\n• 电源银行系统（10KW，配备20KWh/30KWh）\n• ATS（自动转换开关）系统\n• 技术规格和功能\n• 定价和安装指导\n\n💬 尝试询问：\n• "15kVA" 或 "30kVA" 以获取发电机详情\n• "power bank" 以获取电池系统信息\n• "ATS" 以获取转换开关信息\n• "比较15kVA vs 30kVA"\n\n您想了解什么？😊';
        break;
      default:
        welcomeMessage =
            'Hello $userName! 👋 I\'m your Mega Genset Malaysia Assistant powered by DeepSeek AI.\n\n🤖 I can help you with:\n• Generator models (15KVA - 500KVA)\n• Power bank systems (10KW with 20KWh/30KWh)\n• ATS (Automatic Transfer Switch) systems\n• Technical specifications & features\n• Pricing & installation guidance\n\n💬 Try asking:\n• "15kVA" or "30kVA" for generator details\n• "power bank" for battery systems\n• "ATS" for transfer switch info\n• "compare 15kVA vs 30kVA"\n\nWhat would you like to know? 😊';
    }
    _addMessage(welcomeMessage, false);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String userMessage = _controller.text.trim();
      _addMessage(userMessage, true);
      _controller.clear();

      // Show global chat shortcut on all pages after first message
      main_app.HomePage.showChatShortcut();

      setState(() {
        _showHomeShortcut = true; // Show home shortcut after sending first message
      }); // 刷新按钮状态

      // Auto-detect language from user message
      String detectedLanguage = _detectLanguage(userMessage);
      if (detectedLanguage != _currentLanguage) {
        print("DEBUG: Auto-detected language change from $_currentLanguage to $detectedLanguage");
        setState(() {
          _currentLanguage = detectedLanguage;
        });
        _updateTtsLanguage();

        // Show language change notification
        String notificationMessage;
        switch (detectedLanguage) {
          case 'ms':
            notificationMessage = 'Bahasa dikesan: Bahasa Malaysia';
            break;
          case 'zh':
            notificationMessage = '检测到语言：中文';
            break;
          default:
            notificationMessage = 'Language detected: English';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notificationMessage),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Show typing indicator
      _showTypingIndicator();

      // Add natural pause before generating response
      await Future.delayed(Duration(milliseconds: 800 + (userMessage.length * 10)));

      // Generate intelligent response
      Map<String, dynamic> responseData = await _generateIntelligentResponse(userMessage);

      // Remove typing indicator
      _removeTypingIndicator();

      // Add response with natural typing effect and image
      _addMessageWithTypingEffect(responseData['text'], false, responseData['image']);
    }
  }

  Future<void> _startListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        _showErrorSnackBar('Speech recognition error: ${error.errorMsg}');
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _controller.text = result.recognizedWords;
            setState(() => _isListening = false);
          }
        },
        localeId: _getLocaleId(),
      );
    } else {
      _showErrorSnackBar('Speech recognition not available');
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speakMessage(String message) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(message);

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  String _getLocaleId() {
    switch (_currentLanguage) {
      case 'ms':
        return 'ms_MY';
      case 'zh':
        return 'zh_CN';
      default:
        return 'en_US';
    }
  }

  String _getLocalizedHintText() {
    switch (_currentLanguage) {
      case 'ms':
        return 'Tanya tentang generator, ATS, pemantauan...';
      case 'zh':
        return '询问发电机、ATS、监控...';
      default:
        return 'Ask about generators, ATS, monitoring...';
    }
  }

  Future<void> _updateTtsLanguage() async {
    String languageCode;
    switch (_currentLanguage) {
      case 'ms':
        languageCode = 'ms-MY';
        break;
      case 'zh':
        languageCode = 'zh-CN';
        break;
      default:
        languageCode = 'en-US';
    }
    await _flutterTts.setLanguage(languageCode);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showTypingIndicator() {
    setState(() {
      _messages.add(ChatMessage(
        text: '...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeTypingIndicator() {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.text == '...') {
        _messages.removeLast();
      }
    });
  }

  Future<Map<String, dynamic>> _generateIntelligentResponse(String userMessage) async {
    print("DEBUG: Current language set to: $_currentLanguage");
    print("DEBUG: User message: $userMessage");

    String? imagePath;
    List<String> detectedErrorCodes = [];
    String detectedIntent = 'general_inquiry';

    // Simple response generation based on keywords
    String response = _generateSimpleResponse(userMessage);

    // Check if user is asking about a specific generator to include image
    String lowerMessage = userMessage.toLowerCase();
    List<String> gensetMatches = [];

    // Check for each genset type
    if (lowerMessage.contains('15kva') || lowerMessage.contains('15 kw')) {
      gensetMatches.add('15kva');
    }
    if (lowerMessage.contains('30kva') || lowerMessage.contains('30 kw')) {
      gensetMatches.add('30kva');
    }
    if (lowerMessage.contains('60kva') || lowerMessage.contains('60 kw')) {
      gensetMatches.add('60kva');
    }
    if (lowerMessage.contains('100kva') || lowerMessage.contains('100 kw')) {
      gensetMatches.add('100kva');
    }
    if (lowerMessage.contains('150kva') || lowerMessage.contains('150 kw') ||
        lowerMessage.contains('160kva') || lowerMessage.contains('160 kw')) {
      gensetMatches.add('160kva');
    }
    if (lowerMessage.contains('250kva') || lowerMessage.contains('250 kw')) {
      gensetMatches.add('250kva');
    }
    if (lowerMessage.contains('350kva') || lowerMessage.contains('350 kw')) {
      gensetMatches.add('350kva');
    }
    if (lowerMessage.contains('500kva') || lowerMessage.contains('500 kw')) {
      gensetMatches.add('500kva');
    }
    if (lowerMessage.contains('power bank') || lowerMessage.contains('battery')) {
      gensetMatches.add('powerbank');
    }

    // Only show image if exactly ONE genset type is mentioned
    if (gensetMatches.length == 1) {
      String gensetType = gensetMatches[0];
      switch (gensetType) {
        case '15kva':
          imagePath = 'assets/images/15KVA MGM GENERATOR_image.png';
          break;
        case '30kva':
          if (lowerMessage.contains('isuzu')) {
            imagePath = 'assets/images/30KVA ISUZU_image.png';
          } else if (lowerMessage.contains('compact')) {
            imagePath = 'assets/images/30KVA  MGM COMPACT GENERATOR_image.png';
          } else if (lowerMessage.contains('mark 15')) {
            imagePath = 'assets/images/30KVA MGM GENERATOR MARK 15_image.png';
          } else {
            imagePath = 'assets/images/30KVA MGM GENERATOR_image.png';
          }
          break;
        case '60kva':
          imagePath = 'assets/images/60KVA MGM GENERATOR_image.png';
          break;
        case '100kva':
          imagePath = 'assets/images/100KVA MGM GENERATOR_image.png';
          break;
        case '160kva':
          imagePath = 'assets/images/160KVA MGM GENERATOR_image.png';
          break;
        case '250kva':
          imagePath = 'assets/images/250KVA MGM Generator_image.png';
          break;
        case '350kva':
          imagePath = 'assets/images/350kva MGM GENERATOR_image.png';
          break;
        case '500kva':
          imagePath = 'assets/images/500KVA MGM GENERATOR_image.png';
          break;
        case 'powerbank':
          if (lowerMessage.contains('20kwh') || lowerMessage.contains('20 kwh')) {
            imagePath = 'assets/images/10KW MGM PWR BNK WITH 20KWH BATTERY(BATTERY)_image.png';
          } else if (lowerMessage.contains('30kwh') || lowerMessage.contains('30 kwh')) {
            imagePath = 'assets/images/10KW MGM PWR BNK WITH 30KWh BATTERY(V2)(BATTERY)_image.png';
          } else {
            imagePath = 'assets/images/10KW MGM PWR BNK WITH 20KWH BATTERY(BATTERY)_image.png';
          }
          break;
      }
    }

    // Add natural follow-up questions for technician-like behavior
    String enhancedResponse = _addTechnicianFollowUp(response, userMessage, _currentLanguage);

    // Chat interaction logging removed - now using Airtable for data management

    return {'text': enhancedResponse, 'image': imagePath};
  }

  String _addTechnicianFollowUp(String response, String userMessage, String language) {
    String lowerMessage = userMessage.toLowerCase();
    String lowerResponse = response.toLowerCase();

    // Don't add follow-up if response already has questions or is very short
    if (response.contains('?') || response.length < 100) {
      return response;
    }

    // Add technician-like follow-up questions based on context
    String followUp = '';

    if (language == 'ms') {
      // Troubleshooting follow-ups
      if (lowerResponse.contains('masalah') || lowerResponse.contains('troubleshoot') ||
          lowerResponse.contains('tidak hidup') || lowerResponse.contains('tiada output')) {
        followUp = '\n\n👨‍🔧 *Sebagai juruteknik, saya perlu tahu lebih lanjut:*\n' +
                   '• Generator masih hidup sekarang?\n' +
                   '• Bilakah masalah ini bermula?\n' +
                   '• Adakah lampu amaran menyala?\n' +
                   '• Anda sudah cuba penyelesaian apa?';
      }
      // Product inquiry follow-ups
      else if (lowerResponse.contains('generator') || lowerResponse.contains('spesifikasi') ||
               lowerResponse.contains('model') || lowerResponse.contains('kva')) {
        followUp = '\n\n🤔 *Untuk membantu anda lebih baik:*\n' +
                   '• Anda perlukan untuk aplikasi apa?\n' +
                   '• Berapa jam penggunaan sehari?\n' +
                   '• Adakah ada keperluan khas?';
      }
      // Pricing follow-ups
      else if (lowerResponse.contains('harga') || lowerResponse.contains('kos') ||
               lowerResponse.contains('quotation')) {
        followUp = '\n\n💰 *Untuk sebut harga yang tepat:*\n' +
                   '• Kuantiti yang diperlukan?\n' +
                   '• Lokasi penghantaran?\n' +
                   '• Adakah termasuk pemasangan?';
      }
      // General empathetic follow-up
      else {
        followUp = '\n\n😊 *Saya di sini untuk bantu!* Jika ada lagi soalan tentang generator atau sistem kuasa, jangan segan bertanya. Pengalaman saya sebagai juruteknik sedia membantu! 🔧';
      }
    } else if (language == 'zh') {
      // Troubleshooting follow-ups
      if (lowerResponse.contains('故障') || lowerResponse.contains('问题') ||
          lowerResponse.contains('无法启动') || lowerResponse.contains('无输出')) {
        followUp = '\n\n👨‍🔧 *作为技师，我需要了解更多信息：*\n' +
                   '• 发电机现在还在运行吗？\n' +
                   '• 这个问题什么时候开始的？\n' +
                   '• 是否有警告灯亮起？\n' +
                   '• 您已经尝试过什么解决方案？';
      }
      // Product inquiry follow-ups
      else if (lowerResponse.contains('发电机') || lowerResponse.contains('规格') ||
               lowerResponse.contains('型号') || lowerResponse.contains('kva')) {
        followUp = '\n\n🤔 *为了更好地帮助您：*\n' +
                   '• 您需要用于什么应用？\n' +
                   '• 每天使用多少小时？\n' +
                   '• 是否有特殊要求？';
      }
      // Pricing follow-ups
      else if (lowerResponse.contains('价格') || lowerResponse.contains('成本') ||
               lowerResponse.contains('报价')) {
        followUp = '\n\n💰 *为了准确报价：*\n' +
                   '• 需要多少数量？\n' +
                   '• 送货地点？\n' +
                   '• 是否包括安装？';
      }
      // General empathetic follow-up
      else {
        followUp = '\n\n😊 *我在这里帮助您！* 如果您对发电机或电力系统有更多问题，请随时询问。我作为技师的经验随时为您服务！🔧';
      }
    } else {
      // Troubleshooting follow-ups
      if (lowerResponse.contains('problem') || lowerResponse.contains('troubleshoot') ||
          lowerResponse.contains('won\'t start') || lowerResponse.contains('no output')) {
        followUp = '\n\n👨‍🔧 *As a technician, I need to know more:*\n' +
                   '• Is the generator still running now?\n' +
                   '• When did this problem start?\n' +
                   '• Are any warning lights on?\n' +
                   '• What solutions have you tried already?';
      }
      // Product inquiry follow-ups
      else if (lowerResponse.contains('generator') || lowerResponse.contains('specification') ||
               lowerResponse.contains('model') || lowerResponse.contains('kva')) {
        followUp = '\n\n🤔 *To help you better:*\n' +
                   '• What application do you need it for?\n' +
                   '• How many hours of daily usage?\n' +
                   '• Any special requirements?';
      }
      // Pricing follow-ups
      else if (lowerResponse.contains('price') || lowerResponse.contains('cost') ||
               lowerResponse.contains('quotation')) {
        followUp = '\n\n💰 *For accurate pricing:*\n' +
                   '• How many units do you need?\n' +
                   '• What\'s the delivery location?\n' +
                   '• Does it include installation?';
      }
      // General empathetic follow-up
      else {
        followUp = '\n\n😊 *I\'m here to help!* If you have any more questions about generators or power systems, don\'\'t hesitate to ask. My experience as a technician is always here to assist! 🔧';
      }
    }

    return response + followUp;
  }

  String _detectLanguage(String message) {
    if (message.trim().isEmpty) return _currentLanguage;

    String lowerMessage = message.toLowerCase();

    // Malay language indicators
    List<String> malayWords = [
      'saya', 'anda', 'kami', 'mereka', 'apa', 'bagaimana', 'kenapa', 'di mana',
      'generator', 'masalah', 'tidak', 'boleh', 'nak', 'mahu', 'perlu', 'ada',
      'yang', 'dan', 'atau', 'dengan', 'untuk', 'daripada', 'pada', 'dalam',
      'sudah', 'belum', 'akan', 'telah', 'sedang', 'lagi', 'juga', 'sangat',
      'banyak', 'sedikit', 'besar', 'kecil', 'panas', 'sejuk', 'baik', 'buruk',
      'harga', 'kos', 'beli', 'jual', 'cuba', 'buat', 'guna', 'jalan', 'kerja'
    ];

    // Chinese language indicators (simplified characters)
    List<String> chineseChars = [
      '的', '是', '在', '有', '和', '我', '你', '他', '她', '它', '这', '那',
      '一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
      '不', '了', '吗', '呢', '啊', '哦', '嗯', '哈', '嘿', '呀',
      '发电机', '问题', '可以', '需要', '没有', '什么', '怎么', '为什么', '哪里',
      '价格', '成本', '购买', '销售', '尝试', '做', '使用', '运行', '工作'
    ];

    // Count Malay words
    int malayCount = 0;
    for (String word in malayWords) {
      if (lowerMessage.contains(word)) {
        malayCount++;
      }
    }

    // Count Chinese characters
    int chineseCount = 0;
    for (String char in chineseChars) {
      if (message.contains(char)) {
        chineseCount++;
      }
    }

    // Additional Malay detection - common Malay sentence patterns
    bool hasMalayPatterns = lowerMessage.contains('tak ') ||
                           lowerMessage.contains(' nak ') ||
                           lowerMessage.contains(' boleh ') ||
                           lowerMessage.contains(' ada ') ||
                           lowerMessage.contains(' untuk ') ||
                           lowerMessage.contains(' dengan ') ||
                           lowerMessage.contains(' dari ') ||
                           lowerMessage.contains(' ke ') ||
                           lowerMessage.contains(' di ') ||
                           lowerMessage.contains(' yang ') ||
                           lowerMessage.contains(' dan ') ||
                           (lowerMessage.contains('saya') && lowerMessage.contains('anda'));

    // Additional Chinese detection - common Chinese patterns
    bool hasChinesePatterns = message.contains('吗') ||
                             message.contains('呢') ||
                             message.contains('的') ||
                             message.contains('了') ||
                             message.contains('我') ||
                             message.contains('你') ||
                             message.contains('是') ||
                             message.contains('在') ||
                             message.contains('有');

    // Language detection logic
    if (chineseCount > malayCount && (chineseCount >= 2 || hasChinesePatterns)) {
      return 'zh'; // Chinese
    } else if (malayCount > chineseCount && (malayCount >= 3 || hasMalayPatterns)) {
      return 'ms'; // Malay
    } else {
      return 'en'; // Default to English
    }
  }

  void _addMessageWithTypingEffect(String text, bool isUser, [String? image]) async {
    if (isUser) {
      _addMessage(text, isUser);
      return;
    }

    // Simulate typing effect for bot responses
    List<String> words = text.split(' ');
    String currentText = '';

    for (int i = 0; i < words.length; i++) {
      currentText += (i > 0 ? ' ' : '') + words[i];

      // Update message in place for typing effect
      setState(() {
        if (_messages.isEmpty || _messages.last.isUser) {
          _messages.add(ChatMessage(
            text: currentText,
            isUser: isUser,
            timestamp: DateTime.now(),
            image: image,
          ));
        } else {
          _messages.last = ChatMessage(
            text: currentText,
            isUser: isUser,
            timestamp: _messages.last.timestamp,
            image: image,
          );
        }
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });

      // Variable typing speed for natural effect
      int delay = 30 + (words[i].length * 2);
      if (words[i].contains('.') || words[i].contains('?') || words[i].contains('!')) {
        delay += 200; // Pause at sentence endings
      }
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showHomeShortcut ? FloatingActionButton(
        onPressed: () {
          // Navigate back to home page (first tab in bottom navigation)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePageWidget()),
            (route) => false,
          );
        },
        backgroundColor: const Color(0xFF1E3A8A), // Primary blue
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Back to Home',
      ) : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Dark blue
              Color(0xFF3B82F6), // Medium blue
              Color(0xFF60A5FA), // Light blue
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom App Bar with gradient
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E40AF), // Darker blue
                    Color(0xFF2563EB), // Medium blue
                    Color(0xFF3B82F6), // Lighter blue
                  ],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AppBar(
                title: const Text(
                  'Genset Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  // Language Selector
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: DropdownButton<String>(
                      value: _currentLanguage,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFFFFF)),
                      underline: Container(),
                      dropdownColor: const Color(0xFF1E40AF),
                      style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
                      onChanged: _onLanguageChanged,
                      items: _languageNames.entries.map<DropdownMenuItem<String>>((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                ),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
            ),
            // Input area with gradient background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1E40AF).withOpacity(0.8),
                    const Color(0xFF1E40AF).withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                        decoration: InputDecoration(
                          hintText: _getLocalizedHintText(),
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}), // 刷新按钮状态
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _controller.text.isEmpty
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFFFFD700), // Gold
                          _controller.text.isEmpty
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFFFA500), // Orange
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _controller.text.isEmpty ? Icons.mic : Icons.send,
                        color: _controller.text.isEmpty ? Colors.white : const Color(0xFF1E40AF),
                        size: 20,
                      ),
                      onPressed: () {
                        if (_controller.text.isEmpty) {
                          _startListening();
                        } else {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateSimpleResponse(String userMessage) {
    String lowerMessage = userMessage.toLowerCase();

    // Simple keyword-based responses
    if (lowerMessage.contains('15kva') || lowerMessage.contains('15 kw')) {
      return 'The 15KVA MGM Generator is perfect for small to medium applications. It features:\n• 15KVA / 12KW output capacity\n• Diesel engine with excellent fuel efficiency\n• Compact design for easy installation\n• Comprehensive protection systems\n• Low maintenance requirements\n\nContact us for pricing and availability!';
    }

    if (lowerMessage.contains('30kva') || lowerMessage.contains('30 kw')) {
      return 'The 30KVA MGM Generator offers reliable power for larger applications:\n• 30KVA / 24KW output capacity\n• Multiple engine options (Perkins, Isuzu, MGM)\n• Advanced digital control panel\n• Automatic voltage regulation\n• Suitable for commercial and industrial use\n\nWe have different models available. Which type interests you?';
    }

    if (lowerMessage.contains('power bank') || lowerMessage.contains('battery')) {
      return 'Our Power Bank systems provide reliable energy storage:\n• 10KW inverter capacity\n• 20KWh or 30KWh battery options\n• Lithium-ion technology for long life\n• Multiple protection features\n• Scalable for larger installations\n\nPerfect for solar integration and backup power!';
    }

    if (lowerMessage.contains('ats') || lowerMessage.contains('transfer switch')) {
      return 'Automatic Transfer Switches (ATS) ensure seamless power transfer:\n• Automatic switching between mains and generator\n• Multiple amperage options available\n• Manual override capability\n• Status monitoring and alarms\n• Complies with international standards\n\nEssential for critical power applications!';
    }

    if (lowerMessage.contains('price') || lowerMessage.contains('cost') || lowerMessage.contains('quotation')) {
      return 'For accurate pricing, please provide:\n• Specific model requirements\n• Quantity needed\n• Delivery location\n• Installation requirements\n• Any special customizations\n\nWe offer competitive pricing and can provide detailed quotations. Contact our sales team!';
    }

    if (lowerMessage.contains('maintenance') || lowerMessage.contains('service')) {
      return 'Regular maintenance is crucial for generator reliability:\n• Monthly visual inspections\n• Quarterly oil and filter changes\n• Annual comprehensive servicing\n• Load bank testing\n• Software updates\n\nWe offer comprehensive maintenance contracts!';
    }

    // Default response
    return 'I\'m here to help with information about MGM generators, power systems, and related equipment. You can ask me about:\n\n• Generator specifications (15KVA to 500KVA)\n• Power bank and battery systems\n• ATS (Automatic Transfer Switches)\n• Pricing and quotations\n• Maintenance and servicing\n• Technical support\n\nWhat would you like to know more about?';
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFD4AF37) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image if available
            if (message.image != null && message.image!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    message.image!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Color(0xFFB3B3B3),
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Display text
            Text(
              message.text,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple message model for chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? image;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.image,
  });
}
