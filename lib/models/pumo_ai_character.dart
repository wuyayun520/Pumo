class AICharacter {
  final String id;
  final String name;
  final String description;
  final String personality;
  final String avatarUrl;
  final String systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const AICharacter({
    required this.id,
    required this.name,
    required this.description,
    required this.personality,
    required this.avatarUrl,
    required this.systemPrompt,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AICharacter.fromJson(Map<String, dynamic> json) {
    return AICharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      personality: json['personality'] as String,
      avatarUrl: json['avatarUrl'] as String,
      systemPrompt: json['systemPrompt'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'personality': personality,
      'avatarUrl': avatarUrl,
      'systemPrompt': systemPrompt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  AICharacter copyWith({
    String? id,
    String? name,
    String? description,
    String? personality,
    String? avatarUrl,
    String? systemPrompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AICharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AICharacter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AICharacter(id: $id, name: $name, description: $description)';
  }
}
