import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/deepseek_service.dart';

class OpenAISettingsPage extends StatefulWidget {
  const OpenAISettingsPage({super.key});

  @override
  State<OpenAISettingsPage> createState() => _OpenAISettingsPageState();
}

class _OpenAISettingsPageState extends State<OpenAISettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;
  String _statusMessage = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedKey = prefs.getString('openai_api_key');
      
      setState(() {
        if (savedKey != null && savedKey.isNotEmpty) {
          _apiKeyController.text = savedKey;
          _isConnected = DeepSeekService.isAvailable;
          _statusMessage = _isConnected ? 'Connected to DeepSeek AI' : 'API key saved but not connected';
        } else {
          _statusMessage = 'No API key configured';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading settings: $e';
      });
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showStatusMessage('Please enter an API key first', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
    });

    try {
      // Set the API key
      await DeepSeekService.setAPIKey(_apiKeyController.text.trim());

      // Test the connection with a simple request
      String testResponse = await DeepSeekService.generateIntelligentResponse(
        'Hello, can you respond with just "Connection successful"?',
        language: 'en',
      );
      
      if (testResponse.toLowerCase().contains('connection') || testResponse.toLowerCase().contains('successful')) {
        setState(() {
          _isConnected = true;
          _statusMessage = '✅ Connection successful! DeepSeek AI is now active.';
        });
      } else {
        setState(() {
          _isConnected = false;
          _statusMessage = '⚠️ Connection test unclear. API key may be working.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = '❌ Connection failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showStatusMessage('Please enter an API key', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Saving settings...';
    });

    try {
      await DeepSeekService.setAPIKey(_apiKeyController.text.trim());
      setState(() {
        _statusMessage = '✅ API key saved successfully!';
      });
      
      // Test connection after saving
      await _testConnection();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error saving settings: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSettings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing settings...';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('openai_api_key');
      
      setState(() {
        _apiKeyController.clear();
        _isConnected = false;
        _statusMessage = 'Settings cleared. Chatbot will use fallback mode.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing settings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showStatusMessage(String message, bool isSuccess) {
    setState(() {
      _statusMessage = message;
    });
    
    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🤖 DeepSeek AI Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7B1FA2),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isConnected ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.check_circle : Icons.info,
                        color: _isConnected ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DeepSeek AI Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // API Key Input
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DeepSeek API Key',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your DeepSeek API key to enable intelligent responses. Your key will be stored securely on your device.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        hintText: 'sk-...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isObscured ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (_apiKeyController.text.trim().isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.vpn_key),
                  label: Text(_isLoading ? 'Testing...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSettings,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save API Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _clearSettings,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📚 How to Get Your API Key',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Visit https://platform.openai.com\n'
                      '2. Sign up or log in to your account\n'
                      '3. Navigate to API Keys section\n'
                      '4. Create a new API key\n'
                      '5. Copy and paste the key here',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your API key is stored locally and never shared with third parties.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Features Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✨ DeepSeek AI Features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('🧠 Natural language understanding'),
                    _buildFeatureItem('📚 Context-aware responses'),
                    _buildFeatureItem('🔍 Intelligent product recommendations'),
                    _buildFeatureItem('💬 Conversational memory'),
                    _buildFeatureItem('🌐 Multi-language support'),
                    _buildFeatureItem('⚡ Fallback to knowledge base if unavailable'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
