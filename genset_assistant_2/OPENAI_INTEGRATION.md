# OpenAI Integration for Genset Assistant

This document explains how to set up and use the OpenAI integration in your Genset Assistant app.

## 🚀 Features

### Enhanced Intelligence with OpenAI
- **Natural Language Understanding**: Advanced comprehension of user queries
- **Context-Aware Responses**: Maintains conversation history and context
- **Intelligent Product Recommendations**: Smart suggestions based on user needs
- **Multi-Language Support**: Enhanced responses in English, Malay, and Chinese
- **Seamless Fallback**: Automatically falls back to knowledge base if OpenAI is unavailable

### Database Integration
- **Real-time Product Information**: Combines OpenAI intelligence with your product database
- **Accurate Technical Details**: Ensures responses are based on your actual product specifications
- **Smart Context Extraction**: Automatically includes relevant product information in AI responses

## 📋 Setup Instructions

### 1. Get OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com)
2. Sign up or log in to your account
3. Navigate to the API Keys section
4. Create a new API key
5. Copy the key (it starts with `sk-...`)

### 2. Configure in App
1. Open the Genset Assistant app
2. Go to the AI Chat page
3. Tap the settings icon (⚙️) in the top-right corner
4. Enter your OpenAI API key in the settings page
5. Tap "Save API Key"
6. Test the connection to verify it's working

### 3. Alternative: Manual Configuration
If you prefer to set the API key programmatically, you can modify the `OpenAIService` class:

```dart
// In lib/services/openai_service.dart
static Future<String?> _getAPIKey() async {
  // For demo purposes, you can set your API key here
  // In production, this should be stored securely
  return 'your-openai-api-key-here';
}
```

## 🔧 Technical Details

### Architecture
```
User Input → OpenAI Service → Database Context → OpenAI API → Enhanced Response
                ↓
         Fallback to Knowledge Base (if OpenAI unavailable)
```

### Key Components

#### OpenAIService (`lib/services/openai_service.dart`)
- Handles OpenAI API integration
- Manages API key storage and authentication
- Combines database context with AI responses
- Provides intelligent fallback mechanisms

#### OpenAI Settings Page (`lib/features/ai_chat/openai_settings_page.dart`)
- User-friendly interface for API key management
- Connection testing and status monitoring
- Secure local storage of API keys

#### Enhanced AI Chat Page (`lib/features/ai_chat/ai_chat_page.dart`)
- Visual status indicator for OpenAI availability
- Seamless integration with existing chat features
- Maintains all existing functionality

### Database Context Integration
The system automatically extracts relevant information from your knowledge base:

- **Generator Information**: Power ratings, specifications, applications
- **ATS Systems**: Categories, descriptions, models
- **AVS Systems**: Voltage stabilizers, specifications
- **Power Banks**: Capacity, applications
- **Oversight Modules**: Features, monitoring capabilities

## 🛡️ Security & Privacy

### API Key Storage
- API keys are stored locally using SharedPreferences
- Keys are never shared with third parties
- Secure storage on the user's device

### Data Privacy
- Only relevant product information is shared with OpenAI
- No personal user data is transmitted
- Conversation history is processed locally when possible

## 📱 User Experience

### Status Indicators
- **Green "AI" badge**: OpenAI is active and working
- **Grey "Basic" badge**: Using fallback knowledge base
- **Settings icon**: Access to OpenAI configuration

### Fallback Behavior
If OpenAI is unavailable:
- Automatically switches to knowledge base responses
- Maintains full chat functionality
- No interruption to user experience

## 🔍 Troubleshooting

### Common Issues

#### "Connection failed" error
- Verify your API key is correct
- Check your internet connection
- Ensure your OpenAI account has sufficient credits

#### "API key not found" message
- Make sure you've saved the API key in settings
- Try re-entering the key
- Check for any extra spaces or characters

#### Slow responses
- OpenAI responses may take 2-5 seconds
- Network conditions can affect response time
- The app shows typing indicators during processing

### Debug Mode
Enable debug logging by checking the console output:
- Look for "OpenAI service initialized successfully"
- Check for any error messages in the logs
- Verify database context is being loaded correctly

## 💰 Cost Considerations

### OpenAI API Usage
- Uses GPT-3.5-turbo model (cost-effective)
- Typical cost: ~$0.002 per 1K tokens
- Average chat session uses 500-2000 tokens
- Monitor usage in your OpenAI dashboard

### Optimization Features
- Limits conversation history to manage costs
- Caches database context to reduce API calls
- Intelligent context extraction minimizes token usage

## 🚀 Future Enhancements

### Planned Features
- Support for GPT-4 model
- Custom system prompts
- Advanced analytics dashboard
- Voice input integration with OpenAI
- Custom training data integration

### Performance Improvements
- Response caching
- Batch processing for multiple queries
- Optimized context extraction
- Reduced latency for common questions

## 📞 Support

If you encounter any issues with the OpenAI integration:

1. Check the troubleshooting section above
2. Verify your API key and OpenAI account status
3. Ensure you have a stable internet connection
4. Contact support if issues persist

---

**Note**: This integration enhances the existing chatbot functionality while maintaining full backward compatibility. The app will continue to work normally even without an OpenAI API key, using the built-in knowledge base as a fallback.
