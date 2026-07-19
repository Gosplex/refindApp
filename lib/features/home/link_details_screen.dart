import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/url_launcher.dart';
import '../../core/widgets/widgets.dart';
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
  late bool _dismissed;

  @override
  void initState() {
    super.initState();
    _selectedCollectionId = widget.post.collectionId;
    _dismissed = widget.post.isDismissed;
  }

  void _openCollectionPicker() {
    showAppSheet(
      context: context,
      title: 'Move to collection',
      builder: (_) => _CollectionPickerSheet(
        controller: _collectionsController,
        selectedId: _selectedCollectionId,
        onSelect: (collection) async {
          Navigator.pop(context);

          await _postsController.addToCollection(
            postId: widget.post.id,
            collectionId: collection?.id,
          );

          if (!mounted) return;
          setState(() {
            _selectedCollectionId = collection?.id;
            _selectedCollectionName = collection?.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                collection == null
                    ? 'Removed from collection'
                    : 'Moved to ${collection.name}',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _remind() async {
    if (_dismissed) return;
    HapticFeedback.lightImpact();
    await _postsController.dismissPost(widget.post.id);
    if (!mounted) return;
    setState(() => _dismissed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You’ll be reminded later')),
    );
  }

  Future<void> _delete() async {
    final confirm = await showConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete this link?',
      message: 'This action can’t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirm) {
      await _postsController.deletePost(widget.post.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _visit() {
    HapticFeedback.lightImpact();
    _postsController.onPostOpened(widget.post.id);
    openUrl(widget.post.url);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final c = context.c;
    final tags = post.tags ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text('Link', style: context.text.titleLarge)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xxl),
        child: FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.image != null && post.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.network(
                    post.image!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(context),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              if (post.domain != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(post.domain!,
                          style: context.text.labelSmall
                              ?.copyWith(color: c.primary)),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              Text(post.title, style: context.text.headlineSmall),

              if (post.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(post.description!, style: context.text.bodyMedium),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Meta stats
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.visibility_rounded,
                    label:
                        '${post.visitCount} visit${post.visitCount == 1 ? '' : 's'}',
                  ),
                  if (post.reminderCount > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _MetaChip(
                      icon: Icons.notifications_active_rounded,
                      label:
                          '${post.reminderCount} reminder${post.reminderCount == 1 ? '' : 's'}',
                    ),
                  ],
                ],
              ),

              if (tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children:
                      tags.map((t) => AppChip(label: t, tonal: true)).toList(),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Collection selector
              AppCard(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _openCollectionPicker();
                },
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: c.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.folder_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _selectedCollectionId == null
                            ? 'Add to collection'
                            : (_selectedCollectionName ?? 'Update collection'),
                        style: context.text.titleSmall,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: c.textTertiary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
            AppSpacing.screen, AppSpacing.md + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border, width: 0.8)),
        ),
        child: Row(
          children: [
            _BottomAction(
              icon: _dismissed
                  ? Icons.notifications_off_rounded
                  : Icons.notifications_active_rounded,
              label: _dismissed ? 'Dismissed' : 'Remind',
              disabled: _dismissed,
              onTap: _remind,
            ),
            const SizedBox(width: AppSpacing.sm),
            _BottomAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              destructive: true,
              onTap: _delete,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: AppButton(
                  label: 'Visit link',
                  icon: Icons.open_in_new_rounded,
                  onPressed: _visit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      color: context.c.surfaceVariant,
      child: Icon(Icons.image_not_supported_rounded,
          size: 34, color: context.c.textTertiary),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = disabled
        ? c.textTertiary
        : destructive
            ? c.error
            : c.textPrimary;
    final bg = destructive && !disabled ? c.errorSurface : c.surfaceVariant;

    return Expanded(
      child: PressableScale(
        onTap: disabled ? null : onTap,
        pressedScale: 0.94,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: fg),
              const SizedBox(height: 2),
              Text(label,
                  style: context.text.labelSmall?.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collection picker sheet body (content only — chrome comes from AppSheet).
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: StreamBuilder<List<CollectionModel>>(
        stream: controller.getCollectionsStream(),
        builder: (context, snapshot) {
          final collections = snapshot.data ?? [];
          return ListView(
            shrinkWrap: true,
            children: [
              _PickerRow(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Remove from collection',
                selected: selectedId == null,
                onTap: () => onSelect(null),
              ),
              ...collections.map((col) => _PickerRow(
                    icon: Icons.folder_rounded,
                    label: col.name,
                    selected: col.id == selectedId,
                    onTap: () => onSelect(col),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? c.primarySurface : c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 19, color: selected ? c.primary : c.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyLarge?.copyWith(
                  color: selected ? c.primary : c.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
