class PumoConstants {
  static const String appName = 'Pumo';
  static const String appDescription = 'Create AI Character Chat';
  
  // API Configuration
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String model = 'gpt-3.5-turbo';
  
  // Storage Keys
  static const String charactersKey = 'ai_characters';
  static const String chatHistoryKey = 'chat_history';
  static const String userPreferencesKey = 'user_preferences';
  static const String goldCoinsKey = 'petCoins';
  static const String unlockedCharactersKey = 'unlocked_characters';
  
  // Default Character Settings
  static const String defaultCharacterName = 'AI Assistant';
  static const String defaultCharacterDescription = 'A helpful AI assistant';
  static const String defaultCharacterPersonality = 'Friendly and helpful';
  
  // Character Unlock Settings
  static const int characterUnlockCost = 88;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
