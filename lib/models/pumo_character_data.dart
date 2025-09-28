class AICharacterData {
  final String characterId;
  final String characterName;
  final String characterAvatar;
  final String characterDescription;
  final String characterPersonality;
  final List<String> characterAbilities;
  final String characterStyle;
  final String characterVoice;

  const AICharacterData({
    required this.characterId,
    required this.characterName,
    required this.characterAvatar,
    required this.characterDescription,
    required this.characterPersonality,
    required this.characterAbilities,
    required this.characterStyle,
    required this.characterVoice,
  });

  factory AICharacterData.fromJson(Map<String, dynamic> json) {
    return AICharacterData(
      characterId: json['character_id'] as String,
      characterName: json['character_name'] as String,
      characterAvatar: json['character_avatar'] as String,
      characterDescription: json['character_description'] as String,
      characterPersonality: json['character_personality'] as String,
      characterAbilities: List<String>.from(json['character_abilities'] as List),
      characterStyle: json['character_style'] as String,
      characterVoice: json['character_voice'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character_id': characterId,
      'character_name': characterName,
      'character_avatar': characterAvatar,
      'character_description': characterDescription,
      'character_personality': characterPersonality,
      'character_abilities': characterAbilities,
      'character_style': characterStyle,
      'character_voice': characterVoice,
    };
  }
}

class UserData {
  final String userId;
  final String userName;
  final String userAvatar;
  final String userDescription;
  final int userAge;
  final String userGender;
  final String userNationality;
  final List<String> userInterests;
  final List<AICharacterData> aiCharacters;

  const UserData({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userDescription,
    required this.userAge,
    required this.userGender,
    required this.userNationality,
    required this.userInterests,
    required this.aiCharacters,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String,
      userDescription: json['user_description'] as String,
      userAge: json['user_age'] as int,
      userGender: json['user_gender'] as String,
      userNationality: json['user_nationality'] as String,
      userInterests: List<String>.from(json['user_interests'] as List),
      aiCharacters: (json['ai_characters'] as List)
          .map((character) => AICharacterData.fromJson(character))
          .toList(),
    );
  }
}
