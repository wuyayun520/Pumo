import 'package:flutter/material.dart';
import '../models/pumo_character_data.dart';
import '../models/pumo_ai_character.dart';
import 'pumo_chat_screen.dart';
import 'pumo_user_chat_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PumoUserDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;
  final String userDescription;
  final int userAge;
  final String userGender;
  final String userNationality;
  final List<String> userInterests;

  const PumoUserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userDescription,
    required this.userAge,
    required this.userGender,
    required this.userNationality,
    required this.userInterests,
  });

  @override
  State<PumoUserDetailScreen> createState() => _PumoUserDetailScreenState();
}

class _PumoUserDetailScreenState extends State<PumoUserDetailScreen> {
  List<AICharacterData> _userCharacters = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadUserCharacters();
    _loadFollowingStatus();
    _loadBlockStatus();
  }

  Future<void> _loadUserCharacters() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/nurturing/affectingDetailed.json');

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> usersData = jsonData['users'] as List;

      // 找到对应用户的AI角色
      for (var userData in usersData) {
        if (userData['user_id'] == widget.userId) {
          final List<dynamic> aiCharacters = userData['ai_characters'] as List;
          List<AICharacterData> characters = [];
          
          for (var characterData in aiCharacters) {
            characters.add(AICharacterData.fromJson(characterData));
          }
          
          setState(() {
            _userCharacters = characters;
            _isLoading = false;
          });
          break;
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load user characters: $e');
    }
  }

  Future<void> _loadFollowingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followingList = prefs.getStringList('following_users') ?? [];
      setState(() {
        _isFollowing = followingList.contains(widget.userId);
      });
    } catch (e) {
      print('Error loading following status: $e');
    }
  }

  Future<void> _saveFollowingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followingList = prefs.getStringList('following_users') ?? [];
      
      if (_isFollowing) {
        if (!followingList.contains(widget.userId)) {
          followingList.add(widget.userId);
        }
      } else {
        followingList.remove(widget.userId);
      }
      
      await prefs.setStringList('following_users', followingList);
    } catch (e) {
      print('Error saving following status: $e');
    }
  }

  Future<void> _loadBlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedList = prefs.getStringList('blocked_users') ?? [];
      setState(() {
        _isBlocked = blockedList.contains(widget.userId);
      });
    } catch (e) {
      print('Error loading block status: $e');
    }
  }

  Future<void> _saveBlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedList = prefs.getStringList('blocked_users') ?? [];
      
      if (_isBlocked) {
        if (!blockedList.contains(widget.userId)) {
          blockedList.add(widget.userId);
        }
      } else {
        blockedList.remove(widget.userId);
      }
      
      await prefs.setStringList('blocked_users', blockedList);
    } catch (e) {
      print('Error saving block status: $e');
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

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    _saveFollowingStatus();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? 'Following ${widget.userName}!' : 'Unfollowed ${widget.userName}'),
        backgroundColor: const Color(0xFFFF4BD9),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // 举报用户
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report User'),
              subtitle: const Text('Report inappropriate behavior'),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
            
            // 拉黑/取消拉黑
            ListTile(
              leading: Icon(
                _isBlocked ? Icons.person_add : Icons.block,
                color: _isBlocked ? Colors.green : Colors.red,
              ),
              title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
              subtitle: Text(_isBlocked 
                ? 'Restore access to this user' 
                : 'Block this user and hide their content'),
              onTap: () {
                Navigator.pop(context);
                _toggleBlock();
              },
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Are you sure you want to report this user? This action will be reviewed by our team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User reported successfully. Thank you for your feedback.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _toggleBlock() {
    setState(() {
      _isBlocked = !_isBlocked;
    });
    _saveBlockStatus();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBlocked 
          ? 'User blocked successfully' 
          : 'User unblocked successfully'),
        backgroundColor: _isBlocked ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF), // 淡紫色背景
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black54,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.black54,
                size: 18,
              ),
            ),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: _isBlocked 
        ? _buildBlockedView()
        : Column(
            children: [
              // 用户信息头部
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // 用户头像
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          widget.userAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 60, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 用户名
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '🍒', // 樱桃表情符号
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Follow按钮和聊天按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Follow按钮
                        Expanded(
                          child: GestureDetector(
                            onTap: _toggleFollow,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF4BD9), Color(0xFFFF69B4)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isFollowing ? Icons.check : Icons.add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 聊天按钮
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PumoUserChatScreen(
                                  userId: widget.userId,
                                  userName: widget.userName,
                                  userAvatar: widget.userAvatar,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            child: Image.asset(
                              'assets/resources/pumo_individual_chat.webp',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // AI角色标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'My character',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '(${_userCharacters.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // AI角色网格
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4BD9)),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75, // 调整卡片比例
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _userCharacters.length,
                          itemBuilder: (context, index) {
                            final character = _userCharacters[index];
                            return _buildCharacterCard(character);
                          },
                        ),
                      ),
              ),
            ],
          ),
    );
  }

  Widget _buildCharacterCard(AICharacterData character) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PumoChatScreen(
              character: AICharacter(
                id: character.characterId,
                name: character.characterName,
                avatarUrl: character.characterAvatar,
                personality: character.characterPersonality,
                description: character.characterDescription,
                systemPrompt: 'You are ${character.characterName}, ${character.characterDescription}. Your personality: ${character.characterPersonality}.',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 角色背景图片
              Image.asset(
                character.characterAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  );
                },
              ),
              
              // 渐变遮罩
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              
              // 角色名称
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  character.characterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 拉黑图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // 拉黑提示文字
          const Text(
            'This user has been blocked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          const Text(
            'You have blocked this user and their content is hidden.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // 取消拉黑按钮
          ElevatedButton(
            onPressed: _toggleBlock,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Unblock User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
