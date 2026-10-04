enum Sender { user, ai }

class ChatMessage {
  final String text;
  final Sender sender;
  final bool isError;

  /// 'weather' or 'calculate' when a tool produced this reply.
  final String? tool;
  final DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.sender,
    this.isError = false,
    this.tool,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'sender': sender.name,
        'isError': isError,
        'tool': tool,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String? ?? '',
      sender: Sender.values.firstWhere(
        (s) => s.name == json['sender'],
        orElse: () => Sender.ai,
      ),
      isError: json['isError'] as bool? ?? false,
      tool: json['tool'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
