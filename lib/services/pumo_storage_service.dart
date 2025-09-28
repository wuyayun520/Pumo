import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pumo_ai_character.dart';
import '../models/pumo_chat_message.dart';
import '../constants/pumo_constants.dart';

class PumoStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // AI Characters Management
  static Future<List<AICharacter>> getCharacters() async {
    await init();
    final charactersJson = _prefs!.getStringList(PumoConstants.charactersKey) ?? [];
    return charactersJson
        .map((json) => AICharacter.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveCharacter(AICharacter character) async {
    await init();
    final characters = await getCharacters();
    final existingIndex = characters.indexWhere((c) => c.id == character.id);
    
    if (existingIndex >= 0) {
      characters[existingIndex] = character;
    } else {
      characters.add(character);
    }
    
    final charactersJson = characters
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    
    await _prefs!.setStringList(PumoConstants.charactersKey, charactersJson);
  }

  static Future<void> deleteCharacter(String characterId) async {
    await init();
    final characters = await getCharacters();
    characters.removeWhere((c) => c.id == characterId);
    
    final charactersJson = characters
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    
    await _prefs!.setStringList(PumoConstants.charactersKey, charactersJson);
  }

  // Chat History Management
  static Future<List<ChatMessage>> getChatHistory(String characterId) async {
    await init();
    final key = '${PumoConstants.chatHistoryKey}_$characterId';
    final messagesJson = _prefs!.getStringList(key) ?? [];
    return messagesJson
        .map((json) => ChatMessage.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveChatMessage(ChatMessage message) async {
    await init();
    final key = '${PumoConstants.chatHistoryKey}_${message.characterId}';
    final messages = await getChatHistory(message.characterId);
    messages.add(message);
    
    final messagesJson = messages
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    
    await _prefs!.setStringList(key, messagesJson);
  }

  static Future<void> clearChatHistory(String characterId) async {
    await init();
    final key = '${PumoConstants.chatHistoryKey}_$characterId';
    await _prefs!.remove(key);
  }

  static Future<void> deleteChatMessage(String characterId, String messageId) async {
    await init();
    final messages = await getChatHistory(characterId);
    messages.removeWhere((m) => m.id == messageId);
    
    final key = '${PumoConstants.chatHistoryKey}_$characterId';
    final messagesJson = messages
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    
    await _prefs!.setStringList(key, messagesJson);
  }

  // User Preferences
  static Future<Map<String, dynamic>> getUserPreferences() async {
    await init();
    final prefsJson = _prefs!.getString(PumoConstants.userPreferencesKey);
    if (prefsJson != null) {
      return jsonDecode(prefsJson);
    }
    return {};
  }

  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await init();
    await _prefs!.setString(
      PumoConstants.userPreferencesKey,
      jsonEncode(preferences),
    );
  }

  // Utility Methods
  static Future<void> clearAllData() async {
    await init();
    await _prefs!.clear();
  }

  static Future<int> getStorageSize() async {
    await init();
    final keys = _prefs!.getKeys();
    int totalSize = 0;
    
    for (final key in keys) {
      final value = _prefs!.get(key);
      if (value is String) {
        totalSize += value.length;
      } else if (value is List<String>) {
        totalSize += value.join().length;
      }
    }
    
    return totalSize;
  }
}
