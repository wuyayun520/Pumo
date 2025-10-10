import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../models/pumo_character_data.dart';
import '../models/pumo_ai_character.dart';
import '../widgets/pumo_character_popup.dart';
import '../services/pumo_storage_service.dart';
import '../constants/pumo_constants.dart';
import '../theme/pumo_theme.dart';
import 'pumo_chat_screen.dart';
import 'pumo_inapppurchases_screen.dart';

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

  Future<void> _startChat(AICharacterData character) async {
    try {
      // 检查角色是否已解锁
      final isUnlocked = await PumoStorageService.isCharacterUnlocked(character.characterId);
      
      if (isUnlocked) {
        // 角色已解锁，直接进入聊天
        _navigateToChat(character);
        return;
      }
      
      // 角色未解锁，检查金币是否足够
      final currentCoins = await PumoStorageService.getGoldCoins();
      
      if (currentCoins >= PumoConstants.characterUnlockCost) {
        // 金币足够，显示解锁确认对话框
        _showUnlockConfirmDialog(character, currentCoins);
      } else {
        // 金币不足，显示充值提示对话框
        _showInsufficientCoinsDialog(currentCoins);
      }
    } catch (e) {
      _showErrorSnackBar('Error checking character status: $e');
    }
  }

  void _navigateToChat(AICharacterData character) {
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

  void _showUnlockConfirmDialog(AICharacterData character, int currentCoins) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.favorite,
                color: PumoTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Unlock Character',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock "${character.characterName}" requires ${PumoConstants.characterUnlockCost} Love Hearts',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Current Balance: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: PumoTheme.primaryColor,
                    size: 16,
                  ),
                  Text(
                    ' $currentCoins',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Balance After Unlock: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: PumoTheme.primaryColor,
                    size: 16,
                  ),
                  Text(
                    ' ${currentCoins - PumoConstants.characterUnlockCost}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _unlockCharacter(character);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Unlock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInsufficientCoinsDialog(int currentCoins) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Insufficient Star Coins',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlocking a character requires ${PumoConstants.characterUnlockCost} Love Hearts',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Current Balance: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: PumoTheme.primaryColor,
                    size: 16,
                  ),
                  Text(
                    ' $currentCoins',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Still Need: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
                  Text(
                    ' ${PumoConstants.characterUnlockCost - currentCoins}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToRecharge();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Recharge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unlockCharacter(AICharacterData character) async {
    try {
      // 扣除金币
      final success = await PumoStorageService.deductGoldCoins(PumoConstants.characterUnlockCost);
      
      if (success) {
        // 解锁角色
        await PumoStorageService.unlockCharacter(character.characterId);
        
        // 显示成功提示
        _showSuccessSnackBar('Successfully unlocked "${character.characterName}"!');
        
        // 进入聊天界面
        _navigateToChat(character);
      } else {
        _showErrorSnackBar('Unlock failed: Insufficient coins');
      }
    } catch (e) {
      _showErrorSnackBar('Error unlocking character: $e');
    }
  }

  void _navigateToRecharge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PumoLoveHeartShopScreen(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _isLoading ? null : _onScreenTap,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/resources/pumo_choose_Charra.webp'),
              fit: BoxFit.cover,
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
