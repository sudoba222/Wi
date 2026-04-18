import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';
import '../models/message.dart';


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  String _conversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Extract the other participant's UID from a conversationId
  String _otherUserId(String conversationId) {
    return conversationId
        .split('_')
        .firstWhere((id) => id != currentUserId, orElse: () => '');
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

          // Online status: lastSeen within 2 minutes
          bool isOnline = false;
          final onlineRaw = userData['online'] ?? false;
          final lastSeen = userData['lastSeen'];
          if (onlineRaw && lastSeen != null) {
            final lastSeenTime = (lastSeen as Timestamp).toDate();
            isOnline = DateTime.now().difference(lastSeenTime).inMinutes < 2;
          }

          conversations.add(Conversation.fromFirestore(
            doc,
            currentUserId,
            otherUserName,
            otherUserId,
            otherUserPicture,
            isOnline: isOnline,
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
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
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
      'readBy': [currentUserId],
      'reactions': {},
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
    });

    final otherId = _otherUserId(conversationId);
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': now,
      if (otherId.isNotEmpty) 'unreadCounts.$otherId': FieldValue.increment(1),
    });
  }

  // Toggle emoji reaction on a message
  Future<void> toggleReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final doc = await msgRef.get();
    final data = doc.data() ?? {};
    final reactions = Map<String, String>.from(data['reactions'] ?? {});

    if (reactions[currentUserId] == emoji) {
      reactions.remove(currentUserId);
    } else {
      reactions[currentUserId] = emoji;
    }

    await msgRef.update({'reactions': reactions});
  }

  // Delete a single message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
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
      'readBy': [currentUserId],
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

  // Mark all messages in conversation as read by current user
Future<void> markMessagesAsRead(String conversationId) async {
  final messagesRef = _firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages');

  final unread = await messagesRef
      .where('senderId', isNotEqualTo: currentUserId)
      .get();

  final batch = _firestore.batch();
  for (final doc in unread.docs) {
    final readBy = List<String>.from(doc.data()['readBy'] ?? []);
    if (!readBy.contains(currentUserId)) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }
  await batch.commit();

  // Reset unread counter for current user
  await _firestore.collection('conversations').doc(conversationId).update({
    'unreadCounts.$currentUserId': 0,
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

  // Stream of total unread messages across all conversations
  Stream<int> getTotalUnreadStream() {
    if (currentUserId.isEmpty) return Stream.value(0);
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final counts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
        total += (counts[currentUserId] as int?) ?? 0;
      }
      return total;
    });
  }

  // Typing indicator
  Future<void> setTyping(String conversationId, bool isTyping) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'typingUsers': isTyping
            ? FieldValue.arrayUnion([currentUserId])
            : FieldValue.arrayRemove([currentUserId]),
      });
    } catch (_) {}
  }

  Stream<bool> getTypingStream(String conversationId, String otherUserId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      final data = doc.data() ?? {};
      final typing = List<String>.from(data['typingUsers'] ?? []);
      return typing.contains(otherUserId);
    });
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