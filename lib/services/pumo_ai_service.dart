import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pumo_ai_character.dart';
import '../models/pumo_chat_message.dart';
import '../constants/pumo_constants.dart';

class PumoAIService {
  static const String _apiKey = '81adb1eaf2f14a4280f3c139dd37dc8c.li46WnNUTi3kcQmw';
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  
  static Future<String> generateResponse({
    required AICharacter character,
    required List<ChatMessage> messages,
  }) async {
    try {
      final messagesForAPI = _prepareMessagesForAPI(character, messages);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': messagesForAPI,
          'max_tokens': 1000,
          'temperature': 0.7,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in generateResponse: $e');
      // 返回模拟响应用于演示
      return _getMockResponse(character, messages.last.content);
    }
  }

  static List<Map<String, String>> _prepareMessagesForAPI(
    AICharacter character,
    List<ChatMessage> messages,
  ) {
    final apiMessages = <Map<String, String>>[];
    
    // 添加系统提示，确保用英文回复
    apiMessages.add({
      'role': 'system',
      'content': '${character.systemPrompt}\n\nIMPORTANT: You must always respond in English, regardless of the language used by the user.',
    });
    
    // 添加对话历史
    for (final message in messages) {
      if (message.type == MessageType.user) {
        apiMessages.add({
          'role': 'user',
          'content': message.content,
        });
      } else if (message.type == MessageType.ai && !message.isTyping) {
        apiMessages.add({
          'role': 'assistant',
          'content': message.content,
        });
      }
    }
    
    return apiMessages;
  }

  static String _getMockResponse(AICharacter character, String userMessage) {
    // 模拟AI响应，基于角色个性，用英文回复
    final responses = [
      "Hello! That's an interesting question. As ${character.name}, I'd love to help you with that.",
      "Hi there! I understand what you're asking. Let me share my thoughts on this topic.",
      "Greetings! That's a great point you've raised. Here's my perspective as someone with a ${character.personality.toLowerCase()} personality.",
      "Hello! I'm glad you brought that up. Let me explain my thoughts on this matter.",
      "Hi! That's something I find fascinating too. Here's how I see it from my unique perspective.",
    ];
    
    final randomResponse = responses[DateTime.now().millisecond % responses.length];
    return randomResponse;
  }

  static String generateWelcomeMessage(AICharacter character) {
    // 根据角色个性生成欢迎消息
    final welcomeMessages = [
      "Hello! I'm ${character.name}. ${character.description} I'm excited to chat with you today!",
      "Hi there! Welcome to our conversation. I'm ${character.name}, and I'm here to help and chat with you.",
      "Greetings! I'm ${character.name}. With my ${character.personality.toLowerCase()} personality, I'm looking forward to our discussion.",
      "Hello and welcome! I'm ${character.name}. ${character.description} Let's have a great conversation!",
      "Hi! Nice to meet you. I'm ${character.name}, and I'm ready to assist and chat with you about anything you'd like.",
    ];
    
    final randomWelcome = welcomeMessages[DateTime.now().millisecond % welcomeMessages.length];
    return randomWelcome;
  }

  static Future<String> generateCharacterDescription({
    required String name,
    required String personality,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': PumoConstants.model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a creative assistant that helps create AI character descriptions.',
            },
            {
              'role': 'user',
              'content': 'Create a detailed description for an AI character named "$name" with personality: "$personality"',
            },
          ],
          'max_tokens': 200,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Failed to generate description: ${response.statusCode}');
      }
    } catch (e) {
      // 返回模拟描述
      return "A helpful AI assistant with a $personality personality, ready to chat and assist you with various topics.";
    }
  }

  static Future<String> generateSystemPrompt({
    required String name,
    required String personality,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': PumoConstants.model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a prompt engineer that creates system prompts for AI characters.',
            },
            {
              'role': 'user',
              'content': 'Create a system prompt for an AI character named "$name" with personality "$personality" and description "$description"',
            },
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Failed to generate system prompt: ${response.statusCode}');
      }
    } catch (e) {
      // 返回模拟系统提示
      return "You are $name, an AI assistant with a $personality personality. $description. Always stay in character and be helpful, friendly, and engaging in your responses.";
    }
  }
}
