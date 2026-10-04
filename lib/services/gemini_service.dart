import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/message_model.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-3.5-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _systemInstruction = '''
You are PocketAI, a helpful assistant with access to two tools:

1. Weather — when the user asks about weather in a city, respond with ONLY:
   TOOL_CALL:weather:<city name>

2. Calculator — when the user asks you to compute a math expression, respond with ONLY:
   TOOL_CALL:calculate:<expression>

Only emit a TOOL_CALL when a tool is genuinely needed to answer accurately.
Otherwise, respond normally and conversationally.
Never explain that you are about to call a tool — just emit the TOOL_CALL line, nothing else.
''';

  Future<String> sendMessage(List<ChatMessage> history) async {
    if (_apiKey.isEmpty) {
      throw GeminiServiceException(
        'Missing Gemini API key. Add GEMINI_API_KEY to your .env file.',
      );
    }

    final contents = history
        .map(
          (m) => {
            'role': m.sender == Sender.user ? 'user' : 'model',
            'parts': [
              {'text': m.text}
            ],
          },
        )
        .toList();

    final body = {
      'system_instruction': {
        'parts': [
          {'text': _systemInstruction}
        ]
      },
      'contents': contents,
    };

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw GeminiServiceException(
        'Network error contacting Gemini: $e',
      );
    }

    if (response.statusCode != 200) {
      throw GeminiServiceException(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      final text =
          decoded['candidates'][0]['content']['parts'][0]['text'] as String;

      return text.trim();
    } catch (e) {
      throw GeminiServiceException(
        'Could not parse Gemini response: $e',
      );
    }
  }
}

class GeminiServiceException implements Exception {
  final String message;

  GeminiServiceException(this.message);

  @override
  String toString() => message;
}
