enum MessageType {
  text,
  image,
  voice,
}

class PumoUserChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isFromMe;
  final String? imagePath;
  final String? voicePath;
  final int? voiceDuration; // 语音时长(秒)

  const PumoUserChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isFromMe,
    this.imagePath,
    this.voicePath,
    this.voiceDuration,
  });

  factory PumoUserChatMessage.fromJson(Map<String, dynamic> json) {
    return PumoUserChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      type: MessageType.values[json['type'] as int],
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromMe: json['isFromMe'] as bool,
      imagePath: json['imagePath'] as String?,
      voicePath: json['voicePath'] as String?,
      voiceDuration: json['voiceDuration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'isFromMe': isFromMe,
      'imagePath': imagePath,
      'voicePath': voicePath,
      'voiceDuration': voiceDuration,
    };
  }

  PumoUserChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isFromMe,
    String? imagePath,
    String? voicePath,
    int? voiceDuration,
  }) {
    return PumoUserChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      imagePath: imagePath ?? this.imagePath,
      voicePath: voicePath ?? this.voicePath,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }
}
