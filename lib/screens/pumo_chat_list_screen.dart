import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pumo_user_detail_screen.dart';

class UserData {
  final String userId;
  final String userName;
  final String userAvatar;
  final String userDescription;
  final int userAge;
  final String userGender;
  final String userNationality;
  final List<String> userInterests;

  UserData({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userDescription,
    required this.userAge,
    required this.userGender,
    required this.userNationality,
    required this.userInterests,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'] ?? '',
      userDescription: json['user_description'] ?? '',
      userAge: json['user_age'] ?? 0,
      userGender: json['user_gender'] ?? '',
      userNationality: json['user_nationality'] ?? '',
      userInterests: List<String>.from(json['user_interests'] ?? []),
    );
  }
}

class PumoChatListScreen extends StatefulWidget {
  const PumoChatListScreen({super.key});

  @override
  State<PumoChatListScreen> createState() => _PumoChatListScreenState();
}

class _PumoChatListScreenState extends State<PumoChatListScreen> {
  List<UserData> _allUsers = [];
  bool _isLoading = true;
  Set<String> _likedUsers = {}; // 存储已点赞的用户ID

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLikedUsers();
  }

  Future<void> _loadUserData() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/nurturing/affectingDetailed.json');

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> usersData = jsonData['users'] as List;

      List<UserData> allUsers = [];
      for (var userData in usersData) {
        allUsers.add(UserData.fromJson(userData));
      }

      setState(() {
        _allUsers = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load user data: $e');
    }
  }

  Future<void> _loadLikedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedUsersList = prefs.getStringList('liked_users') ?? [];
      setState(() {
        _likedUsers = Set<String>.from(likedUsersList);
      });
    } catch (e) {
      print('Error loading liked users: $e');
    }
  }

  Future<void> _saveLikedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('liked_users', _likedUsers.toList());
    } catch (e) {
      print('Error saving liked users: $e');
    }
  }

  void _toggleLike(String userId) {
    setState(() {
      if (_likedUsers.contains(userId)) {
        _likedUsers.remove(userId);
      } else {
        _likedUsers.add(userId);
      }
    });
    _saveLikedUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片铺满整个屏幕
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/resources/pumo_loveai_nor.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 前景内容
          SafeArea(
            child: Column(
              children: [
                // LOVEDAI标题
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 15),
                  child: Image.asset(
                    'assets/resources/pumo_LOVEDAI.webp',
                    width: 241,
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                ),
                // 用户列表
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          itemCount: _allUsers.length,
                          itemBuilder: (context, index) {
                            final user = _allUsers[index];
                            final isEven = index % 2 == 0;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: isEven
                                  ? _buildUserCardLeftToRight(user)
                                  : _buildUserCardRightToLeft(user),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCardLeftToRight(UserData user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PumoUserDetailScreen(
              userId: user.userId,
              userName: user.userName,
              userAvatar: user.userAvatar,
              userDescription: user.userDescription,
              userAge: user.userAge,
              userGender: user.userGender,
              userNationality: user.userNationality,
              userInterests: user.userInterests,
            ),
          ),
        );
      },
      child: Container(
        height: 180, // 增加卡片高度
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/resources/pumo_individual_card_left.webp'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 左侧：用户头像
            Container(
              width: 120,
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  user.userAvatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 50),
            // 中间：用户信息 - 增加宽度20像素
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${user.userName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.userAge} • ${user.userGender}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 右侧：点赞按钮
            GestureDetector(
              onTap: () => _toggleLike(user.userId),
              child: Container(
                width: 50,
                height: 50,
                child: Image.asset(
                  _likedUsers.contains(user.userId)
                      ? 'assets/resources/pumo_like_pre.webp'
                      : 'assets/resources/pumo_like_nor.webp',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildUserCardRightToLeft(UserData user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PumoUserDetailScreen(
              userId: user.userId,
              userName: user.userName,
              userAvatar: user.userAvatar,
              userDescription: user.userDescription,
              userAge: user.userAge,
              userGender: user.userGender,
              userNationality: user.userNationality,
              userInterests: user.userInterests,
            ),
          ),
        );
      },
      child: Container(
        height: 180, // 增加卡片高度
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/resources/pumo_individual_card_right.webp'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 左侧：点赞按钮
            GestureDetector(
              onTap: () => _toggleLike(user.userId),
              child: Container(
                width: 50,
                height: 50,
                child: Image.asset(
                  _likedUsers.contains(user.userId)
                      ? 'assets/resources/pumo_like_pre.webp'
                      : 'assets/resources/pumo_like_nor.webp',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 30),
            // 中间：用户信息 - 增加宽度20像素
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${user.userName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.userAge} • ${user.userGender}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            // 右侧：用户头像
            Container(
              width: 120,
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  user.userAvatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
