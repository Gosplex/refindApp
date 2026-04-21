import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/utils/url_launcher.dart';
import '../collection/collection_controller.dart';
import '../collection/models/collection_model.dart';
import '../saved_posts/models/saved_post_model.dart';
import '../saved_posts/saved_posts_controller.dart';

class LinkDetailScreen extends StatefulWidget {
  final SavedPost post;

  const LinkDetailScreen({super.key, required this.post});

  @override
  State<LinkDetailScreen> createState() => _LinkDetailScreenState();
}

class _LinkDetailScreenState extends State<LinkDetailScreen> {
  final SavedPostsController _postsController = SavedPostsController();
  final CollectionsController _collectionsController = CollectionsController();

  String? _selectedCollectionId;
  String? _selectedCollectionName;

  @override
  void initState() {
    super.initState();
    _selectedCollectionId = widget.post.collectionId;
  }

  void _openCollectionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CollectionPickerSheet(
          controller: _collectionsController,
          selectedId: _selectedCollectionId,
          onSelect: (collection) async {
            Navigator.pop(context);

            await _postsController.addToCollection(
              postId: widget.post.id,
              collectionId: collection?.id,
            );

            setState(() {
              _selectedCollectionId = collection?.id;
              _selectedCollectionName = collection?.name;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    collection == null
                        ? 'Removed from collection'
                        : 'Moved to ${collection.name}',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        title: Text('Link', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (post.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.image!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            if (post.domain != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.domain!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ),

            const SizedBox(height: 12),

            Text(
              post.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            if (post.description != null)
              Text(
                post.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            const SizedBox(height: 20),

            if (post.tags != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags!
                    .map(
                      (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: borderColor,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      tag,
                      style:
                      Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                )
                    .toList(),
              ),

            const SizedBox(height: 24),

            /// 🔥 Collection Card (SMART)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _openCollectionPicker();
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedCollectionId == null
                            ? 'Add to collection'
                            : (_selectedCollectionName ??
                            'Update collection'),
                        style:
                        Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 0.6),
            ),
          ),
          child: Row(
            children: [

              _ActionButton(
                icon: post.isDismissed
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_outlined,

                label: post.isDismissed ? 'Dismissed' : 'Remind',

                isDisabled: post.isDismissed,

                onTap: () async {
                  if (post.isDismissed) return;

                  HapticFeedback.lightImpact();

                  await _postsController.dismissPost(post.id);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You’ll be reminded later'),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(width: 10),

              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                isDestructive: true,
                onTap: () async {
                  HapticFeedback.mediumImpact();

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete post?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await _postsController.deletePost(post.id);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      openUrl(post.url);
                    },
                    child: const Text('Visit link'),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}

class _CollectionPickerSheet extends StatelessWidget {
  final CollectionsController controller;
  final Function(CollectionModel?) onSelect;
  final String? selectedId;

  const _CollectionPickerSheet({
    required this.controller,
    required this.onSelect,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<List<CollectionModel>>(
            stream: controller.getCollectionsStream(),
            builder: (context, snapshot) {
              final collections = snapshot.data ?? [];

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: const Text('Remove from collection'),
                    selected: selectedId == null,
                    onTap: () => onSelect(null),
                  ),
                  ...collections.map((c) {
                    final isSelected = c.id == selectedId;

                    return ListTile(
                      leading: Icon(
                        Icons.folder_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : null,
                      ),
                      title: Text(c.name),
                      selected: isSelected,
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                          : null,
                      onTap: () => onSelect(c),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDisabled
        ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
        : isDestructive
        ? AppColors.errorMuted
        : isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;

    final textColor = isDisabled
        ? AppColors.textTertiary
        : isDestructive
        ? AppColors.error
        : AppColors.textOf(context);

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}