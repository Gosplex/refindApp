import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final bool isAnonymous;

  final DateTime? createdAt;
  final DateTime? lastSeen;

  // 🔥 Usage
  final int totalPostsCreated;
  final int totalCollectionsCreated;

  // 💰 Plan / Subscription
  final String plan;
  final bool isPro;
  final List<String> entitlements;

  // 📱 App metadata
  final String? appVersion;
  final String? deviceType; // android / ios / web
  final String? platform;   // android 14, ios 17, chrome etc
  final String? rcAppUserId;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.isAnonymous,
    this.createdAt,
    this.lastSeen,
    this.totalPostsCreated = 0,
    this.totalCollectionsCreated = 0,
    this.plan = 'free',
    this.isPro = false,
    this.entitlements = const [],
    this.appVersion,
    this.deviceType,
    this.platform,
    this.rcAppUserId,
  });

  // 🔁 FROM FIRESTORE
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? 'User',
      photoUrl: map['photoUrl'] ?? '',
      isAnonymous: map['isAnonymous'] ?? true,

      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),

      totalPostsCreated: map['totalPostsCreated'] ?? 0,
      totalCollectionsCreated: map['totalCollectionsCreated'] ?? 0,

      plan: map['plan'] ?? 'free',
      isPro: map['isPro'] ?? false,
      entitlements: List<String>.from(map['entitlements'] ?? []),

      appVersion: map['appVersion'],
      deviceType: map['deviceType'],
      platform: map['platform'],
      rcAppUserId: map['rcAppUserId'],
    );
  }

  // 🔁 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,

      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),

      'lastSeen': FieldValue.serverTimestamp(),

      'totalPostsCreated': totalPostsCreated,
      'totalCollectionsCreated': totalCollectionsCreated,

      'plan': plan,
      'isPro': isPro,
      'entitlements': entitlements,

      'appVersion': appVersion,
      'deviceType': deviceType,
      'platform': platform,

      'rcAppUserId': rcAppUserId,
    };
  }

  // 🔄 COPY WITH
  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? plan,
    bool? isPro,
    bool? isAnonymous,
    List<String>? entitlements,
    int? totalPostsCreated,
    int? totalCollectionsCreated,
    String? appVersion,
    String? deviceType,
    String? platform,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.name,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
      lastSeen: lastSeen,
      totalPostsCreated:
      totalPostsCreated ?? this.totalPostsCreated,
      totalCollectionsCreated:
      totalCollectionsCreated ?? this.totalCollectionsCreated,
      plan: plan ?? this.plan,
      isPro: isPro ?? this.isPro,
      entitlements: entitlements ?? this.entitlements,
      appVersion: appVersion ?? this.appVersion,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      rcAppUserId: rcAppUserId,
    );
  }
}