class CollectionModel {
  final String id;
  final String name;
  final String description;
  final bool isDefault;
  final String userId;
  final DateTime createdAt;

  const CollectionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isDefault,
    required this.userId,
    required this.createdAt,
  });

  /// ─────────────────────────────────────────────
  /// 🔄 From Firestore
  /// ─────────────────────────────────────────────
  factory CollectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return CollectionModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isDefault: map['isDefault'] ?? false,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }

  /// ─────────────────────────────────────────────
  /// 📤 To Firestore
  /// ─────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isDefault': isDefault,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  /// ─────────────────────────────────────────────
  /// ✏️ Copy (for updates)
  /// ─────────────────────────────────────────────
  CollectionModel copyWith({
    String? name,
    String? description,
    bool? isDefault,
  }) {
    return CollectionModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      userId: userId,
      createdAt: createdAt,
    );
  }
}