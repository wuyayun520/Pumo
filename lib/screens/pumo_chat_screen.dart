import 'package:flutter/material.dart';
import '../models/pumo_ai_character.dart';
import '../models/pumo_chat_message.dart';
import '../services/pumo_ai_service.dart';
import '../widgets/pumo_chat_bubble.dart';
import '../widgets/pumo_message_input.dart';
import '../constants/pumo_constants.dart';

class PumoChatScreen extends StatefulWidget {
  final AICharacter character;

  const PumoChatScreen({
    super.key,
    required this.character,
  });

  @override
  State<PumoChatScreen> createState() => _PumoChatScreenState();
}

class _PumoChatScreenState extends State<PumoChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }


  Future<void> _addWelcomeMessage() async {
    // 每次进入都添加欢迎消息
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      characterId: widget.character.id,
      type: MessageType.ai,
      content: PumoAIService.generateWelcomeMessage(widget.character),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      characterId: widget.character.id,
      type: MessageType.user,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiResponse = await PumoAIService.generateResponse(
        character: widget.character,
        messages: _messages,
      );

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: widget.character.id,
        type: MessageType.ai,
        content: aiResponse,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      _showErrorSnackBar('Failed to send message: $e');
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: PumoConstants.shortAnimation,
          curve: Curves.easeOut,
        );
      }
    });
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
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: widget.character.avatarUrl.isNotEmpty
                  ? AssetImage(widget.character.avatarUrl)
                  : null,
              child: widget.character.avatarUrl.isEmpty
                  ? Text(
                      widget.character.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.character.personality,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(PumoConstants.defaultPadding),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                        return PumoChatBubble(
                          message: ChatMessage(
                            id: 'typing',
                            characterId: 'typing',
                            type: MessageType.ai,
                            content: 'Typing...',
                            timestamp: DateTime.now(),
                            isTyping: true,
                          ),
                          character: widget.character,
                        );
                }
                return PumoChatBubble(
                  message: _messages[index],
                  character: widget.character,
                );
              },
            ),
          ),
          PumoMessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            isLoading: _isTyping,
          ),
        ],
      ),
    );
  }

}
