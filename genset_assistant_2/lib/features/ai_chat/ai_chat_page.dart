import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../services/knowledge_base_service.dart';
import '../../services/wordpress_service.dart' as deepseek_service;

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
    _initializeVoiceFeatures();
  }

  Future<void> _initializeChat() async {
    await KnowledgeBaseService.loadKnowledgeBase();
    await deepseek_service.DeepSeekService.initialize(); // Initialize DeepSeek service
    setState(() {
      _isLoading = false;
    });
    _addWelcomeMessage();

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _addMessage(widget.initialMessage!, true);
      String response = await deepseek_service.DeepSeekService.generateIntelligentResponse(
        widget.initialMessage!,
        language: _currentLanguage,
      );
      _addMessage(response, false);
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
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

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
      setState(() {}); // 刷新按钮状态

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

    // Check if user is asking about a specific generator to include image
    String lowerMessage = userMessage.toLowerCase();
    if (lowerMessage.contains('15kva') || lowerMessage.contains('15 kw')) {
      imagePath = 'assets/images/15KVA MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('30kva') || lowerMessage.contains('30 kw')) {
      if (lowerMessage.contains('isuzu')) {
        imagePath = 'assets/images/30KVA ISUZU_image.png';
      } else if (lowerMessage.contains('compact')) {
        imagePath = 'assets/images/30KVA  MGM COMPACT GENERATOR_image.png';
      } else if (lowerMessage.contains('mark 15')) {
        imagePath = 'assets/images/30KVA MGM GENERATOR MARK 15_image.png';
      } else {
        imagePath = 'assets/images/30KVA MGM GENERATOR_image.png';
      }
    } else if (lowerMessage.contains('60kva') || lowerMessage.contains('60 kw')) {
      imagePath = 'assets/images/60KVA MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('100kva') || lowerMessage.contains('100 kw')) {
      imagePath = 'assets/images/100KVA MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('150kva') || lowerMessage.contains('150 kw')) {
      imagePath = 'assets/images/160KVA MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('160kva') || lowerMessage.contains('160 kw')) {
      imagePath = 'assets/images/160KVA MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('250kva') || lowerMessage.contains('250 kw')) {
      imagePath = 'assets/images/250KVA MGM Generator_image.png';
    } else if (lowerMessage.contains('350kva') || lowerMessage.contains('350 kw')) {
      imagePath = 'assets/images/350kva MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('500kva') || lowerMessage.contains('500 kw')) {
      imagePath = 'assets/images/500KVA MGM GENERATOR_image.png';
    } else if (lowerMessage.contains('power bank') || lowerMessage.contains('battery')) {
      if (lowerMessage.contains('20kwh') || lowerMessage.contains('20 kwh')) {
        imagePath = 'assets/images/10KW MGM PWR BNK WITH 20KWH BATTERY(BATTERY)_image.png';
      } else if (lowerMessage.contains('30kwh') || lowerMessage.contains('30 kwh')) {
        imagePath = 'assets/images/10KW MGM PWR BNK WITH 30KWH BATTERY(V2)(BATTERY)_image.png';
      } else {
        imagePath = 'assets/images/10KW MGM PWR BNK WITH 20KWH BATTERY(BATTERY)_image.png';
      }
    }

    // Use DeepSeek service for intelligent responses with fallback to knowledge base
    try {
      print("DEBUG: Calling DeepSeek service with language: $_currentLanguage");
      String response = await deepseek_service.DeepSeekService.generateIntelligentResponse(
        userMessage,
        language: _currentLanguage,
      );
      print("DEBUG: DeepSeek response received: ${response.substring(0, 100)}...");
      return {'text': response, 'image': imagePath};
    } catch (e) {
      print("Error using DeepSeek service, falling back to knowledge base: $e");
      // Fallback to knowledge base service
      print("DEBUG: Falling back to KnowledgeBase service with language: $_currentLanguage");
      String response = await KnowledgeBaseService.generateIntelligentResponse(
        userMessage,
        language: _currentLanguage,
        conversationHistory: _messages.where((m) => m.text != '...').toList(),
      );
      print("DEBUG: KnowledgeBase response received: ${response.substring(0, 100)}...");
      return {'text': response, 'image': imagePath};
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
      appBar: AppBar(
        title: const Text(
          'Genset Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          // Language Selector
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _currentLanguage,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: Container(),
              dropdownColor: Colors.blue,
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
            // 输入区
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _getLocalizedHintText(),
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
                      color: _controller.text.isEmpty
                          ? Colors.grey.shade100
                          : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _controller.text.isEmpty ? Icons.mic : Icons.send,
                        color: _controller.text.isEmpty ? Colors.grey : Colors.white,
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

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
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
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
