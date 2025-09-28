import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../theme/pumo_theme.dart';
import 'pumo_video_call_screen.dart';

class PumoUserChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const PumoUserChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<PumoUserChatScreen> createState() => _PumoUserChatScreenState();
}

class _PumoUserChatScreenState extends State<PumoUserChatScreen> {
  List<_PumoChatMessage> _pumoMessages = [];
  final TextEditingController _pumoTextController = TextEditingController();
  final ScrollController _pumoChatScrollController = ScrollController();
  final ImagePicker _pumoImagePicker = ImagePicker();
  final AudioRecorder _pumoVoiceRecorder = AudioRecorder();
  bool _isPumoRecording = false;
  DateTime? _pumoRecordingStartTime;

  @override
  void initState() {
    super.initState();
    _loadPumoMessages();
    // 如果用户名是默认格式，强制保存正确的用户信息
    _ensurePumoUserInfo();
  }

  Future<void> _ensurePumoUserInfo() async {
    // 检查当前用户是否是从真实用户资料页面传递过来的（不是默认用户）
    if (!widget.userName.startsWith('User ')) {
      // 如果是真实用户信息，立即保存以覆盖可能存在的默认用户信息
      await _savePumoUserInfoOnly();
    }
  }

  Future<void> _savePumoUserInfoOnly() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/chat_history_${widget.userId}.json');
      
      List<Map<String, dynamic>> chatData = [];
      
      // 如果文件存在，读取现有消息
      if (await file.exists()) {
        try {
          final jsonStr = await file.readAsString();
          final List<dynamic> existingData = json.decode(jsonStr);
          
          // 保留所有非用户信息的条目
          chatData = existingData
              .where((item) => item is Map<String, dynamic> && item['type'] != 'userInfo')
              .cast<Map<String, dynamic>>()
              .toList();
        } catch (e) {
          debugPrint('Error reading existing chat data: $e');
        }
      }
      
      // 在开头添加最新的用户信息
      chatData.insert(0, {
        'type': 'userInfo',
        'userInfo': {
          'name': widget.userName,
          'username': widget.userName,
          'profilePicture': widget.userAvatar,
          'userIcon': widget.userAvatar,
          'bio': 'User profile',
        },
        'time': _getPumoTimeStamp(),
      });
      
      final jsonStr = json.encode(chatData);
      await file.writeAsString(jsonStr);
      debugPrint('Updated user info for ${widget.userName}');
    } catch (e) {
      debugPrint('Error saving user info: $e');
    }
  }

  Future<String> _getPumoMediaDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/chat_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  Future<void> _loadPumoMessages() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/chat_history_${widget.userId}.json');
    if (await file.exists()) {
      try {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonStr);
        
        // 过滤掉用户信息条目，只保留实际的聊天消息
        final messageList = jsonList.where((item) => 
          item is Map<String, dynamic> && item['type'] != 'userInfo'
        ).toList();
        
        setState(() {
          _pumoMessages = messageList.map((e) => _PumoChatMessage.fromJson(e)).toList();
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollPumoToBottom);
      } catch (e) {
        debugPrint('Error loading messages: $e');
      }
    }
  }

  Future<void> _savePumoMessages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/chat_history_${widget.userId}.json');
      
      // 创建包含用户信息的聊天记录
      final chatData = <Map<String, dynamic>>[];
      
      // 总是添加最新的用户信息（覆盖旧的用户信息）
      chatData.add({
        'type': 'userInfo',
        'userInfo': {
          'name': widget.userName,
          'username': widget.userName,
          'profilePicture': widget.userAvatar,
          'userIcon': widget.userAvatar,
          'bio': 'User profile',
        },
        'time': _getPumoTimeStamp(),
      });
      debugPrint('Added user info for ${widget.userName}');
      
      // 添加所有消息
      chatData.addAll(_pumoMessages.map((e) => e.toJson()).toList());
      
      final jsonStr = json.encode(chatData);
      await file.writeAsString(jsonStr);
      debugPrint('Saved ${_pumoMessages.length} messages for user ${widget.userId}');
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  void _sendPumoMessage() {
    final text = _pumoTextController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _pumoMessages.add(_PumoChatMessage(
        text: text,
        isMe: true,
        time: _getPumoTimeStamp(),
        type: _PumoChatMessageType.text,
      ));
    });
    _pumoTextController.clear();
    _scrollPumoToBottom();
    _savePumoMessages();
  }

  Future<void> _sendPumoImage(File imageFile) async {
    try {
      final mediaDir = await _getPumoMediaDirectory();
      final fileName = 'pumo_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await imageFile.copy('$mediaDir/$fileName');
      
      setState(() {
        _pumoMessages.add(_PumoChatMessage(
          imagePath: fileName,
          isMe: true,
          time: _getPumoTimeStamp(),
          type: _PumoChatMessageType.image,
        ));
      });
      _scrollPumoToBottom();
      _savePumoMessages();
    } catch (e) {
      _showPumoErrorSnackBar('Failed to send image: $e');
    }
  }

  Future<void> _sendPumoVoice(String audioPath, Duration duration) async {
    try {
      final mediaDir = await _getPumoMediaDirectory();
      final fileName = 'pumo_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await File(audioPath).copy('$mediaDir/$fileName');
      
      setState(() {
        _pumoMessages.add(_PumoChatMessage(
          audioPath: fileName,
          audioDuration: duration,
          isMe: true,
          time: _getPumoTimeStamp(),
          type: _PumoChatMessageType.audio,
        ));
      });
      _scrollPumoToBottom();
      _savePumoMessages();
        
      _showPumoSuccessSnackBar('Voice message sent! 🎵');
    } catch (e) {
      _showPumoErrorSnackBar('Failed to send voice message: $e');
    }
  }

  void _scrollPumoToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_pumoChatScrollController.hasClients) {
        _pumoChatScrollController.animateTo(
          _pumoChatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickPumoImage() async {
    try {
      final XFile? picked = await _pumoImagePicker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 85
      );
      if (picked != null) {
        await _sendPumoImage(File(picked.path));
      }
    } catch (e) {
      _showPumoErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _togglePumoVoiceRecording() async {
    try {
      if (_isPumoRecording) {
        // 停止录制
        final path = await _pumoVoiceRecorder.stop();
        setState(() {
          _isPumoRecording = false;
          _pumoRecordingStartTime = null;
        });
          
        if (path != null) {
          final duration = await _getPumoAudioDuration(path);
          if (duration.inSeconds > 0) {
            await _sendPumoVoice(path, duration);
          } else {
            _showPumoErrorSnackBar('Recording too short');
          }
        }
      } else {
        // 检查权限
        if (await _pumoVoiceRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/pumo_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
            
          await _pumoVoiceRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: filePath,
          );
            
          setState(() {
            _isPumoRecording = true;
            _pumoRecordingStartTime = DateTime.now();
          });
            
          _showPumoInfoSnackBar('Recording... 🎙️ Tap again to stop');
        } else {
          _showPumoErrorSnackBar('Microphone permission denied');
        }
      }
    } catch (e) {
      setState(() {
        _isPumoRecording = false;
        _pumoRecordingStartTime = null;
      });
      _showPumoErrorSnackBar('Recording error: $e');
    }
  }

  Future<Duration> _getPumoAudioDuration(String path) async {
    final player = AudioPlayer();
    try {
      await player.setFilePath(path);
      return player.duration ?? Duration.zero;
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return Duration.zero;
    } finally {
      await player.dispose();
    }
  }

  void _showPumoSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: PumoTheme.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPumoErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[400],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPumoInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: PumoTheme.secondaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getPumoTimeStamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pumoTextController.dispose();
    _pumoChatScrollController.dispose();
    _pumoVoiceRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PumoTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: PumoTheme.primaryColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(widget.userAvatar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.video_call, size: 20, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PumoVideoCallScreen(
                      user: PumoVideoCallUser(
                        id: widget.userId,
                        name: widget.userName,
                        displayName: widget.userName,
                        avatar: widget.userAvatar,
                        background: widget.userAvatar, // 使用用户头像作为背景
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 聊天头部装饰条
          Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PumoTheme.primaryColor,
                  PumoTheme.secondaryColor,
                ],
              ),
            ),
          ),
          // 消息列表
          Expanded(
            child: Container(
              color: PumoTheme.backgroundColor,
              child: _pumoMessages.isEmpty
                  ? _buildPumoEmptyState()
                  : ListView.builder(
                      controller: _pumoChatScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _pumoMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _pumoMessages[index];
                        return _PumoChatBubble(
                          message: msg,
                          onImageTap: (file) {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: InteractiveViewer(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(file),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
          // 输入栏
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _PumoChatInputBar(
              controller: _pumoTextController,
              onSend: _sendPumoMessage,
              onImage: _pickPumoImage,
              onRecord: _togglePumoVoiceRecording,
              isRecording: _isPumoRecording,
              recordingStartTime: _pumoRecordingStartTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPumoEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PumoTheme.primaryColor.withOpacity(0.2),
                  PumoTheme.secondaryColor.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: PumoTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PumoTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message, photo, or voice note',
            style: TextStyle(
              fontSize: 14,
              color: PumoTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PumoChatMessageType { text, image, audio }

class _PumoChatMessage {
  final String? text;
  final String? imagePath;
  final String? audioPath;
  final Duration? audioDuration;
  final bool isMe;
  final String time;
  final _PumoChatMessageType type;

  _PumoChatMessage({
    this.text,
    this.imagePath,
    this.audioPath,
    this.audioDuration,
    required this.isMe,
    required this.time,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'imagePath': imagePath,
    'audioPath': audioPath,
    'audioDuration': audioDuration?.inMilliseconds,
    'isMe': isMe,
    'time': time,
    'type': type.name,
  };

  static _PumoChatMessage fromJson(Map<String, dynamic> json) => _PumoChatMessage(
    text: json['text'],
    imagePath: json['imagePath'],
    audioPath: json['audioPath'],
    audioDuration: json['audioDuration'] != null 
        ? Duration(milliseconds: json['audioDuration']) 
        : null,
    isMe: json['isMe'] ?? true,
    time: json['time'] ?? '',
    type: _PumoChatMessageType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => _PumoChatMessageType.text,
    ),
  );
}

class _PumoChatBubble extends StatefulWidget {
  final _PumoChatMessage message;
  final void Function(File file)? onImageTap;
  const _PumoChatBubble({required this.message, this.onImageTap});

  @override
  State<_PumoChatBubble> createState() => _PumoChatBubbleState();
}

class _PumoChatBubbleState extends State<_PumoChatBubble> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == _PumoChatMessageType.audio) {
      _duration = widget.message.audioDuration ?? Duration.zero;
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      final msg = widget.message;
      final dir = await getApplicationDocumentsDirectory();
      final absPath = '${dir.path}/chat_media/${msg.audioPath}';
      
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        
        // 监听播放状态
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        });
        
        // 监听播放进度
        _audioPlayer!.positionStream.listen((pos) {
          if (mounted) {
            setState(() {
              _position = pos;
            });
          }
        });
        
        // 监听播放完成
        _audioPlayer!.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) {
              setState(() {
                _position = Duration.zero;
                _isPlaying = false;
              });
            }
          }
        });
      }
      
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.setFilePath(absPath);
        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    
    if (msg.type == _PumoChatMessageType.audio && msg.audioPath != null) {
      final current = _position > _duration ? _duration : _position;
      return Align(
        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
          decoration: BoxDecoration(
            gradient: msg.isMe 
                ? LinearGradient(
                    colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: msg.isMe ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: msg.isMe ? null : Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: msg.isMe 
                    ? PumoTheme.primaryColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: msg.isMe 
                            ? Colors.white.withOpacity(0.2)
                            : PumoTheme.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: msg.isMe ? Colors.white : PumoTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: (msg.isMe ? Colors.white : PumoTheme.primaryColor).withOpacity(0.3),
                          ),
                          child: LinearProgressIndicator(
                            value: _duration.inMilliseconds == 0 
                                ? 0 
                                : current.inMilliseconds / _duration.inMilliseconds,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              msg.isMe ? Colors.white : PumoTheme.primaryColor
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(current),
                              style: TextStyle(
                                color: msg.isMe ? Colors.white : Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: TextStyle(
                                color: msg.isMe ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  msg.time,
                  style: TextStyle(
                    color: msg.isMe ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (msg.type == _PumoChatMessageType.image && msg.imagePath != null) {
      return Align(
        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () async {
            final dir = await getApplicationDocumentsDirectory();
            final absPath = '${dir.path}/chat_media/${msg.imagePath}';
            widget.onImageTap?.call(File(absPath));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FutureBuilder<Directory>(
                    future: getApplicationDocumentsDirectory(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox(width: 160, height: 160);
                      final absPath = '${snapshot.data!.path}/chat_media/${msg.imagePath}';
                      return Image.file(
                        File(absPath),
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 160,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 40),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    msg.time,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 文本消息
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: msg.isMe 
              ? LinearGradient(
                  colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: msg.isMe ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: msg.isMe ? null : Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: msg.isMe 
                  ? PumoTheme.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text ?? '',
              style: TextStyle(
                color: msg.isMe ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                msg.time,
                style: TextStyle(
                  color: msg.isMe ? Colors.white70 : Colors.black54,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PumoChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final VoidCallback onRecord;
  final bool isRecording;
  final DateTime? recordingStartTime;
  
  const _PumoChatInputBar({
    required this.controller, 
    required this.onSend, 
    required this.onImage, 
    required this.onRecord, 
    required this.isRecording, 
    this.recordingStartTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Column(
          children: [
            if (isRecording && recordingStartTime != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recording...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final elapsed = DateTime.now().difference(recordingStartTime!);
                        return Text(
                          '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 录音按钮
                  Container(
                    decoration: BoxDecoration(
                      gradient: isRecording 
                          ? LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!])
                          : LinearGradient(
                              colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? Colors.red[400]! : PumoTheme.primaryColor).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onRecord,
                      tooltip: isRecording ? 'Stop recording' : 'Record voice',
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 图片按钮
                  Container(
                    decoration: BoxDecoration(
                      color: PumoTheme.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: PumoTheme.accentColor,
                        size: 20,
                      ),
                      onPressed: onImage,
                      tooltip: 'Send image',
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 输入框
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: PumoTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        style: TextStyle(
                          color: PumoTheme.textPrimaryColor,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: PumoTheme.textSecondaryColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 发送按钮
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PumoTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onSend,
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 