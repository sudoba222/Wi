import 'experience.dart';
import 'education.dart';

class UserProfile {
  final String id;
  final String name;
  final String jobTitle;
  final String company;
  final String location;
  final String bio;
  final String profilePicture;
  final String coverImage;
  final int connections;
  final int posts;
  final int followers;
  final List<Experience> experience;
  final List<Education> education;
  final List<String> skills;
  final bool isOwnProfile;

  UserProfile({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.bio,
    this.profilePicture = '',
    this.coverImage = '',
    this.connections = 0,
    this.posts = 0,
    this.followers = 0,
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.isOwnProfile = false,
  });
}