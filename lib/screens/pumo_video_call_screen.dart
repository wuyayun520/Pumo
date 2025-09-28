import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/pumo_theme.dart';

// Pumo视频通话用户模型
class PumoVideoCallUser {
  final String id;
  final String name;
  final String displayName;
  final String avatar;
  final String background;
  
  PumoVideoCallUser({
    required this.id,
    required this.name, 
    required this.displayName,
    required this.avatar,
    required this.background,
  });
}

class PumoVideoCallScreen extends StatefulWidget {
  final PumoVideoCallUser user;

  const PumoVideoCallScreen({
    super.key,
    required this.user,
  });

  @override
  State<PumoVideoCallScreen> createState() => _PumoVideoCallScreenState();
}

class _PumoVideoCallScreenState extends State<PumoVideoCallScreen> {
  bool _isPumoCalling = true;
  bool _showPumoOfflineMessage = false;
  bool _isPumoConnected = false;
  int _pumoCountdown = 0; // 将在_startPumoCountdown中设置
  Timer? _pumoTimer;
  Timer? _pumoCallTimer;
  int _pumoCallDuration = 0; // 通话时长（秒）

  @override
  void initState() {
    super.initState();
    _startPumoCountdown();
  }

  @override
  void dispose() {
    _pumoTimer?.cancel();
    _pumoCallTimer?.cancel();
    super.dispose();
  }


  void _startPumoCountdown() {
    // 只有第10个用户才能接通，其他用户20秒后挂断
    final maxPumoCountdown = widget.user.id == '10' ? 5 : 20;
    _pumoCountdown = maxPumoCountdown;
    
    _pumoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _pumoCountdown--;
      });
      
      if (_pumoCountdown <= 0) {
        _pumoTimer?.cancel();
        
        if (widget.user.id == '10') {
          // 第10个用户接通
          setState(() {
            _isPumoCalling = false;
            _isPumoConnected = true;
          });
          
          // 启动通话计时器
          _startPumoCallTimer();
        } else {
          // 其他用户20秒后挂断
          setState(() {
            _isPumoCalling = false;
            _showPumoOfflineMessage = true;
          });
          
          // 显示挂断弹窗
          _showPumoOfflineDialog();
        }
      }
    });
  }

  void _startPumoCallTimer() {
    _pumoCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _pumoCallDuration++;
        });
      }
    });
  }

  String _formatPumoCallDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showPumoOfflineDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.signal_wifi_off,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pumo Connection Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: PumoTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          content: Text(
            '${widget.user.displayName} is currently offline.\nPlease try again later.',
            style: TextStyle(
              fontSize: 16,
              color: PumoTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 关闭弹窗
                  Navigator.of(context).pop(); // 返回上一页面
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PumoTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // 用户背景图片
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.user.background),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // 背景遮罩（只在拨打时显示，接通后不显示遮罩以显示前置摄像头）
            if (!_isPumoConnected)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3),
              ),
            
            // 小窗口显示用户头像（接通后显示）
            if (_isPumoConnected)
              Positioned(
                top: 140,
                left: 20,
                child: Container(
                  width: 117,
                  height: 117,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pumo Call\nActive',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // 用户姓名（独立导航栏）
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 底部控制区域
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 40,
                  right: 40,
                  top: 40,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(_isPumoConnected ? 0.4 : 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 通话计时器（只在接通时显示）
                    if (_isPumoConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PumoTheme.primaryColor.withOpacity(0.8),
                              PumoTheme.secondaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: PumoTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatPumoCallDuration(_pumoCallDuration),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isPumoConnected) const SizedBox(height: 24),
                    
                    // Pumo挂断按钮
                    GestureDetector(
                      onTap: _showPumoOfflineMessage ? null : () {
                        _pumoTimer?.cancel();
                        _pumoCallTimer?.cancel();
                        setState(() {
                          _isPumoCalling = false;
                          _isPumoConnected = false;
                        });
                        // 结束Pumo通话
                        Navigator.of(context).pop();
                      },
                      child: Image.asset(
                        'assets/resources/pumo_video_open.webp',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pumo状态文本
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _showPumoOfflineMessage
                            ? '${widget.user.displayName} is offline'
                            : _isPumoCalling 
                                ? 'Pumo calling ${widget.user.displayName}...'
                                : _isPumoConnected
                                    ? 'Pumo connected with ${widget.user.displayName}'
                                    : 'Ending Pumo call...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
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
