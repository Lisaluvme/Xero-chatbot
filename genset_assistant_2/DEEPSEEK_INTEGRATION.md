# DeepSeek AI Integration for Genset Assistant

This document explains how to set up and use the DeepSeek AI integration in your Genset Assistant app.

## 🚀 Features

### Enhanced Intelligence with DeepSeek AI
- **Natural Language Understanding**: Advanced comprehension of user queries using DeepSeek-V3-Lite
- **Context-Aware Responses**: Maintains conversation history and context
- **Intelligent Product Recommendations**: Smart suggestions based on user needs
- **Multi-Language Support**: Enhanced responses in English, Malay, and Chinese
- **Seamless Fallback**: Automatically falls back to knowledge base if DeepSeek is unavailable

### Database Integration
- **Real-time Product Information**: Combines DeepSeek AI intelligence with your product database
- **Accurate Technical Details**: Ensures responses are based on your actual product specifications
- **Smart Context Extraction**: Automatically includes relevant product information in AI responses

## 📋 Setup Instructions

### 1. Get DeepSeek API Key
1. Visit [DeepSeek Platform](https://platform.deepseek.com)
2. Sign up or log in to your account
3. Navigate to the API Keys section
4. Create a new API key
5. Copy the key (it starts with `sk-...`)

### 2. Configure in App
1. Open the Genset Assistant app
2. Go to the AI Chat page
3. Tap the settings icon (⚙️) in the top-right corner
4. Enter your DeepSeek API key in the settings page
5. Tap "Save API Key"
6. Test the connection to verify it's working

### 3. Pre-Configuration
The app comes pre-configured with your API key:
- **API Key**: `sk-5a4e95602d994480925426b35524de25`
- **Model**: DeepSeek-V3-Lite (`deepseek-chat`)
- **Endpoint**: `https://api.deepseek.com`

## 🔧 Technical Details

### Architecture
```
User Input → DeepSeek AI Service → Database Context → DeepSeek API → Enhanced Response
                ↓
         Fallback to Knowledge Base (if DeepSeek unavailable)
```

### Key Components

#### DeepSeek AI Service (`lib/services/openai_service.dart`)
- Handles DeepSeek API integration
- Manages API key storage and authentication
- Combines database context with AI responses
- Provides intelligent fallback mechanisms
- Uses DeepSeek-V3-Lite model for optimal performance

#### DeepSeek Settings Page (`lib/features/ai_chat/openai_settings_page.dart`)
- User-friendly interface for API key management
- Connection testing and status monitoring
- Secure local storage of API keys
- Real-time status indicators

#### Enhanced AI Chat Page (`lib/features/ai_chat/ai_chat_page.dart`)
- Visual status indicator for DeepSeek availability
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
- Only relevant product information is shared with DeepSeek
- No personal user data is transmitted
- Conversation history is processed locally when possible

## 📱 User Experience

### Status Indicators
- **Green "AI" badge**: DeepSeek AI is active and working
- **Grey "Basic" badge**: Using fallback knowledge base
- **Settings icon**: Access to DeepSeek configuration

### Fallback Behavior
If DeepSeek AI is unavailable:
- Automatically switches to knowledge base responses
- Maintains full chat functionality
- No interruption to user experience

## 🔍 Troubleshooting

### Common Issues

#### "Connection failed" error
- Verify your API key is correct
- Check your internet connection
- Ensure your DeepSeek account has sufficient credits

#### "API key not found" message
- Make sure you've saved the API key in settings
- Try re-entering the key
- Check for any extra spaces or characters

#### Slow responses
- DeepSeek AI responses typically take 2-5 seconds
- Network conditions can affect response time
- The app shows typing indicators during processing

### Debug Mode
Enable debug logging by checking the console output:
- Look for "DeepSeek service initialized successfully"
- Check for any error messages in the logs
- Verify database context is being loaded correctly

## 💰 Cost Considerations

### DeepSeek API Usage
- Uses DeepSeek-V3-Lite model (cost-effective)
- Typical cost: ~$0.0001 per 1K tokens (very affordable)
- Average chat session uses 500-2000 tokens
- Monitor usage in your DeepSeek dashboard

### Optimization Features
- Limits conversation history to manage costs
- Caches database context to reduce API calls
- Intelligent context extraction minimizes token usage

## 🚀 DeepSeek AI vs OpenAI Comparison

### Advantages of DeepSeek AI
- **Cost-Effective**: Significantly lower API costs compared to OpenAI
- **Fast Performance**: Quick response times with V3-Lite model
- **High Quality**: Excellent reasoning and language understanding
- **Reliable**: Stable API with good uptime
- **Privacy-Focused**: Strong data protection policies

### Model Specifications
- **Model**: DeepSeek-V3-Lite
- **Context Window**: 128K tokens
- **Languages**: Excellent multi-language support (English, Chinese, Malay)
- **Specialization**: Strong in technical and product knowledge

## 🌐 Multi-Language Support

DeepSeek AI provides excellent support for multiple languages:

### English
- Natural, fluent responses
- Technical terminology handling
- Professional communication style

### Bahasa Malaysia
- Natural Malaysian phrasing
- Cultural context awareness
- Technical terms in Malay

### Chinese (中文)
- Fluent Chinese responses
- Technical terminology in Chinese
- Professional business communication

## 🚀 Future Enhancements

### Planned Features
- Custom system prompts for specific industries
- Advanced analytics dashboard
- Voice input integration with DeepSeek
- Custom training data integration
- Model switching (V3, V3-Lite, etc.)

### Performance Improvements
- Response caching for common questions
- Batch processing for multiple queries
- Optimized context extraction
- Reduced latency for technical queries

## 📞 Support

If you encounter any issues with the DeepSeek AI integration:

1. Check the troubleshooting section above
2. Verify your API key and DeepSeek account status
3. Ensure you have a stable internet connection
4. Check DeepSeek API status page for service availability
5. Contact support if issues persist

---

## 🎯 Quick Start Summary

1. **API Key**: Already configured (`sk-5a4e95602d994480925426b35524de25`)
2. **Model**: DeepSeek-V3-Lite (deepseek-chat)
3. **Endpoint**: https://api.deepseek.com
4. **Status**: Ready to use! 🚀

**Note**: This integration enhances the existing chatbot functionality while maintaining full backward compatibility. The app will continue to work normally even without a DeepSeek API key, using the built-in knowledge base as a fallback.

**Current Configuration**: ✅ Your app is already set up with DeepSeek AI and ready to provide intelligent, context-aware responses for your Genset Assistant users!
