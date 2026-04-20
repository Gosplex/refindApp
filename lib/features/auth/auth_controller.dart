import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/in_app_purchase_service.dart';
import 'auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<void> initAuth() async {
    try {
      User? user = _authService.currentUser;

      user ??= await _authService.signInAnonymously();

      if (user == null) throw Exception("Failed to sign in anonymously");

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
    } catch (e) {
      print("RevenueCat login after Google: $e");
    }
  }
}