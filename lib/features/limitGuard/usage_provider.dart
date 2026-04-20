import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsageProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  int _total = 0;
  String _plan = 'free';

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<User?>? _authSub;

  int get total => _total;
  String get plan => _plan;

  int get limit => _plan == 'premium' ? 999999 : 20;

  double get progress => _total / limit;

  void init() {
    // 🔥 Listen to auth state
    _authSub = _auth.authStateChanges().listen((user) {
      _userSub?.cancel();

      if (user == null) {
        // ❌ Not logged in → reset state
        _total = 0;
        _plan = 'free';
        notifyListeners();
        return;
      }

      // ✅ Logged in → listen to Firestore
      _userSub = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        final data = doc.data() ?? {};

        _total = data['totalPostsCreated'] ?? 0;
        _plan = data['plan'] ?? 'free';

        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}