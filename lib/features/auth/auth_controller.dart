import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/model/app_user_model.dart';
import '../../core/utils/device_info_helper.dart';
import '../../services/in_app_purchase_service.dart';
import '../collection/collection_controller.dart';
import 'auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<void> initAuth() async {
    try {
      User? user = _authService.currentUser;

      user ??= await _authService.signInAnonymously();

      if (user == null) throw Exception("Failed to sign in anonymously");

      await _createOrUpdateUser(user);

      await CollectionsController().seedDefaults();

      await InAppPurchaseService().configureRevenueCat(user.uid);

      await InAppPurchaseService().fetchCustomerInfo();

      if (!user.isAnonymous) {
        final loginResult = await Purchases.logIn(user.uid);
        print("RevenueCat logged in with: ${loginResult.customerInfo.originalAppUserId}");
      }
    } catch (e) {
      print("AuthController init error: $e");
    }
  }

  // Call this when user upgrades from anonymous → Google
  Future<void> onGoogleSignInComplete() async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final loginResult = await Purchases.logIn(user.uid);
      print("RevenueCat linked: ${loginResult.customerInfo.originalAppUserId}");
      await InAppPurchaseService().fetchCustomerInfo();
      await _createOrUpdateUser(user);
    } catch (e) {
      print("RevenueCat login after Google: $e");
    }
  }

  Future<AppUser> _createOrUpdateUser(User user) async {
    final docRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await docRef.get();

    final deviceData = await getDeviceInfo();

    if (!doc.exists) {
      final newUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
        photoUrl: user.photoURL ?? '',
        isAnonymous: user.isAnonymous,
        appVersion: deviceData['appVersion'],
        deviceType: deviceData['deviceType'],
        platform: deviceData['platform'],
      );

      await docRef.set(newUser.toMap());

      return newUser;
    } else {
      final existingUser = AppUser.fromMap(doc.data()!);

      final updatedUser = existingUser.copyWith(
        name: user.displayName ?? existingUser.name,
        email: user.email,
        photoUrl: user.photoURL ?? existingUser.photoUrl,
        isAnonymous: user.isAnonymous,
        appVersion: deviceData['appVersion'],
        deviceType: deviceData['deviceType'],
        platform: deviceData['platform'],
      );

      await docRef.set({
        ...updatedUser.toMap(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return updatedUser;
    }
  }

  Future<void> deleteAccount() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("No user");

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    /// 🔐 1. Ensure recent login (CRITICAL)
    try {
      await user.delete(); // try directly first
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }
    }

    /// 🔁 2. Reauthenticate (Google)
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception("Reauthentication cancelled");
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);

    /// 🧹 3. Delete Firestore data (AFTER auth is valid)

    final collectionsRef =
    firestore.collection('users').doc(uid).collection('collections');

    final postsRef =
    firestore.collection('users').doc(uid).collection('posts');

    final collectionsSnap = await collectionsRef.get();
    final postsSnap = await postsRef.get();

    final batch = firestore.batch();

    for (final doc in collectionsSnap.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in postsSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    /// 🧹 4. Delete main user doc
    await firestore.collection('users').doc(uid).delete();

    /// 🔐 5. Delete auth user (FINAL)
    await user.delete();
  }
}