import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/message_model.dart';
import '../services/gemini_service.dart';
import '../services/weather_service.dart';
import '../services/calculator_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GeminiService _geminiService;
  final WeatherService _weatherService;
  final CalculatorService _calculatorService;

  ChatBloc({
    GeminiService? geminiService,
    WeatherService? weatherService,
    CalculatorService? calculatorService,
  })  : _geminiService = geminiService ?? GeminiService(),
        _weatherService = weatherService ?? WeatherService(),
        _calculatorService = calculatorService ?? CalculatorService(),
        super(const ChatState()) {
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = ChatMessage(text: event.text, sender: Sender.user);
    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);

    emit(
      state.copyWith(messages: updatedMessages, isLoading: true, error: null),
    );

    try {
      String reply = await _geminiService.sendMessage(updatedMessages);

      if (reply.startsWith('TOOL_CALL:')) {
        reply = await _handleToolCall(reply, updatedMessages);
      }

      final aiMessage = ChatMessage(text: reply, sender: Sender.ai);
      emit(state.copyWith(
        messages: [...updatedMessages, aiMessage],
        isLoading: false,
      ));
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Something went wrong: $e',
        sender: Sender.ai,
        isError: true,
      );
      emit(state.copyWith(
        messages: [...updatedMessages, errorMessage],
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<String> _handleToolCall(
    String toolCallLine,
    List<ChatMessage> historySoFar,
  ) async {
    final parts = toolCallLine.split(':');
    if (parts.length < 3) {
      return "I tried to use a tool but couldn't parse the request.";
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
        return "I tried to use an unknown tool: $toolName";
      }
    } catch (e) {
      toolResult = 'Tool error: $e';
    }

    // Feed the tool result back to Gemini so it can phrase a natural reply.
    final followUpHistory = List<ChatMessage>.from(historySoFar)
      ..add(ChatMessage(
        text: 'Tool result: $toolResult\n\nPlease respond to the user '
            'naturally using this information.',
        sender: Sender.user,
      ));

    return _geminiService.sendMessage(followUpHistory);
  }
}
