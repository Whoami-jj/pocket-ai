import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/conversation.dart';
import '../models/message_model.dart';
import '../services/calculator_service.dart';
import '../services/chat_storage.dart';
import '../services/gemini_service.dart';
import '../services/weather_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

typedef _ToolReply = ({String reply, String? tool});

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GeminiService _geminiService;
  final WeatherService _weatherService;
  final CalculatorService _calculatorService;
  final ChatStorage _storage;

  ChatBloc({
    GeminiService? geminiService,
    WeatherService? weatherService,
    CalculatorService? calculatorService,
    ChatStorage? storage,
  })  : _geminiService = geminiService ?? GeminiService(),
        _weatherService = weatherService ?? WeatherService(),
        _calculatorService = calculatorService ?? CalculatorService(),
        _storage = storage ?? ChatStorage(),
        super(const ChatState()) {
    on<LoadChatsEvent>(_onLoad);
    on<SendMessageEvent>(_onSendMessage);
    on<NewChatEvent>(
      (event, emit) => emit(state.copyWith(clearActive: true, error: null)),
    );
    on<SelectChatEvent>(_onSelect);
    on<DeleteChatEvent>(_onDelete);
    on<RenameChatEvent>(_onRename);
    on<ClearAllChatsEvent>(_onClearAll);
  }

  Future<void> _onLoad(LoadChatsEvent event, Emitter<ChatState> emit) async {
    final saved = await _storage.load();
    emit(state.copyWith(conversations: saved, loaded: true));
  }

  void _onSelect(SelectChatEvent event, Emitter<ChatState> emit) {
    if (!state.conversations.any((c) => c.id == event.id)) return;
    emit(state.copyWith(activeId: event.id, error: null));
  }

  void _onDelete(DeleteChatEvent event, Emitter<ChatState> emit) {
    final remaining =
        state.conversations.where((c) => c.id != event.id).toList();
    emit(state.copyWith(
      conversations: remaining,
      clearActive: state.activeId == event.id,
    ));
    _persist();
  }

  void _onRename(RenameChatEvent event, Emitter<ChatState> emit) {
    final title = event.title.trim();
    if (title.isEmpty) return;
    emit(state.copyWith(
      conversations: [
        for (final c in state.conversations)
          c.id == event.id ? c.copyWith(title: title) : c,
      ],
    ));
    _persist();
  }

  void _onClearAll(ClearAllChatsEvent event, Emitter<ChatState> emit) {
    emit(const ChatState(loaded: true));
    _persist();
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoading) return;

    final userMessage = ChatMessage(text: event.text, sender: Sender.user);
    var conversations = state.conversations;
    var current = state.active;
    if (current == null) {
      current = Conversation.start(event.text);
      conversations = [current, ...conversations];
    }
    final id = current.id;
    final history = [...current.messages, userMessage];

    emit(state.copyWith(
      conversations:
          _touch(conversations, id, (c) => c.copyWith(messages: history)),
      activeId: id,
      loadingId: id,
      error: null,
    ));
    _persist();

    try {
      String reply = await _geminiService.sendMessage(history);
      String? usedTool;

      if (reply.startsWith('TOOL_CALL:')) {
        final result = await _handleToolCall(reply, history);
        reply = result.reply;
        usedTool = result.tool;
      }

      _finish(
        emit,
        id,
        ChatMessage(text: reply, sender: Sender.ai, tool: usedTool),
      );
    } catch (e) {
      _finish(
        emit,
        id,
        ChatMessage(
          text: 'Something went wrong: $e',
          sender: Sender.ai,
          isError: true,
        ),
        error: e.toString(),
      );
    }
  }

  void _finish(
    Emitter<ChatState> emit,
    String id,
    ChatMessage reply, {
    String? error,
  }) {
    emit(state.copyWith(
      conversations: _touch(
        state.conversations,
        id,
        (c) => c.copyWith(messages: [...c.messages, reply]),
      ),
      clearLoading: true,
      error: error,
    ));
    _persist();
  }

  Future<_ToolReply> _handleToolCall(
    String toolCallLine,
    List<ChatMessage> historySoFar,
  ) async {
    final parts = toolCallLine.split(':');
    if (parts.length < 3) {
      return (
        reply: "I tried to use a tool but couldn't parse the request.",
        tool: null,
      );
    }

    final toolName = parts[1].trim();
    final argument = parts.sublist(2).join(':').trim();

    String toolResult;
    try {
      if (toolName == 'weather') {
        toolResult = await _weatherService.getWeather(argument);
      } else if (toolName == 'calculate') {
        final result = _calculatorService.evaluate(argument);
        toolResult = 'Result: $result';
      } else {
        return (reply: 'I tried to use an unknown tool: $toolName', tool: null);
      }
    } catch (e) {
      toolResult = 'Tool error: $e';
    }

    final followUpHistory = List<ChatMessage>.from(historySoFar)
      ..add(ChatMessage(
        text: 'Tool result: $toolResult\n\nPlease respond to the user '
            'naturally using this information.',
        sender: Sender.user,
      ));

    final reply = await _geminiService.sendMessage(followUpHistory);
    return (reply: reply, tool: toolName);
  }

  List<Conversation> _touch(
    List<Conversation> list,
    String id,
    Conversation Function(Conversation) update,
  ) {
    final now = DateTime.now();
    final result = [
      for (final c in list) c.id == id ? update(c).copyWith(updatedAt: now) : c,
    ];
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  void _persist() => unawaited(_storage.save(state.conversations));
}
