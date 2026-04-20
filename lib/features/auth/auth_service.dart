import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  final _random = Random();


  // Anonymous login
  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print("Auth Error: $e");
      return null;
    }
  }

  // Check if logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Check if anonymous
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? true;
  }

  // Google Sign-In (with linking)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = _auth.currentUser;

      if (user != null && user.isAnonymous) {
        return await user.linkWithCredential(credential);
      }

      return await _auth.signInWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return await _auth.signInWithCredential(e.credential!);
      }

      print("Google Sign-In Error: ${e.message}");
      return null;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  String get displayName {
    final user = _auth.currentUser;
    return user?.displayName ?? "User";
  }

  Future<void> ensureDisplayName() async {
    final user = _auth.currentUser;

    if (user == null) return;

    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      return;
    }

    final name = _birdNames[_random.nextInt(_birdNames.length)];

    await user.updateDisplayName(name);
    await user.reload();
  }

  String get email {
    return _auth.currentUser?.email ?? '';
  }

  static const List<String> _birdNames = [
    "Sparrow",
    "Eagle",
    "Falcon",
    "Parrot",
    "Peacock",
    "Hawk",
    "Owl",
    "Flamingo",
    "Kingfisher",
    "Robin",
    "Swallow",
    "Heron",
    "Woodpecker",
    "Canary",
    "Pigeon",
  ];

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}