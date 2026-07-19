import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// ─────────────────────────────────────────────
/// 🔁  userSwitchStream — auth-aware "switchMap"
///
/// Rebuilds the inner stream whenever the signed-in user's uid changes,
/// cancelling the previous inner subscription.
///
/// This replaces the old `authStateChanges().asyncExpand(...)` pattern, which
/// was broken: `asyncExpand` waits for the inner stream to *complete* before
/// handling the next auth event, but a Firestore `snapshots()` stream never
/// completes. So once it locked onto the anonymous uid it never switched when
/// the user signed in as a different account — the data only appeared after an
/// app restart recreated the stream.
///
/// We listen to [FirebaseAuth.userChanges] (fires on sign-in / sign-out /
/// link / profile & token refresh) and de-dupe by uid, so redundant emits
/// (e.g. hourly token refresh) don't re-subscribe, but a real account switch
/// tears down the old stream and starts a fresh one immediately.
Stream<T> userSwitchStream<T>(
  Stream<T> Function(String uid) build, {
  required T whenSignedOut,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? innerSub;
  StreamSubscription<User?>? authSub;
  String? currentUid;
  var initialized = false;

  void onUser(User? user) {
    final uid = user?.uid;
    // Same account (or repeat token refresh) → keep the current inner stream.
    if (initialized && uid == currentUid) return;
    initialized = true;
    currentUid = uid;

    innerSub?.cancel();
    innerSub = null;

    if (uid == null) {
      controller.add(whenSignedOut);
    } else {
      innerSub = build(uid).listen(
        controller.add,
        onError: controller.addError,
      );
    }
  }

  controller = StreamController<T>(
    onListen: () {
      authSub = FirebaseAuth.instance.userChanges().listen(onUser);
    },
    onCancel: () async {
      await innerSub?.cancel();
      await authSub?.cancel();
      innerSub = null;
      authSub = null;
    },
  );

  return controller.stream;
}
