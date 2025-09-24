import '../models/post.dart';
import '../models/conversation.dart';
import '../models/message.dart';

// Global Data Storage (In production, use Firebase/Backend)
class GlobalData {
  static List<Post> posts = [];
  static List<Conversation> conversations = [];

  static void addPost(Post post) {
    posts.insert(0, post);
  }

  static void addMessage(String conversationId, Message message) {
    final conversation = conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => Conversation(id: conversationId, userName: '', messages: []),
    );
    conversation.messages.add(message);
  }

  static void createConversation(String userName) {
    final newId = (conversations.length + 1).toString();
    conversations.add(
      Conversation(
        id: newId,
        userName: userName,
        messages: [],
      ),
    );
  }
}