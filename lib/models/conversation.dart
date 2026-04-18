import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String userName;
  final String otherUserId;
  final String otherUserProfilePicture;
  bool isPinned;
  String lastMessage;
  String lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  Conversation({
    required this.id,
    required this.userName,
    required this.otherUserId,
    this.otherUserProfilePicture = '',
    this.isPinned = false,
    this.lastMessage = 'No messages yet',
    this.lastMessageTime = '',
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory Conversation.fromFirestore(
    DocumentSnapshot doc,
    String currentUserId,
    String otherUserName,
    String otherUserId,
    String otherUserProfilePicture, {
    int unreadCount = 0,
    bool isOnline = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['lastMessageTime'] as Timestamp?)?.toDate();
    String timeStr = '';
    if (timestamp != null) {
      final now = DateTime.now();
      final diff = now.difference(timestamp);
      if (diff.inDays == 0) {
        final hour = timestamp.hour.toString().padLeft(2, '0');
        final minute = timestamp.minute.toString().padLeft(2, '0');
        timeStr = '$hour:$minute';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        timeStr = days[timestamp.weekday - 1];
      } else {
        timeStr = '${timestamp.day}/${timestamp.month}';
      }
    }

    final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
    final computedUnread = (unreadCounts[currentUserId] as int?) ?? unreadCount;

    return Conversation(
      id: doc.id,
      userName: otherUserName,
      otherUserId: otherUserId,
      otherUserProfilePicture: otherUserProfilePicture,
      lastMessage: data['lastMessage'] ?? 'No messages yet',
      lastMessageTime: timeStr,
      unreadCount: computedUnread,
      isOnline: isOnline,
    );
  }
}