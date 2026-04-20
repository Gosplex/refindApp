import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_post_model.dart';

class SavedPostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  CollectionReference get _postsRef =>
      _firestore.collection('users').doc(userId).collection('posts');

  /// ➕ Add Post
  Future<void> addPost(SavedPost post) async {
    await _postsRef.doc(post.id).set(post.toMap());
  }

  /// 📥 Get Posts (Realtime)
  Stream<List<SavedPost>> getPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          SavedPost.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<SavedPost>> getPostsStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value([]); // no user → empty
      }

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => SavedPost.fromMap(doc.data()))
            .toList();
      });
    });
  }

  /// ❌ Delete Post
  Future<void> deletePost(String id) async {
    await _postsRef.doc(id).delete();
  }

  /// 🔄 Update Post
  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    await _postsRef.doc(id).update(data);
  }

  /// 🚫 Dismiss Post (IMPORTANT)
  Future<void> dismissPost(String id) async {
    await _postsRef.doc(id).update({
      'isDismissed': true,
    });
  }

  /// 🔔 Increment Reminder Count
  Future<void> incrementReminder(String id) async {
    await _postsRef.doc(id).update({
      'reminderCount': FieldValue.increment(1),
      'lastRemindedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> canAddPost() async {
    final doc = await _userRef.get();

    final data = doc.data() as Map<String, dynamic>? ?? {};

    final isPro = data['isPro'] ?? false;
    final total = data['totalPostsCreated'] ?? 0;

    if (isPro) return true;

    return total < 20;
  }

  Future<void> incrementPostUsage() async {
    await _userRef.set({
      'totalPostsCreated': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAllPosts() async {
    final snapshot = await _postsRef.get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  DocumentReference get _userRef =>
      _firestore.collection('users').doc(userId);
}