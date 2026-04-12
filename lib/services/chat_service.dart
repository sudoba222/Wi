import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';
import '../models/message.dart';


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Generate a consistent conversation ID for two users
  String _conversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Get or create a conversation between current user and another user
  Future<String> getOrCreateConversation(String otherUserId) async {
    final convId = _conversationId(currentUserId, otherUserId);
    final convRef = _firestore.collection('conversations').doc(convId);
    final convDoc = await convRef.get();

    if (!convDoc.exists) {
      await convRef.set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return convId;
  }

  // Stream all conversations for the current user
  Stream<List<Conversation>> getConversationsStream() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <Conversation>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        // Fetch other user's profile
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(otherUserId)
              .get();
          final userData = userDoc.data() ?? {};
          final otherUserName = userData['fullName'] ?? userData['email'] ?? 'Unknown';
          final otherUserPicture = userData['profilePicture'] ?? '';

          conversations.add(Conversation.fromFirestore(
            doc,
            currentUserId,
            otherUserName,
            otherUserId,
            otherUserPicture,
          ));
        } catch (e) {
          print('Error fetching user: $e');
        }
      }

      return conversations;
    });
  }

  // Stream messages for a conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc, currentUserId))
            .toList());
  }

  // Send a text message
  Future<void> sendMessage(String conversationId, String text) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final now = Timestamp.now();

    await messageRef.set({
      'text': text,
      'senderId': currentUserId,
      'timestamp': now,
      'type': 'text',
      'meeting': null,
    });

    // Update last message in conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': now,
    });
  }

  // check if the user is online or not
  Stream<Map<String, dynamic>> getUserPresenceStream(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
    final data = doc.data() ?? {};
    return {
      'online': data['online'] ?? false,
      'lastSeen': data['lastSeen'],
    };
  });
}
  // Send a meeting invite
  Future<void> sendMeetingInvite(
    String conversationId,
    String title,
    String date,
    String time,
  ) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final now = Timestamp.now();

    await messageRef.set({
      'text': 'Meeting invite: $title',
      'senderId': currentUserId,
      'timestamp': now,
      'type': 'meeting',
      'meeting': {
        'title': title,
        'date': date,
        'time': time,
        'status': 'pending',
      },
    });

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': 'Meeting invite: $title',
      'lastMessageTime': now,
    });
  }

  // Update meeting status (accept/decline)
  Future<void> updateMeetingStatus(
    String conversationId,
    String messageId,
    String status,
  ) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'meeting.status': status});
  }

// Toggle pin/unpin conversation
  Future<void> togglePin(String conversationId, bool isPinned) async {
  await _firestore
      .collection('users')
      .doc(currentUserId)
      .update({
    'pinnedConversations': isPinned
        ? FieldValue.arrayUnion([conversationId])
        : FieldValue.arrayRemove([conversationId]),
  });
  }

Stream<Set<String>> getPinnedConversationsStream() {
  return _firestore
      .collection('users')
      .doc(currentUserId)
      .snapshots()
      .map((doc) {
    final data = doc.data() ?? {};
    final pinned = List<String>.from(data['pinnedConversations'] ?? []);
    return pinned.toSet();
  });
  }
  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final messages = await messagesRef.get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('conversations').doc(conversationId).delete();
  }

  // Clear messages in a conversation
  Future<void> clearMessages(String conversationId) async {
    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final messages = await messagesRef.get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}