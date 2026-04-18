import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String author;
  final String authorProfilePicture;
  final String content;
  final DateTime timestamp;
  final List<String> mediaUrls;
  final String mediaType;
  final String location;
  final List<String> taggedUsers;
  final List<String> taggedUserNames;
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
    this.mediaUrls = const [],
    this.mediaType = '',
    this.location = '',
    this.taggedUsers = const [],
    this.taggedUserNames = const [],
    this.likedBy = const [],
    this.likes = 0,
    this.comments = 0,
  });

  bool isLikedBy(String userId) => likedBy.contains(userId);

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      author: data['author'] ?? 'Unknown User',
      authorProfilePicture: data['authorProfilePicture'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: data['mediaType'] ?? '',
      location: data['location'] ?? '',
      taggedUsers: List<String>.from(data['taggedUsers'] ?? []),
      taggedUserNames: List<String>.from(data['taggedUserNames'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'author': author,
      'authorProfilePicture': authorProfilePicture,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'location': location,
      'taggedUsers': taggedUsers,
      'taggedUserNames': taggedUserNames,
      'likedBy': likedBy,
      'likes': likes,
      'comments': comments,
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? author,
    String? authorProfilePicture,
    String? content,
    DateTime? timestamp,
    List<String>? mediaUrls,
    String? mediaType,
    String? location,
    List<String>? taggedUsers,
    List<String>? taggedUserNames,
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
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      location: location ?? this.location,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      taggedUserNames: taggedUserNames ?? this.taggedUserNames,
      likedBy: likedBy ?? this.likedBy,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}