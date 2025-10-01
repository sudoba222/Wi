import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String author;
  final String authorProfilePicture;
  final String content;
  final DateTime timestamp;
  List<String> likedBy;
  int likes;
  int comments;

  Post({
    required this.id,
    required this.authorId,
    required this.author,
    this.authorProfilePicture = '',
    required this.content,
    required this.timestamp,
    this.likedBy = const [],
    this.likes = 0,
    this.comments = 0,
  });

  // Check if current user liked this post
  bool isLikedBy(String userId) => likedBy.contains(userId);

  // Convert from Firestore document
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      author: data['author'] ?? 'Unknown User',
      authorProfilePicture: data['authorProfilePicture'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'author': author,
      'authorProfilePicture': authorProfilePicture,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likedBy': likedBy,
      'likes': likes,
      'comments': comments,
    };
  }

  // Create a copy with updated fields
  Post copyWith({
    String? id,
    String? authorId,
    String? author,
    String? authorProfilePicture,
    String? content,
    DateTime? timestamp,
    List<String>? likedBy,
    int? likes,
    int? comments,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likedBy: likedBy ?? this.likedBy,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}
