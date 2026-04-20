class SavedPost {
  final String id;
  final String title;
  final String url;

  final String? description;
  final String? image;
  final String? source;
  final String? domain;
  final List<String>? tags;

  final int reminderCount;
  final bool isDismissed;
  final DateTime? lastRemindedAt;

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
    this.reminderCount = 0,
    this.isDismissed = false,
    this.lastRemindedAt,
    required this.createdAt,
  });

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
      'reminderCount': reminderCount,
      'isDismissed': isDismissed,
      'lastRemindedAt': lastRemindedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

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
      reminderCount: map['reminderCount'] ?? 0,
      isDismissed: map['isDismissed'] ?? false,
      lastRemindedAt: map['lastRemindedAt'] != null
          ? DateTime.parse(map['lastRemindedAt'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}