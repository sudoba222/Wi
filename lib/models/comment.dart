import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String author;
  final String authorProfilePicture;
  final String content;
  final DateTime timestamp;
  final List<String> likedBy;
  final bool isActive;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.author,
    this.authorProfilePicture = '',
    required this.content,
    required this.timestamp,
    this.likedBy = const [],
    this.isActive = true,
  });

  // Get number of likes
  int get likes => likedBy.length;

  // Check if current user liked this comment
  bool isLikedBy(String userId) => likedBy.contains(userId);

  // Convert from Firestore document
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      author: data['author'] ?? 'Unknown User',
      authorProfilePicture: data['authorProfilePicture'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'author': author,
      'authorProfilePicture': authorProfilePicture,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likedBy': likedBy,
      'isActive': isActive,
    };
  }

  // Create a copy with updated fields
  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? author,
    String? authorProfilePicture,
    String? content,
    DateTime? timestamp,
    List<String>? likedBy,
    bool? isActive,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likedBy: likedBy ?? this.likedBy,
      isActive: isActive ?? this.isActive,
    );
  }
}
