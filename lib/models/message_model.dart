enum Sender { user, ai }

class ChatMessage {
  final String text;
  final Sender sender;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.sender,
    this.isError = false,
  });
}
