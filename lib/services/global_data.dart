import '../models/post.dart';
import '../models/conversation.dart';

class GlobalData {
  static List<Post> posts = [];

  static void addPost(Post post) {
    posts.insert(0, post);
  }
}