class SavedPost {
  final String id;
  final String title;
  final String url;

  final String? description;
  final String? image;
  final String? source;
  final String? domain;
  final List<String>? tags;

  final String? collectionId;

  final int reminderCount;
  final bool isDismissed;
  final DateTime? lastRemindedAt;

  final int visitCount;
  final DateTime? lastVisitedAt;

  final DateTime createdAt;

  SavedPost({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.image,
    this.source,
    this.domain,
    this.tags,
    this.collectionId,
    this.reminderCount = 0,
    this.isDismissed = false,
    this.visitCount = 0,
    this.lastVisitedAt,
    this.lastRemindedAt,
    required this.createdAt,
  });

  /// ─────────────────────────────────────────────
  /// 📤 To Firestore
  /// ─────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'image': image,
      'source': source,
      'domain': domain,
      'tags': tags,
      'collectionId': collectionId,
      'reminderCount': reminderCount,
      'visitCount': visitCount,
      'lastVisitedAt': lastVisitedAt?.toIso8601String(),
      'isDismissed': isDismissed,
      'lastRemindedAt': lastRemindedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// ─────────────────────────────────────────────
  /// 📥 From Firestore
  /// ─────────────────────────────────────────────
  factory SavedPost.fromMap(Map<String, dynamic> map) {
    return SavedPost(
      id: map['id'],
      title: map['title'],
      url: map['url'],
      description: map['description'],
      image: map['image'],
      source: map['source'],
      domain: map['domain'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,

      collectionId: map['collectionId'],

      visitCount: map['visitCount'] ?? 0,
      lastVisitedAt: map['lastVisitedAt'] != null
          ? DateTime.parse(map['lastVisitedAt'])
          : null,

      reminderCount: map['reminderCount'] ?? 0,
      isDismissed: map['isDismissed'] ?? false,
      lastRemindedAt: map['lastRemindedAt'] != null
          ? DateTime.parse(map['lastRemindedAt'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  /// ─────────────────────────────────────────────
  /// ✏️ CopyWith (VERY useful later 🔥)
  /// ─────────────────────────────────────────────
  SavedPost copyWith({
    String? title,
    String? url,
    String? description,
    String? image,
    String? source,
    String? domain,
    List<String>? tags,
    String? collectionId,
    int? visitCount,
    DateTime? lastVisitedAt,
    int? reminderCount,
    bool? isDismissed,
    DateTime? lastRemindedAt,
  }) {
    return SavedPost(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      image: image ?? this.image,
      source: source ?? this.source,
      domain: domain ?? this.domain,
      tags: tags ?? this.tags,
      collectionId: collectionId ?? this.collectionId,
      reminderCount: reminderCount ?? this.reminderCount,
      visitCount: visitCount ?? this.visitCount,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      isDismissed: isDismissed ?? this.isDismissed,
      lastRemindedAt: lastRemindedAt ?? this.lastRemindedAt,
      createdAt: createdAt,
    );
  }
}