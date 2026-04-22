import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../saved_posts/models/saved_post_model.dart';
import '../saved_posts/services/saved_posts_service.dart';
import 'models/analytics_model.dart';
import 'services/analytic_service.dart';

class AnalyticsController {
  final SavedPostsService _postsService = SavedPostsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  /// ─────────────────────────────────────────────
  /// 🔁 Stream analytics (REAL FIX)
  /// ─────────────────────────────────────────────
  Stream<AnalyticsModel> getAnalyticsStream() {
    return _postsService.getPostsStream().asyncMap((posts) async {
      final collectionMap = await _getCollectionMap();

      return AnalyticsService.generate(
        posts,
        collectionMap,
      );
    });
  }

  /// ─────────────────────────────────────────────
  /// 📥 One-time fetch
  /// ─────────────────────────────────────────────
  Future<AnalyticsModel> getAnalyticsOnce() async {
    final posts = await _postsService.getPostsStream().first;
    final collectionMap = await _getCollectionMap();

    return AnalyticsService.generate(
      posts,
      collectionMap,
    );
  }

  /// ─────────────────────────────────────────────
  /// 🔍 Manual generate
  /// ─────────────────────────────────────────────
  Future<AnalyticsModel> generateFromPosts(
      List<SavedPost> posts,
      ) async {
    final collectionMap = await _getCollectionMap();

    return AnalyticsService.generate(
      posts,
      collectionMap,
    );
  }

  /// ─────────────────────────────────────────────
  /// 📦 COLLECTION MAP (ID → NAME)
  /// ─────────────────────────────────────────────
  Future<Map<String, String>> _getCollectionMap() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('collections')
        .get();

    return {
      for (var doc in snapshot.docs)
        doc.id: doc.data()['name'] ?? 'Unknown'
    };
  }
}