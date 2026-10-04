import 'package:equatable/equatable.dart';
import '../models/conversation.dart';
import '../models/message_model.dart';

class ChatState extends Equatable {
  final List<Conversation> conversations;
  final String? activeId;
  final String? loadingId;
  final bool loaded;
  final String? error;

  const ChatState({
    this.conversations = const [],
    this.activeId,
    this.loadingId,
    this.loaded = false,
    this.error,
  });

  Conversation? get active {
    for (final c in conversations) {
      if (c.id == activeId) return c;
    }
    return null;
  }

  List<ChatMessage> get messages => active?.messages ?? const [];
  bool get isLoading => loadingId != null;
  bool get isActiveLoading => loadingId != null && loadingId == activeId;

  ChatState copyWith({
    List<Conversation>? conversations,
    String? activeId,
    bool clearActive = false,
    String? loadingId,
    bool clearLoading = false,
    bool? loaded,
    String? error,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeId: clearActive ? null : (activeId ?? this.activeId),
      loadingId: clearLoading ? null : (loadingId ?? this.loadingId),
      loaded: loaded ?? this.loaded,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [conversations, activeId, loadingId, loaded, error];
}
