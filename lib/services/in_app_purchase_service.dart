import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CustomerInfo? _customerInfo;
  Offerings? _offerings;

  final StreamController<bool> _proStatusController = StreamController.broadcast();
  Stream<bool> get proStatusStream => _proStatusController.stream;

  bool get isPro => _customerInfo?.entitlements.active["pro"]?.isActive ?? false;

  bool _configured = false;

  // -------------------------------
  // INIT - ONLY call AFTER Firebase user exists
  // -------------------------------
  Future<void> configureRevenueCat(String appUserId) async {
    if (_configured) return;

    if (kDebugMode) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final config = PurchasesConfiguration("goog_oyORKyiSAAkabPCZakCrOVujYYF")
      ..appUserID = appUserId;

    await Purchases.configure(config);
    _configured = true;

    await _fetchOfferings();
    _listenToCustomerUpdates();
  }

  // -------------------------------
  // FETCH
  // -------------------------------
  Future<void> _fetchOfferings() async {
    _offerings = await Purchases.getOfferings();
  }

  Offerings? get offerings => _offerings;
  Package? get monthlyPackage => _offerings?.current?.monthly;
  Package? get yearlyPackage => _offerings?.current?.annual;

  Future<void> fetchCustomerInfo() async {
    _customerInfo = await Purchases.getCustomerInfo();
    _emitProStatus();
    await _syncToFirebase();
  }

  // -------------------------------
  // PURCHASE with guard
  // -------------------------------
  Future<bool> purchase(Package package) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception("You must be logged in with Google to subscribe.");
    }

    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      _customerInfo = purchaseResult.customerInfo;
      _emitProStatus();
      await _syncToFirebase();
      return isPro;
    } catch (e) {
      print("Purchase error: $e");
      rethrow; // Let UI handle the error
    }
  }

  // -------------------------------
  // RESTORE
  // -------------------------------
  Future<void> restorePurchases() async {
    final user = _auth.currentUser;

    if (user == null || user.isAnonymous) {
      throw Exception("Login with Google to restore purchases.");
    }

    try {
      await Purchases.restorePurchases();
      final customerInfo = await Purchases.getCustomerInfo();
      _customerInfo = customerInfo;
      print("Print Customer Info ${_customerInfo}");
      _emitProStatus();
      await _syncToFirebase();
      print("Restore successful. isPro: $isPro");
    } catch (e) {
      print("Restore error: $e");
      rethrow;
    }
  }

  // -------------------------------
  // LISTENER
  // -------------------------------
  void _listenToCustomerUpdates() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      _customerInfo = customerInfo;
      _emitProStatus();
      await _syncToFirebase();
    });
  }

  void _emitProStatus() {
    _proStatusController.add(isPro);
  }

  // -------------------------------
  // FIREBASE SYNC
  // -------------------------------
  Future<void> _syncToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("users").doc(user.uid).set({
      "isPro": isPro,
      "entitlements": _customerInfo?.entitlements.all.keys.toList() ?? [],
      "lastUpdated": FieldValue.serverTimestamp(),
      "rcAppUserId": _customerInfo?.originalAppUserId,
    }, SetOptions(merge: true));
  }

  // -------------------------------
  // CLEANUP
  // -------------------------------
  void dispose() {
    _proStatusController.close();
  }
}