import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user_profile.dart';
import 'auth_services.dart';
// ignore_for_file: avoid_print

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get posts stream
  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Post>> getAlgorithmicFeedStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('connections')
        .snapshots()
        .asyncMap((connectionsSnap) async {
          final connectionIds = connectionsSnap.docs.map((d) => d.id).toSet();
          final postsSnap = await _firestore
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .get();
          final allPosts = postsSnap.docs.map((doc) => Post.fromFirestore(doc)).toList();
          final connectionPosts = allPosts.where((p) => connectionIds.contains(p.authorId)).toList();
          final otherPosts = allPosts.where((p) => !connectionIds.contains(p.authorId)).toList();
          return [...connectionPosts, ...otherPosts];
        });
  }

  // Create a new post
  Future<bool> createPost({
  required String content,
  List<String> mediaUrls = const [],
  String mediaType = '',
  String location = '',
  List<String> taggedUsers = const [],
}  ) async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final authService = AuthService();
    final userProfile = await authService.getFullUserProfile(currentUser.uid);
    if (userProfile == null) return false;

    final postRef = _firestore.collection('posts').doc();
    final post = Post(
      id: postRef.id,
      authorId: currentUser.uid,
      author: userProfile.name,
      authorProfilePicture: userProfile.profilePicture,
      content: content,
      timestamp: DateTime.now(),
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      location: location,
      taggedUsers: taggedUsers,
    );

    await postRef.set(post.toFirestore());
    return true;
  } catch (e) {
    print('Error creating post: $e');
    return false;
  }
  }
  // Toggle like on a post
  Future<bool> toggleLike(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      if (!postDoc.exists) return false;

      final post = Post.fromFirestore(postDoc);
      final likedBy = List<String>.from(post.likedBy);

      if (likedBy.contains(currentUser.uid)) {
        likedBy.remove(currentUser.uid);
      } else {
        likedBy.add(currentUser.uid);
      }

      await postRef.update({'likedBy': likedBy});
      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      if (!postDoc.exists) return false;

      final post = Post.fromFirestore(postDoc);
      if (post.authorId != currentUser.uid) return false;

      await postRef.delete();
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Add sample posts for testing
  Future<void> addSamplePosts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final authService = AuthService();
      final userProfile = await authService.getFullUserProfile(currentUser.uid);
      if (userProfile == null) return;

      final samplePosts = [
        {
          'content':
              'Excited to announce our new partnership with local businesses in Dushanbe! This collaboration will bring innovative solutions to the Tajikistan market.',
          'author': userProfile.name,
          'authorId': currentUser.uid,
          'authorProfilePicture': userProfile.profilePicture,
        },
        {
          'content':
              'Just finished an amazing workshop on digital transformation. The future of business in Central Asia looks bright! #Entrepreneurship #Tajikistan',
          'author': userProfile.name,
          'authorId': currentUser.uid,
          'authorProfilePicture': userProfile.profilePicture,
        },
        {
          'content':
              'Looking for talented developers to join our team. If you\'re passionate about creating impactful software solutions, let\'s connect!',
          'author': userProfile.name,
          'authorId': currentUser.uid,
          'authorProfilePicture': userProfile.profilePicture,
        },
      ];

      for (final samplePost in samplePosts) {
        final postRef = _firestore.collection('posts').doc();
        final post = Post(
          id: postRef.id,
          authorId: samplePost['authorId'] as String,
          author: samplePost['author'] as String,
          authorProfilePicture: samplePost['authorProfilePicture'] as String,
          content: samplePost['content'] as String,
          timestamp: DateTime.now().subtract(
            Duration(minutes: samplePosts.indexOf(samplePost) * 30),
          ),
        );
        await postRef.set(post.toFirestore());
      }
    } catch (e) {
      print('Error adding sample posts: $e');
    }
  }

  // Get comments for a post
  Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  // Add a comment to a post
  Future<bool> addComment(String postId, String content) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final authService = AuthService();
      final userProfile = await authService.getFullUserProfile(currentUser.uid);
      if (userProfile == null) return false;

      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      final comment = Comment(
        id: commentRef.id,
        postId: postId,
        authorId: currentUser.uid,
        author: userProfile.name,
        authorProfilePicture: userProfile.profilePicture,
        content: content,
        timestamp: DateTime.now(),
      );

      await commentRef.set(comment.toFirestore());
      await _updateCommentCount(postId);

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Toggle like on a comment
  Future<bool> toggleCommentLike(String postId, String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) return false;

      final comment = Comment.fromFirestore(commentDoc);
      final likedBy = List<String>.from(comment.likedBy);

      if (likedBy.contains(currentUser.uid)) {
        likedBy.remove(currentUser.uid);
      } else {
        likedBy.add(currentUser.uid);
      }

      await commentRef.update({'likedBy': likedBy});
      return true;
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) return false;

      final comment = Comment.fromFirestore(commentDoc);
      if (comment.authorId != currentUser.uid) return false;

      await commentRef.delete();
      await _updateCommentCount(postId);

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Update comment count on post
  Future<void> _updateCommentCount(String postId) async {
    try {
      final commentsQuery = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      final commentCount = commentsQuery.docs.length;

      await _firestore.collection('posts').doc(postId).update({
        'comments': commentCount,
      });
    } catch (e) {
      print('Error updating comment count: $e');
    }
  }
}