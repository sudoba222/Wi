import 'message.dart';

/// In-memory conversation model used by GlobalData and MessagesPage.
class Conversation {
  final String id;
  final String userName;
  final List<Message> messages;

  /// Whether this chat is pinned to the top (max 3 allowed).
  bool isPinned;

  Conversation({
    required this.id,
    required this.userName,
    required this.messages,
    this.isPinned = false,
  });

  String get lastMessage {
    if (messages.isEmpty) return 'No messages yet';
    return messages.last.text;
  }

  String get lastMessageTime {
    if (messages.isEmpty) return 'Now';
    return messages.last.time;
  }
}
