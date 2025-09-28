import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../models/pumo_character_data.dart';
import '../models/pumo_ai_character.dart';
import '../widgets/pumo_character_popup.dart';
import 'pumo_chat_screen.dart';

class PumoHomeScreen extends StatefulWidget {
  const PumoHomeScreen({super.key});

  @override
  State<PumoHomeScreen> createState() => _PumoHomeScreenState();
}

class _PumoHomeScreenState extends State<PumoHomeScreen> {
  List<AICharacterData> _allCharacters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  Future<void> _loadCharacterData() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/nurturing/affectingDetailed.json');
      
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> usersData = jsonData['users'] as List;
      
      List<AICharacterData> allCharacters = [];
      for (var userData in usersData) {
        final List<dynamic> characters = userData['ai_characters'] as List;
        for (var character in characters) {
          allCharacters.add(AICharacterData.fromJson(character));
        }
      }
      
      setState(() {
        _allCharacters = allCharacters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load character data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onScreenTap() {
    if (_allCharacters.isEmpty) return;
    
    final random = Random();
    final randomCharacter = _allCharacters[random.nextInt(_allCharacters.length)];
    
            showDialog(
              context: context,
              builder: (context) => PumoCharacterPopupCard(
                character: randomCharacter,
                onTap: () => _startChat(randomCharacter),
              ),
            );
  }

  void _startChat(AICharacterData character) {
    // Convert AICharacterData to AICharacter for chat screen
    final aiCharacter = AICharacter(
      id: character.characterId,
      name: character.characterName,
      description: character.characterDescription,
      personality: character.characterPersonality,
      avatarUrl: character.characterAvatar,
      systemPrompt: _generateSystemPrompt(character),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PumoChatScreen(character: aiCharacter),
              ),
            );
  }

  String _generateSystemPrompt(AICharacterData character) {
    return "You are ${character.characterName}, an AI assistant with a ${character.characterPersonality} personality. ${character.characterDescription}. Your style is ${character.characterStyle} and you have a ${character.characterVoice}. Always stay in character and be helpful, friendly, and engaging in your responses.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _onScreenTap,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/resources/pumo_choose_Charra.webp'),
                fit: BoxFit.cover,
              ),
            ),
            
          ),
      ),
    );
  }
}
