import 'message_model.dart';

class Conversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.start(String firstUserText) {
    final now = DateTime.now();
    return Conversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: _titleFrom(firstUserText),
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _titleFrom(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return 'New chat';
    return clean.length <= 40
        ? clean
        : '${clean.substring(0, 40).trimRight()}…';
  }

  Conversation copyWith({
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Chat',
      createdAt: created,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? created,
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
