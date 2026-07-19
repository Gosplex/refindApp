import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/widgets.dart';
import '../../limitGuard/usage_provider.dart';
import '../../../services/in_app_purchase_service.dart';
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
          builder: (context, setLocal) {
            final c = context.c;
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: c.errorSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          color: c.error, size: 24),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Delete collection?',
                        style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'By default, links are kept and just removed from this collection.',
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CheckRow(
                      label: 'Also delete all links inside',
                      value: deletePosts,
                      onChanged: (v) => setLocal(() => deletePosts = v),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(
                              context,
                              DeleteResult(
                                  confirmed: false, deletePosts: false),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: 'Delete',
                            variant: AppButtonVariant.danger,
                            onPressed: () => Navigator.pop(
                              context,
                              DeleteResult(
                                  confirmed: true, deletePosts: deletePosts),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return result ?? DeleteResult(confirmed: false, deletePosts: false);
  }

  void _showCollectionUsageInfo() {
    showAppSheet(
      context: context,
      title: 'Collection limit',
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This counter tracks the total number of collections you've created.",
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Even if you delete collections, your usage count stays the same.",
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          StreamBuilder<bool>(
            stream: InAppPurchaseService().proStatusStream,
            initialData: InAppPurchaseService().isPro,
            builder: (context, snapshot) {
              final isPro = snapshot.data ?? false;
              if (isPro) return const SizedBox.shrink();
              return AppButton(
                label: 'Upgrade for unlimited collections',
                icon: Icons.auto_awesome_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onCreatePressed() async {
    final canAdd = await controller.canAddCollection();
    if (!mounted) return;

    if (!canAdd) {
      final goToPaywall = await showConfirmDialog(
        context,
        icon: Icons.lock_rounded,
        title: 'Limit reached',
        message:
            'You can create up to 3 collections on the free plan. Upgrade for unlimited collections.',
        confirmLabel: 'Upgrade',
      );
      if (goToPaywall && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      }
      return;
    }

    if (!mounted) return;
    showAppSheet(
      context: context,
      title: 'Create collection',
      builder: (_) => _CreateCollectionSheet(controller: controller),
    );
  }

  void _open(CollectionModel col) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionDetailScreen(collection: col),
      ),
    );
  }

  void _openEdit(CollectionModel col) {
    showAppSheet(
      context: context,
      title: 'Edit collection',
      builder: (_) =>
          _EditCollectionSheet(controller: controller, collection: col),
    );
  }

  Future<void> _handleDelete(CollectionModel col) async {
    final result = await _confirmDelete(context);
    if (result.confirmed) {
      await controller.deleteCollection(col.id,
          deletePosts: result.deletePosts);
    }
  }

  Future<void> _handleTogglePin(CollectionModel col) async {
    final success = await controller.togglePin(col);
    if (!success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('Collections', style: context.text.titleLarge),
        actions: [
          Consumer<UsageProvider>(
            builder: (context, usage, _) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.screen),
              child: UsagePill(
                icon: Icons.folder_rounded,
                total: usage.totalCollections,
                limit: usage.collectionLimit,
                onTap: _showCollectionUsageInfo,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          GradientFab(label: 'New', onTap: _onCreatePressed),
      body: StreamBuilder<List<CollectionModel>>(
        stream: controller.getCollectionsStream(),
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final collections = snapshot.data ?? [];

          final Widget child;
          if (waiting) {
            child = const _CollectionSkeletonGrid(key: ValueKey('loading'));
          } else if (collections.isEmpty) {
            child = _EmptyCollections(
              key: const ValueKey('empty'),
              onCreate: _onCreatePressed,
            );
          } else {
            child = GridView.builder(
              key: const ValueKey('grid'),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 110),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
              ),
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final col = collections[index];
                return FadeSlideIn(
                  index: index,
                  child: _CollectionCard(
                    collection: col,
                    onOpen: () => _open(col),
                    onEdit: () => _openEdit(col),
                    onDelete: () => _handleDelete(col),
                    onTogglePin: () => _handleTogglePin(col),
                  ),
                );
              },
            );
          }

          return AnimatedSwitcher(
            duration: AppMotion.medium,
            child: child,
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Collection grid card
/// ─────────────────────────────────────────────
class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  final CollectionModel collection;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.primarySurface,
                      Color.lerp(c.primarySurface, c.surface, 0.4)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.folder_rounded,
                    size: 22, color: AppColors.primary),
              ),
              if (collection.isPinned) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.push_pin_rounded,
                    size: 14, color: AppColors.primary),
              ],
              const Spacer(),
              _CardMenu(
                isPinned: collection.isPinned,
                onEdit: onEdit,
                onDelete: onDelete,
                onTogglePin: onTogglePin,
              ),
            ],
          ),
          const Spacer(),
          Text(
            collection.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            collection.description.isNotEmpty
                ? collection.description
                : 'No description',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.isPinned,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  final bool isPinned;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textSecondary),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (value) {
        switch (value) {
          case 'pin':
            onTogglePin();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18, color: c.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(isPinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: c.textSecondary),
              const SizedBox(width: AppSpacing.md),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: c.error),
              const SizedBox(width: AppSpacing.md),
              Text('Delete', style: TextStyle(color: c.error)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small tappable checkbox row for the delete dialog.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? c.error : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: value ? c.error : c.border,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Empty + skeleton states
/// ─────────────────────────────────────────────
class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.create_new_folder_rounded,
      title: 'No collections yet',
      message: 'Group your saved links into collections to keep them tidy.',
      actionLabel: 'Create a collection',
      onAction: onCreate,
    );
  }
}

class _CollectionSkeletonGrid extends StatelessWidget {
  const _CollectionSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 110),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.05,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 42, height: 42, radius: AppRadius.md),
              Spacer(),
              SkeletonBox(height: 13),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 80, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Create collection sheet
/// ─────────────────────────────────────────────
class _CreateCollectionSheet extends StatefulWidget {
  final CollectionsController controller;

  const _CreateCollectionSheet({required this.controller});

  @override
  State<_CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<_CreateCollectionSheet> {
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

    final success = await widget.controller.createCollection(
      name: name,
      description: desc,
    );

    if (!mounted) return;
    if (!success) {
      Navigator.pop(context);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _CollectionForm(
      nameController: _nameController,
      descController: _descController,
      isSaving: _isSaving,
      actionLabel: 'Create',
      onSubmit: _create,
    );
  }
}

/// ─────────────────────────────────────────────
/// Edit collection sheet
/// ─────────────────────────────────────────────
class _EditCollectionSheet extends StatefulWidget {
  final CollectionsController controller;
  final CollectionModel collection;

  const _EditCollectionSheet({
    required this.controller,
    required this.collection,
  });

  @override
  State<_EditCollectionSheet> createState() => _EditCollectionSheetState();
}

class _EditCollectionSheetState extends State<_EditCollectionSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descController = TextEditingController(text: widget.collection.description);
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
    return _CollectionForm(
      nameController: _nameController,
      descController: _descController,
      isSaving: _isSaving,
      actionLabel: 'Save',
      onSubmit: _update,
    );
  }
}

/// Shared create/edit form body.
class _CollectionForm extends StatelessWidget {
  const _CollectionForm({
    required this.nameController,
    required this.descController,
    required this.isSaving,
    required this.actionLabel,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController descController;
  final bool isSaving;
  final String actionLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: nameController,
            autofocus: true,
            hint: 'Collection name',
            icon: Icons.folder_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: descController,
            hint: 'Description (optional)',
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: actionLabel,
            icon: Icons.check_rounded,
            loading: isSaving,
            onPressed: onSubmit,
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
