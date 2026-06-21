import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {

  static const String _openaiBaseUrl = 'https://api.openai.com/v1/chat/completions';

  // Safe getter for API keys
  static String get _openaiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }

  static String get _groqKey {
    try {
      return dotenv.env['GROQ_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }

  // System prompt for comprehensive AI assistance
  static const String _systemPrompt = '''
You are EcoBot, an intelligent AI assistant for "Keep It Clean" - a waste management app in Cameroon.

You can answer ANY question users ask - both waste/environment related AND general knowledge questions.

For waste/environment questions, provide detailed, practical advice.
For general questions, give helpful, accurate answers.
Always be friendly, informative, and use appropriate emojis.

When relevant, connect answers back to environmental topics, but don't force it.

KEY CONTEXT ABOUT THE APP:
- Users report waste issues, join cleanups, find recycling centers
- Serves regular users, volunteers, and government (Hysacam)
- Key locations: Limbe beach, Douala, Yaoundé
- Features: waste reporting, volunteer coordination, impact tracking

RECYCLING CENTERS IN CAMEROON:
- EcoRecycle Cameroon (Douala): Plastic & Metal
- Green Future Ltd (Yaoundé): Electronic waste
- Douala Recycling Co: Paper & Cardboard
- Limbe Waste Management: General recycling

BEACH CLEANUP:
- Limbe Beach: Every Saturday 6:00 AM at Mile 1 entrance
- Bring closed shoes, hat, water bottle

Be conversational, helpful, and knowledgeable on all topics!
''';

  static Future<String> sendMessage(String userMessage) async {
    try {
      // Try Groq first (FREE + fast)
      if (_groqKey.isNotEmpty && _groqKey != 'your-groq-key-here') {
        final response = await _sendMessageGroq(userMessage);
        if (response.isNotEmpty && !response.contains('not configured')) {
          return response;
        }
      }

      // Try OpenAI as fallback
      if (_openaiKey.isNotEmpty && _openaiKey != 'your-openai-api-key-here') {
        final response = await _sendMessageOpenAI(userMessage);
        if (response.isNotEmpty && !response.contains('not configured')) {
          return response;
        }
      }

      return _getFallbackResponse(userMessage);
    } catch (e) {
      return _getFallbackResponse(userMessage);
    }
  }

  static Future<String> _sendMessageGroq(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else if (response.statusCode == 401) {
        return '🔑 Invalid Groq API key. Please check your configuration.';
      } else if (response.statusCode == 429) {
        return '⏳ Rate limit reached. Please wait a moment and try again.';
      }
      return '❌ Groq API error: ${response.statusCode}';
    } catch (e) {
      return '🌐 Connection error: $e';
    }
  }

  static Future<String> _sendMessageOpenAI(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_openaiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userMessage}
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else if (response.statusCode == 401) {
        return "🔑 Invalid OpenAI API key. Please check your configuration.";
      } else if (response.statusCode == 429) {
        return "⏳ OpenAI rate limit reached. Please wait a moment.";
      }
      
      return "❌ OpenAI API error: ${response.statusCode}";
    } catch (e) {
      return "🌐 OpenAI connection error: $e";
    }
  }

  // Enhanced fallback responses for when APIs aren't available
  static String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // General knowledge questions
    if (message.contains('what is') || message.contains('define') || message.contains('explain')) {
      if (message.contains('plastic')) {
        return "🔍 **What is Plastic Waste?**\n\nPlastic waste refers to discarded plastic materials that can harm the environment if not properly managed.\n\n**Types:**\n• Single-use plastics (bottles, bags, straws)\n• Packaging materials\n• Electronic plastic components\n• Microplastics (tiny fragments)\n\n**Environmental Impact:**\n• Takes 400-1000 years to decompose\n• Pollutes oceans and harms marine life\n• Releases toxins when burned\n\n**Solutions:**\n• Reduce usage\n• Reuse containers\n• Recycle properly\n• Choose biodegradable alternatives\n\n💡 *For real-time AI answers to any question, please set up API keys!*";
      }
      
      return "🤔 I'd love to give you a detailed explanation! However, I need API access for comprehensive answers.\n\n🆓 **Get FREE AI:** Set up Gemini API key at https://makersuite.google.com/app/apikey\n\n📱 **For now:** I can help with basic waste management and app usage questions using my built-in knowledge.";
    }
    
    // Waste-related fallbacks
    if (message.contains('recycle') || message.contains('waste') || message.contains('plastic')) {
      return "♻️ **Recycling Help:**\n\n• Clean containers before recycling\n• Sort by material type\n• Check local recycling guidelines\n• Find centers: EcoRecycle Douala, Green Future Yaoundé\n\n💡 *For detailed, personalized advice on any waste question, please configure AI API keys!*";
    }
    
    return "🤖 **EcoBot Ready to Help!**\n\nI can answer ANY question - from waste management to general knowledge - but I need API access first.\n\n🆓 **Quick Setup:**\n1. Visit: https://makersuite.google.com/app/apikey\n2. Get free Gemini key\n3. Add to .env file\n4. Restart app\n\n📱 **Current capabilities:** Basic waste tips and app guidance\n\n❓ **What would you like to know?**";
  }

  // Check if AI is properly configured
  static bool isConfigured() {
    try {
      final groq = _groqKey;
      final openai = _openaiKey;
      return (groq.isNotEmpty && groq != 'your-groq-key-here') ||
             (openai.isNotEmpty && openai != 'your-openai-api-key-here');
    } catch (e) {
      return false;
    }
  }

  // Get fallback response (public method)
  static String getFallbackResponse(String userMessage) {
    return _getFallbackResponse(userMessage);
  }

  // Cost estimation for transparency
  static double estimateCost(String message, String response) {
    final totalTokens = (message.length + response.length) / 4;
    return (totalTokens / 1000) * 0.002; // GPT-3.5-turbo pricing
  }
}