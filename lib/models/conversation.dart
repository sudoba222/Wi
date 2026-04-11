import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String userName;
  final String otherUserId;
  final String otherUserProfilePicture;
  bool isPinned;
  String lastMessage;
  String lastMessageTime;

  Conversation({
    required this.id,
    required this.userName,
    required this.otherUserId,
    this.otherUserProfilePicture = '',
    this.isPinned = false,
    this.lastMessage = 'No messages yet',
    this.lastMessageTime = '',
  });

  factory Conversation.fromFirestore(
    DocumentSnapshot doc,
    String currentUserId,
    String otherUserName,
    String otherUserId,
    String otherUserProfilePicture,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['lastMessageTime'] as Timestamp?)?.toDate();
    String timeStr = '';
    if (timestamp != null) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      timeStr = '$hour:$minute';
    }

    return Conversation(
      id: doc.id,
      userName: otherUserName,
      otherUserId: otherUserId,
      otherUserProfilePicture: otherUserProfilePicture,
      lastMessage: data['lastMessage'] ?? 'No messages yet',
      lastMessageTime: timeStr,
    );
  }
}