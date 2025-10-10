import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'pumo_home_screen.dart';
import 'pumo_chat_list_screen.dart';
import 'pumo_profile_screen.dart';
import 'pumo_subscriptions_screen.dart';
import '../widgets/pumo_tab_bar.dart';
import '../theme/pumo_theme.dart';

class PumoMainScreen extends StatefulWidget {
  const PumoMainScreen({super.key});

  @override
  State<PumoMainScreen> createState() => _PumoMainScreenState();
}

class _PumoMainScreenState extends State<PumoMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PumoHomeScreen(),
    const PumoChatListScreen(),
    Container(), // 第三个tab用于弹出创建AI页面，不需要实际页面
    const PumoProfileScreen(),
  ];

  // 检查VIP月订阅状态
  Future<bool> _checkMonthlyVipStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVip = prefs.getBool('isVip') ?? false;
      final expiryStr = prefs.getString('vipExpiry');
      final vipType = prefs.getString('vip_type') ?? '';
      
      if (!isVip || vipType != 'monthly') {
        return false;
      }
      
      if (expiryStr != null) {
        final vipExpiry = DateTime.tryParse(expiryStr);
        if (vipExpiry != null && vipExpiry.isBefore(DateTime.now())) {
          // VIP已过期，清除状态
          await prefs.setBool('isVip', false);
          await prefs.remove('vipExpiry');
          await prefs.remove('vip_type');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking monthly VIP status: $e');
      return false;
    }
  }

  // 显示月订阅VIP要求弹窗
  void _showMonthlyVipRequiredDialog() {
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
                Icons.workspace_premium,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: PumoTheme.secondaryColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To create AI characters, you need Pumo Monthly Premium.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // 月订阅价格信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.1),
                      PumoTheme.accentColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Monthly',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$49.99',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
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
                _navigateToSubscriptions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade Now',
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

  // 导航到订阅页面（默认选择月订阅）
  void _navigateToSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PumoPremiumScreen(initialPlanIndex: 1), // 1 = 月订阅
      ),
    );
  }

  // 处理第三个tab点击
  Future<void> _handleCreateAITap() async {
    // 检查VIP月订阅状态
    final hasMonthlyVip = await _checkMonthlyVipStatus();
    
    if (hasMonthlyVip) {
      // 有月订阅VIP，正常弹出创建AI页面
      _showCreateAIBottomSheet();
    } else {
      // 没有月订阅VIP，显示提示弹窗
      _showMonthlyVipRequiredDialog();
    }
  }

  void _showCreateAIBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PumoCreateAIBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: PumoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // 第三个tab检查VIP月订阅后弹出创建AI角色页面
            _handleCreateAITap();
          } else {
          setState(() {
            _currentIndex = index;
          });
          }
        },
      ),
    );
  }
}

class PumoCreateAIBottomSheet extends StatefulWidget {
  const PumoCreateAIBottomSheet({super.key});

  @override
  State<PumoCreateAIBottomSheet> createState() => _PumoCreateAIBottomSheetState();
}

class _PumoCreateAIBottomSheetState extends State<PumoCreateAIBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _personalityController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createAICharacter() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for your AI character'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_personalityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a personality for your AI character'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    // 模拟创建过程
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isCreating = false;
      });

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Created successfully, waiting for review completion',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: PumoTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/resources/pumo_loveai_nor.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 标题栏
            Container(
              margin: const EdgeInsets.only(top: 54, left: 15, right: 15, bottom: 40),
              child: Row(
                children: [
                  // 标题图片
                  Image.asset(
                    'assets/resources/pumo_CreateAI.webp',
                    width: 278,
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  // 取消按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像上传区域
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.add,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Name输入框
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                        
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Please enter',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Races输入框
                    const Text(
                      'Personality',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                       
                      ),
                      child: TextField(
                        controller: _personalityController,
                        decoration: const InputDecoration(
                          hintText: 'Please enter',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // OK按钮
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                PumoTheme.primaryColor,
                                PumoTheme.secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _isCreating ? null : _createAICharacter,
                              child: Center(
                                child: _isCreating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'OK',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
