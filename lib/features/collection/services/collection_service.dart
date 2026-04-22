import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/model/app_user_model.dart';
import '../models/collection_model.dart';

class CollectionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  CollectionReference get _collectionsRef =>
      _firestore.collection('users').doc(userId).collection('collections');

  /// ─────────────────────────────────────────────
  /// ➕ Create Collection (USES MODEL ✅)
  /// ─────────────────────────────────────────────
  Future<void> createCollection(CollectionModel collection) async {
    await _collectionsRef.doc(collection.id).set({
      ...collection.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ─────────────────────────────────────────────
  /// 📥 Get Collections (Realtime)
  /// ─────────────────────────────────────────────
  Stream<List<CollectionModel>> getCollectionsStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collections')
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CollectionModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    });
  }

  /// ─────────────────────────────────────────────
  /// ✏️ Update
  /// ─────────────────────────────────────────────
  Future<void> updateCollection(
      String id, Map<String, dynamic> data) async {
    await _collectionsRef.doc(id).update(data);
  }

  Future<bool> togglePinSmart(CollectionModel collection) async {
    final user = await getCurrentUser();

    if (user == null) return false;

    if (!user.isPro) {
      return false;
    }

    await _collectionsRef.doc(collection.id).set({
      'isPinned': !collection.isPinned,
    }, SetOptions(merge: true));

    return true;
  }

  /// ─────────────────────────────────────────────
  /// ❌ Delete
  /// ─────────────────────────────────────────────
  Future<void> deleteCollection(
      String id, {
        bool deletePosts = false,
      }) async {
    final postsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('posts');

    final snapshot =
    await postsRef.where('collectionId', isEqualTo: id).get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      if (deletePosts) {
        batch.delete(doc.reference);
      } else {
        batch.update(doc.reference, {
          'collectionId': null,
        });
      }
    }

    batch.delete(_collectionsRef.doc(id));

    await batch.commit();
  }

  /// ─────────────────────────────────────────────
  /// 🌱 Seed Default Collections (USES MODEL ✅)
  /// ─────────────────────────────────────────────
  Future<void> seedDefaultCollections() async {
    final snapshot = await _collectionsRef.limit(1).get();

    if (snapshot.docs.isNotEmpty) return;

    final now = DateTime.now();

    final defaults = [
      CollectionModel(
        id: _collectionsRef.doc().id,
        name: 'Learning',
        description: 'Articles, blogs, and things to learn',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CollectionModel(
        id: _collectionsRef.doc().id,
        name: 'Startup Ideas',
        description: 'Business ideas and inspiration',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CollectionModel(
        id: _collectionsRef.doc().id,
        name: 'Watch Later',
        description: 'Videos to watch later',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CollectionModel(
        id: _collectionsRef.doc().id,
        name: 'Money Ideas',
        description: 'Ways to make and grow money',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CollectionModel(
        id: _collectionsRef.doc().id,
        name: 'Design',
        description: 'UI, UX, and design inspiration',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CollectionModel(
        id: _collectionsRef.doc().id,
        name: 'Health',
        description: 'Fitness, wellness, and health tips',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
    ];

    final batch = _firestore.batch();

    for (final collection in defaults) {
      final docRef = _collectionsRef.doc(collection.id);

      batch.set(docRef, {
        ...collection.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<bool> canAddCollection() async {
    final user = await getCurrentUser();

    if (user == null) return false;

    if (user.plan == 'premium') return true;

    return user.totalCollectionsCreated < 3;
  }

  Future<AppUser?> getCurrentUser() async {
    final doc =
    await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

  Future<void> incrementCollectionUsage() async {
    await _firestore.collection('users').doc(userId).set({
      'totalCollectionsCreated': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}