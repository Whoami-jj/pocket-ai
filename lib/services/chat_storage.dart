import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

class ChatStorage {
  static const _key = 'pocketai_conversations_v1';

  /// Oldest chats are dropped beyond this many.
  static const maxConversations = 50;

  Future<List<Conversation>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      // Corrupted or unreadable data: start with an empty history.
      return [];
    }
  }

  Future<void> save(List<Conversation> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sorted = [...conversations]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final trimmed = sorted.take(maxConversations).toList();
      await prefs.setString(
        _key,
        jsonEncode(trimmed.map((c) => c.toJson()).toList()),
      );
    } catch (_) {
      // Saving is best-effort; the chat keeps working in memory.
    }
  }
}
