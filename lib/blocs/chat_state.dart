import 'package:equatable/equatable.dart';
import '../models/conversation.dart';
import '../models/message_model.dart';

class ChatState extends Equatable {
  /// All saved chats, newest first.
  final List<Conversation> conversations;

  /// The open chat. Null means an empty "new chat" that isn't saved yet.
  final String? activeId;

  /// The chat currently waiting for a reply, if any.
  final String? loadingId;

  /// True once saved chats have been read from the device.
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

  /// Any chat waiting for a reply (used to block sending).
  bool get isLoading => loadingId != null;

  /// The open chat is waiting for a reply (used for the typing indicator).
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
