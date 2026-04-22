import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionModel {
  final String id;
  final String name;
  final String description;
  final bool isDefault;
  final String userId;
  final DateTime createdAt;

  final bool isPinned;

  const CollectionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isDefault,
    required this.userId,
    required this.createdAt,
    this.isPinned = false,
  });

  /// ─────────────────────────────────────────────
  /// 🔄 From Firestore
  /// ─────────────────────────────────────────────
  factory CollectionModel.fromMap(
      Map<String, dynamic> map,
      String docId,
      ) {
    return CollectionModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isDefault: map['isDefault'] ?? false,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      isPinned: map['isPinned'] ?? false,
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
      'isPinned': isPinned,
    };
  }

  /// ─────────────────────────────────────────────
  /// ✏️ Copy (for updates)
  /// ─────────────────────────────────────────────
  CollectionModel copyWith({
    String? name,
    String? description,
    bool? isDefault,
    bool? isPinned,
  }) {
    return CollectionModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      userId: userId,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}