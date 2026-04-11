import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../models/experience.dart';
import '../models/education.dart';

class AuthResult {
  final bool isSuccess;
  final String message;
  AuthResult({required this.isSuccess, required this.message});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return AuthResult(isSuccess: true, message: 'Login successful');
    } catch (e) {
      return AuthResult(isSuccess: false, message: e.toString());
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': fullName,
        'email': email,
        'profilePicture': '',
        'jobTitle': '',
        'company': '',
        'location': '',
        'bio': '',
        'connections': 0,
        'posts': 0,
        'followers': 0,
        'skills': [],
      });
      return AuthResult(isSuccess: true, message: 'Account created successfully');
    } catch (e) {
      return AuthResult(isSuccess: false, message: e.toString());
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return AuthResult(isSuccess: false, message: 'Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'fullName': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'profilePicture': userCredential.user!.photoURL ?? '',
          'jobTitle': '',
          'company': '',
          'location': '',
          'bio': '',
          'connections': 0,
          'posts': 0,
          'followers': 0,
          'skills': [],
        });
      }

      return AuthResult(isSuccess: true, message: 'Google sign in successful');
    } catch (e) {
      return AuthResult(isSuccess: false, message: e.toString());
    }
  }

  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(isSuccess: true, message: 'Password reset email sent');
    } catch (e) {
      return AuthResult(isSuccess: false, message: e.toString());
    }
  }

  Future<UserProfile?> getFullUserProfile(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final experienceList = (data['experience'] as List<dynamic>? ?? [])
    .map((e) => Experience.fromMap(e as Map<String, dynamic>))
    .toList();

        final educationList = (data['education'] as List<dynamic>? ?? [])
            .map((e) => Education.fromMap(e as Map<String, dynamic>))
            .toList();

        return UserProfile(
          id: uid,
          name: data['fullName'] ?? '',
          jobTitle: data['jobTitle'] ?? '',
          company: data['company'] ?? '',
          location: data['location'] ?? '',
          bio: data['bio'] ?? '',
          profilePicture: data['profilePicture'] ?? '',
          connections: data['connections'] ?? 0,
          posts: data['posts'] ?? 0,
          followers: data['followers'] ?? 0,
          skills: List<String>.from(data['skills'] ?? []),
          experience: experienceList,
          education: educationList,
          isOwnProfile: true,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<void> setUserOnline() async {
  if (currentUser == null) return;
  await firestore.collection('users').doc(currentUser!.uid).update({
    'online': true,
    'lastSeen': FieldValue.serverTimestamp(),
  });
  }

  Future<void> setUserOffline() async {
  if (currentUser == null) return;
  await firestore.collection('users').doc(currentUser!.uid).update({
    'online': false,
    'lastSeen': FieldValue.serverTimestamp(),
  });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}