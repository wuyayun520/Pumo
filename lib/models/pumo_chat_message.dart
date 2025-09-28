enum MessageType {
  user,
  ai,
  system,
}

class ChatMessage {
  final String id;
  final String characterId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isTyping;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.characterId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      characterId: json['characterId'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isTyping: json['isTyping'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? characterId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isTyping,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, content: $content)';
  }
}
