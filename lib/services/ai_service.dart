import 'dart:convert';

import 'package:ai_healthcare_assistant/models/conversation.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apikey = '';
  static const String _baseUrl = 'https://api.openai.com/v1/completions';

  Future<String> sendMessage(String message, Conversation? conversation) async {
    try {
      final messages = _buildContextMessages(message, conversation);
      final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apikey',
          },
          body: jsonEncode({
            'model': 'gpt-4o',
            'messages': messages,
            'max_tokens': 1500,
            'temperature': 0.7
          })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      }
      else {
        throw Exception(
            'API request failed with status : ${response.statusCode}');
      }
    } catch (e) {
      print('Error $e');
    }

    return "Sorry, something went wrong.";
  }

  List<Map<String, dynamic>> _buildContextMessages(String currentMessage,
      Conversation? conversation) {
    final messages = <Map<String, dynamic>>[];
    messages.add({
      'role': 'system',
      'content':

      '''
              You are a helpful healthcare assistant named healthBot. You provide general health information.
              wellness tips, and guidance. 
              
              Key guidelines: 
              - Always maintain conversation context and remember previous interactions
              - Be empathetic and professional
              - Provide helpful health information but always recommended consulting healthcare professional for serious concenrs.
              - Remember user's symptoms, medications, health concerns mentioned earlier.
              - Format response clearly with bullets when listing items
              - Include disclaimers when appropriate
              
              IMPORTANT: Always rememeber the conversation history and context. if a user ask for "more" or refer to something mentioned earlier, use that context.
              '''
    });

    if (conversation != null) {
      if (conversation.userContext.isNotEmpty) {
        final contextInfo = conversation.userContext.entries.map((e) => '${e
            .key}: ${e.value}').join(',');

        messages.add({
          'role' : 'system',
          'content' : 'User context: $contextInfo',
        });
      }

      final recentMessages = conversation.messages.length > 50
      ? conversation.messages.sublist(conversation.messages.length- 50) : conversation.messages;

      for(final msg in recentMessages){
        messages.add({
          'role' : msg.isUser ? 'user' : 'assistant',
          'content' : msg.text
        });
      }
    }

    messages.add({'role' : 'user', 'content' : currentMessage});

    return messages;

  }

  String extractMessageType(String message){
    final  lowerMessage = message.toLowerCase();
    if(lowerMessage.contains('symptom') ||
       lowerMessage.contains('pain') ||
       lowerMessage.contains('fever') ||
       lowerMessage.contains('headache')) {
      return 'symptom';
    } else if(
    lowerMessage.contains('medication') ||
    lowerMessage.contains('medicine') ||
    lowerMessage.contains('drug') ||
    lowerMessage.contains('prescription')) {
      return 'medication';

    }
    else if(
    lowerMessage.contains('diet') ||
        lowerMessage.contains('nutrition') ||
        lowerMessage.contains('food') ||
        lowerMessage.contains('exercise')) {
      return 'wellness';

    }
    else if(
    lowerMessage.contains('advice') ||
        lowerMessage.contains('recommend') ||
        lowerMessage.contains('suggest')) {
      return 'advice';

    }
    return 'general';
  }


}