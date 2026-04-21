import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../limitGuard/usage_provider.dart';
import '../../subscription/subscription_screen.dart';
import '../collection_controller.dart';
import '../models/collection_model.dart';
import 'collection_details_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final CollectionsController controller = CollectionsController();

  Future<DeleteResult> _confirmDelete(BuildContext context) async {
    bool deletePosts = false;

    final result = await showDialog<DeleteResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Delete collection?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'By default, links will be kept and removed from this collection.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    value: deletePosts,
                    onChanged: (val) {
                      setState(() {
                        deletePosts = val ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Also delete all links'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DeleteResult(
                        confirmed: false,
                        deletePosts: false,
                      ),
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DeleteResult(
                        confirmed: true,
                        deletePosts: deletePosts,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ??
        DeleteResult(
          confirmed: false,
          deletePosts: false,
        );
  }

  void _showCollectionUsageInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Collection limit",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              Text(
                "This counter tracks the total number of collections you've created.",
              ),

              const SizedBox(height: 8),

              Text(
                "Even if you delete collections, your usage remains the same.",
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Upgrade to create unlimited collections.",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: const Text("Upgrade"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Collections',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildCollectionUsageIndicator(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () async {
          HapticFeedback.lightImpact();

          final canAdd = await controller.canAddCollection();

          if (!canAdd) {
            final goToPaywall = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'Limit reached',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  content: Text(
                    'You can only create up to 3 collections on the free plan.\n\nUpgrade to create unlimited collections.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Upgrade'),
                    ),
                  ],
                );
              },
            );

            if (goToPaywall == true) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            }

            return;
          }

          /// ✅ Open create sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CreateCollectionSheet(controller: controller),
          );
        },
        child: const Icon(Icons.add_rounded, size: 26),
      ),

      body: StreamBuilder<List<CollectionModel>>(
        stream: controller.getCollectionsStream(),
        builder: (context, snapshot) {
          final collections = snapshot.data ?? [];

          if (collections.isEmpty) {
            return const _EmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CollectionDetailScreen(
                        collection: collection,
                      ),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 🔝 Top Row (icon + menu)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          /// 📁 Folder Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.folder_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),

                          /// ⋮ Menu
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final result = await _confirmDelete(context);

                                if (result.confirmed) {
                                  await controller.deleteCollection(
                                    collection.id,
                                    deletePosts: result.deletePosts,
                                  );
                                }
                              }

                              if (value == 'edit') {
                                HapticFeedback.lightImpact();

                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useRootNavigator: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _EditCollectionSheet(
                                    controller: controller,
                                    collection: collection,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Spacer(),

                      /// 📛 Name
                      Text(
                        collection.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 4),

                      /// 📄 Description (or fallback)
                      Text(
                        collection.description.isNotEmpty
                            ? collection.description
                            : 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionUsageIndicator() {
    return Consumer<UsageProvider>(
      builder: (context, usage, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        /// ✅ Use lifetime usage explicitly
        final total = usage.totalCollections;
        final limit = usage.collectionLimit;

        final isNearLimit = total >= (limit * 0.8).floor();
        final isAtLimit = total >= limit;

        final pillBg = isAtLimit
            ? AppColors.errorMuted
            : isNearLimit
            ? AppColors.warningMuted
            : isDark
            ? AppColors.surfaceVariantDark
            : AppColors.primaryMuted;

        final textColor = isAtLimit
            ? AppColors.error
            : isNearLimit
            ? AppColors.warning
            : AppColors.primary;

        return GestureDetector(
          onTap: _showCollectionUsageInfo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1,
                  ),
                ),
                Text(
                  '/$limit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textColor.withValues(alpha: 0.6),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


/// ─────────────────────────────────────────────
/// 🫙 Empty State (same philosophy as HomeScreen)
/// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No collections yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Group your saved links into collections',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CreateCollectionSheet extends StatefulWidget {
  final CollectionsController controller;

  const _CreateCollectionSheet({required this.controller});

  @override
  State<_CreateCollectionSheet> createState() =>
      _CreateCollectionSheetState();
}

class _CreateCollectionSheetState
    extends State<_CreateCollectionSheet> {

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    final success =  await widget.controller.createCollection(
      name: name,
      description: desc,
    );

    if (!success) {
      Navigator.pop(context);

      _showPaywall();

      return;
    }

    if (mounted) Navigator.pop(context);
  }

  void _showPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Create collection',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            autofocus: true,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Collection name',
              prefixIcon: Icon(Icons.folder_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _descController,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _create,
              child: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}


class _EditCollectionSheet extends StatefulWidget {
  final CollectionsController controller;
  final CollectionModel collection;

  const _EditCollectionSheet({
    required this.controller,
    required this.collection,
  });

  @override
  State<_EditCollectionSheet> createState() =>
      _EditCollectionSheetState();
}

class _EditCollectionSheetState
    extends State<_EditCollectionSheet> {

  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    /// ✅ Prefill values
    _nameController =
        TextEditingController(text: widget.collection.name);

    _descController =
        TextEditingController(text: widget.collection.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) return;

    /// ✅ close keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    await widget.controller.updateCollection(
      id: widget.collection.id,
      name: name,
      description: desc,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /// title
          Text(
            'Edit collection',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          /// name
          TextField(
            controller: _nameController,
            autofocus: true,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Collection name',
              prefixIcon: Icon(Icons.folder_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 12),

          /// description
          TextField(
            controller: _descController,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 24),

          /// update button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _update,
              child: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}


class DeleteResult {
  final bool confirmed;
  final bool deletePosts;

  DeleteResult({
    required this.confirmed,
    required this.deletePosts,
  });
}