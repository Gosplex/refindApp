import 'package:refind_app/features/collection/services/collection_service.dart';
import 'package:uuid/uuid.dart';

import 'models/collection_model.dart';



class CollectionsController {
  final CollectionsService _service = CollectionsService();

  final _uuid = const Uuid();

  /// ─────────────────────────────────────────────
  /// ➕ Create Collection
  /// ─────────────────────────────────────────────
  Future<bool> createCollection({
    required String name,
    String description = '',
    bool isDefault = false,
  }) async {

    final canAdd = await _service.canAddCollection();

    if (!canAdd) {
      return false;
    }

    final collection = CollectionModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      isDefault: isDefault,
      userId: _service.userId,
      createdAt: DateTime.now(),
    );

    await _service.createCollection(collection);
    await _service.incrementCollectionUsage();

    return true;
  }
  /// ─────────────────────────────────────────────
  /// 📥 Get Collections (Realtime)
  /// ─────────────────────────────────────────────
  Stream<List<CollectionModel>> getCollectionsStream() {
    return _service.getCollectionsStream();
  }

  /// ─────────────────────────────────────────────
  /// ✏️ Update Collection
  /// ─────────────────────────────────────────────
  Future<void> updateCollection({
    required String id,
    String? name,
    String? description,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;

    if (data.isEmpty) return;

    await _service.updateCollection(id, data);
  }

  /// ─────────────────────────────────────────────
  /// ❌ Delete Collection
  /// ─────────────────────────────────────────────
  Future<void> deleteCollection(String id, {bool deletePosts = false}) async {
    await _service.deleteCollection(id, deletePosts: deletePosts);
  }

  Future<bool> togglePin(CollectionModel collection) async {
    return await _service.togglePinSmart(collection);
  }

  /// ─────────────────────────────────────────────
  /// 🌱 Seed Default Collections
  /// ─────────────────────────────────────────────
  Future<void> seedDefaults() async {
    await _service.seedDefaultCollections();
  }

  Future<bool> canAddCollection() async {
    return _service.canAddCollection();
  }
}