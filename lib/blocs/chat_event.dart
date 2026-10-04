import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatsEvent extends ChatEvent {
  const LoadChatsEvent();
}

class SendMessageEvent extends ChatEvent {
  final String text;
  const SendMessageEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class NewChatEvent extends ChatEvent {
  const NewChatEvent();
}

class SelectChatEvent extends ChatEvent {
  final String id;
  const SelectChatEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteChatEvent extends ChatEvent {
  final String id;
  const DeleteChatEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RenameChatEvent extends ChatEvent {
  final String id;
  final String title;
  const RenameChatEvent(this.id, this.title);

  @override
  List<Object?> get props => [id, title];
}

class ClearAllChatsEvent extends ChatEvent {
  const ClearAllChatsEvent();
}
