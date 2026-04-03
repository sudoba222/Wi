import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult({required this.isSuccess, required this.message});
}

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String profilePicture;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.profilePicture = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Save user profile to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': fullName,
        'email': email,
        'profilePicture': '',
      });
      return AuthResult(
        isSuccess: true,
        message: 'Account created successfully',
      );
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

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
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

    // Save user profile to Firestore if new user
    if (userCredential.additionalUserInfo?.isNewUser == true) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': userCredential.user!.displayName ?? '',
        'email': userCredential.user!.email ?? '',
        'profilePicture': userCredential.user!.photoURL ?? '',
      });
    }

    return AuthResult(isSuccess: true, message: 'Google sign in successful');
  } catch (e) {
    return AuthResult(isSuccess: false, message: e.toString());
  }
  }
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
