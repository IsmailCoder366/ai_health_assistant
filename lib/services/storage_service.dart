import 'dart:convert';

import 'package:ai_healthcare_assistant/models/conversation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _conversationsKey = 'health_conversation';
  static const String _currentConversationKey = 'current_conversation_id';
  static const String _userProfileKey = 'user_profile';

  Future<List<Conversation>> loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationJson = prefs.getStringList(_conversationsKey) ?? [];

      return conversationJson
          .map((json) => Conversation.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print("Error $e");
      return [];
    }
  }


  Future<void> saveConversation(Conversation conversation) async{
    try{
      final prefs = await SharedPreferences.getInstance();
      final conversations = await loadConversations();
      final existingIndex = conversations.indexWhere(
          (c) => c.id == conversation.id,
      );

      if(existingIndex != -1){
        conversations[existingIndex] = conversation;
      }
      else{
        conversations.add(conversation);
      }

      final conversationsJson = conversations
          .map((c) => jsonEncode(c.toJson()))
          .toList();
await prefs.setStringList(_conversationsKey, conversationsJson);
  }catch(e){
print('Error $e');
    }}


  Future<void> deleteConversation(String conversationId) async{
    try{
      final prefs = await SharedPreferences.getInstance();
      final conversations = await loadConversations();
      conversations.removeWhere((c) => c.id == conversationId);
      final conversationsJson = conversations
          .map((c) => jsonEncode(c.toJson()))
          .toList();
      await prefs.setStringList(_conversationsKey, conversationsJson);


    }catch(e){
      print('Error $e');
    }}


  Future<void> clearAllConversations() async{
    try{
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationsKey);
      await prefs.reload();
    }catch(e){print('Error $e');}
  }


  Future<String?> getCurrentConversationId()async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentConversationKey);
  }

  Future<void> setCurrentConversationId(String conversationId)async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationKey, conversationId);
  }

  Future<Map<String, dynamic>> getUserProfile() async{
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    if(profileJson != null){
      return jsonDecode(profileJson);
    }
    return {};
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile));
  }

}
