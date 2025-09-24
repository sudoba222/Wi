import 'message.dart';

class Conversation {
  final String id;
  final String userName;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.userName,
    required this.messages,
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