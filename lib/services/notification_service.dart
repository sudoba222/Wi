import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> send({
    required String toUserId,
    required String type,
    required String message,
    String senderName = '',
    String? senderPhoto,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (toUserId == currentUser.uid) return;

    await _firestore
        .collection('notifications')
        .doc(toUserId)
        .collection('items')
        .add({
      'type': type,
      'message': message,
      'senderName': senderName,
      'senderPhoto': senderPhoto ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  static Stream<int> unreadCountStream(String userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .doc(userId)
      .collection('items')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);
}
}