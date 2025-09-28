import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/pumo_theme.dart';
import 'pumo_terms_screen.dart';
import 'pumo_privacy_screen.dart';
import 'pumo_about_screen.dart';

class PumoProfileScreen extends StatefulWidget {
  const PumoProfileScreen({super.key});

  @override
  State<PumoProfileScreen> createState() => _PumoProfileScreenState();
}

class _PumoProfileScreenState extends State<PumoProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  String _userName = 'Grace 🍒 Kelly'; // 默认用户名

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUserName();
  }

  // 加载头像
  Future<void> _loadAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileName = prefs.getString('user_avatar_filename');
      
      if (fileName != null) {
        final avatarFile = await _getAvatarFile(fileName);
        if (await avatarFile.exists()) {
          setState(() {
            _avatarFile = avatarFile;
          });
        } else {
          // 如果文件不存在，清除存储的文件名
          await prefs.remove('user_avatar_filename');
        }
      }
    } catch (e) {
      debugPrint('Error loading avatar: $e');
    }
  }

  // 获取头像文件路径
  Future<File> _getAvatarFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${directory.path}/avatars');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    return File('${avatarDir.path}/$fileName');
  }

  // 选择头像
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (image != null) {
        await _saveAvatar(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 保存头像
  Future<void> _saveAvatar(File imageFile) async {
    try {
      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$timestamp.jpg';
      
      // 获取目标文件路径
      final targetFile = await _getAvatarFile(fileName);
      
      // 复制文件到应用文档目录
      await imageFile.copy(targetFile.path);
      
      // 删除旧头像文件
      if (_avatarFile != null && await _avatarFile!.exists()) {
        try {
          await _avatarFile!.delete();
        } catch (e) {
          debugPrint('Error deleting old avatar: $e');
        }
      }
      
      // 保存文件名到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_filename', fileName);
      
      // 更新状态
      setState(() {
        _avatarFile = targetFile;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Avatar updated successfully!'),
              ],
            ),
            backgroundColor: PumoTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 加载用户名
  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');
      
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _userName = savedName;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  // 保存用户名
  Future<void> _saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      
      setState(() {
        _userName = name;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Name updated successfully!'),
              ],
            ),
            backgroundColor: PumoTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示编辑用户名对话框
  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit,
                color: PumoTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Edit Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PumoTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  _saveUserName(newName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name cannot be empty'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PumoTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PumoTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 顶部标题
              Container(
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/resources/pumo_me_title.webp',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              
              // 主要内容区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 用户卡片和头像区域
                    SizedBox(
                      height: 226, // 186 + 40 (头像一半高度)
                      child: Stack(
                        children: [
                          // 背景卡片
                          Container(
                            width: double.infinity,
                            height: 186,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/resources/pumo_me_Groupbg.webp',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          PumoTheme.primaryColor.withOpacity(0.8),
                                          PumoTheme.secondaryColor.withOpacity(0.8),
                                          Colors.purple.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // 用户头像 - 在底部居中，完全显示，可点击选择
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _pickAvatar,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _avatarFile != null
                                            ? Image.file(
                                                _avatarFile!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return _buildDefaultAvatar();
                                                },
                                              )
                                            : _buildDefaultAvatar(),
                                      ),
                                    ),
                                    // 编辑图标
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: PumoTheme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 用户名 - 居中显示，可点击编辑
                    Center(
                      child: GestureDetector(
                        onTap: _showEditNameDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: PumoTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                color: PumoTheme.primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 功能按钮区域
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: Column(
                        children: [
                          // User Contract按钮
                          _buildImageMenuButton(
                            imagePath: 'assets/resources/pumo_me_contract.webp',
                            title: 'User Contract',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PumoTermsScreen(),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Privacy Policy按钮
                          _buildImageMenuButton(
                            imagePath: 'assets/resources/pumo_me_policy.webp',
                            title: 'Privacy Policy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PumoPrivacyScreen(),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // About us按钮
                          _buildImageMenuButton(
                            imagePath: 'assets/resources/pumo_me_us.webp',
                            title: 'About us',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PumoAboutScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // 底部间距，确保内容不会贴底
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageMenuButton({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PumoTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 16,
              color: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
                color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

}
