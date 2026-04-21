import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
}