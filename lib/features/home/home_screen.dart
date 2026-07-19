import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:refind_app/features/home/widgets/pinned_card.dart';
import 'package:refind_app/features/subscription/subscription_screen.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/widgets.dart';
import '../../services/in_app_purchase_service.dart';
import '../collection/collection_controller.dart';
import '../collection/models/collection_model.dart';
import '../limitGuard/usage_provider.dart';
import '../saved_posts/saved_posts_controller.dart';
import '../saved_posts/models/saved_post_model.dart';
import 'link_details_screen.dart';
import 'widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  final String? sharedText;

  const HomeScreen({super.key, this.sharedText});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SavedPostsController controller = SavedPostsController();

  String _searchQuery = '';

  void _showAddPostSheet({String? initialText}) {
    showAppSheet(
      context: context,
      title: 'Save a link',
      builder: (_) =>
          _AddPostSheet(controller: controller, initialText: initialText),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<bool> _confirmDelete() {
    return showConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete this link?',
      message: 'This action can’t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  void _showUsageInfo() {
    showAppSheet(
      context: context,
      title: 'Usage limit',
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This counter tracks the total number of links you've saved over time.",
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Even if you delete posts, your usage count stays the same.",
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
                label: 'Upgrade for unlimited saves',
                icon: Icons.auto_awesome_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<SavedPost> filterPosts(List<SavedPost> posts, String query) {
    if (query.trim().isEmpty) return posts;
    final q = query.toLowerCase();
    return posts.where((post) {
      final title = post.title.toLowerCase();
      final description = post.description?.toLowerCase() ?? '';
      final url = post.url.toLowerCase();
      final domain = post.domain?.toLowerCase() ?? '';
      final tags = post.tags?.join(' ').toLowerCase() ?? '';
      return title.contains(q) ||
          description.contains(q) ||
          url.contains(q) ||
          domain.contains(q) ||
          tags.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Row(
          children: [
            const Icon(Icons.bookmark_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Refind',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screen),
            child: _UsagePill(onInfo: _showUsageInfo),
          ),
        ],
      ),

      floatingActionButton: _AddFab(onTap: _showAddPostSheet),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.sm, AppSpacing.screen, AppSpacing.xs),
              child: SearchField(
                hint: 'Search saved links…',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            // Pinned collections + saved posts share one scroll view
            Expanded(
              child: StreamBuilder<List<SavedPost>>(
                stream: controller.getPostsStream(),
                builder: (context, snapshot) {
                  final waiting =
                      snapshot.connectionState == ConnectionState.waiting;

                  late final Widget postsSliver;
                  if (waiting) {
                    postsSliver = const _PostSkeletonSliver();
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    postsSliver = SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHome(onAdd: _showAddPostSheet),
                    );
                  } else {
                    final filtered =
                        filterPosts(snapshot.data!, _searchQuery);

                    if (filtered.isEmpty) {
                      postsSliver = const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoResults(),
                      );
                    } else {
                      postsSliver = SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                            AppSpacing.md, AppSpacing.screen, 120),
                        sliver: SliverList.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final post = filtered[index];
                            return FadeSlideIn(
                              index: index,
                              child: PostCard(
                                post: post,
                                onDelete: () async {
                                  if (await _confirmDelete()) {
                                    controller.deletePost(post.id);
                                  }
                                },
                                onDismiss: () =>
                                    controller.dismissPost(post.id),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LinkDetailScreen(post: post),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }
                  }

                  return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      const SliverToBoxAdapter(child: _PinnedSection()),
                      postsSliver,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Animated "Save" FAB
/// ─────────────────────────────────────────────
class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.93,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF5A8C69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Save',
              style: context.text.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Usage pill (tap for details / upsell)
/// ─────────────────────────────────────────────
class _UsagePill extends StatelessWidget {
  const _UsagePill({required this.onInfo});

  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageProvider>(
      builder: (context, usage, _) {
        final c = context.c;
        final isNearLimit = usage.total >= (usage.limit * 0.8).floor();
        final isAtLimit = usage.total >= usage.limit;

        final bg = isAtLimit
            ? c.errorSurface
            : isNearLimit
                ? c.warningSurface
                : c.primarySurface;
        final fg = isAtLimit
            ? c.error
            : isNearLimit
                ? c.warning
                : c.primary;

        return PressableScale(
          onTap: onInfo,
          pressedScale: 0.9,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: fg),
                const SizedBox(width: 3),
                Text(
                  '${usage.total}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1,
                  ),
                ),
                Text(
                  '/${usage.limit >= 999999 ? '∞' : usage.limit}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: fg.withValues(alpha: 0.6),
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
/// Empty / no-result states
/// ─────────────────────────────────────────────
class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.bookmark_add_rounded,
      title: 'Nothing saved yet',
      message: 'Save a link and Refind will remind you to come back to it.',
      actionLabel: 'Save your first link',
      onAction: onAdd,
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No matches',
      message: 'Try a different keyword or clear your search.',
    );
  }
}

/// ─────────────────────────────────────────────
/// Pinned collections section (scrolls with the list, has its own shimmer)
/// ─────────────────────────────────────────────
class _PinnedSection extends StatelessWidget {
  const _PinnedSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollectionModel>>(
      stream: CollectionsController().getCollectionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PinnedShimmerRow();
        }

        final collections = snapshot.data ?? [];
        final pinned = collections.where((c) => c.isPinned).toList();
        if (pinned.isEmpty) return const SizedBox.shrink();

        return FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Pinned collections'),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen),
                  scrollDirection: Axis.horizontal,
                  itemCount: pinned.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) => FadeSlideIn(
                    index: index,
                    offset: 24,
                    child: PinnedCard(collection: pinned[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinnedShimmerRow extends StatelessWidget {
  const _PinnedShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: SkeletonBox(width: 150, height: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, __) =>
                  const SkeletonBox(width: 156, height: 96, radius: AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Loading skeleton for the post list (as a sliver)
/// ─────────────────────────────────────────────
class _PostSkeletonSliver extends StatelessWidget {
  const _PostSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Shimmer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
              AppSpacing.screen, AppSpacing.lg),
          child: Column(
            children: List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 66, height: 66, radius: AppRadius.md),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(height: 14),
                            SizedBox(height: AppSpacing.sm),
                            SkeletonBox(width: 140, height: 11),
                            SizedBox(height: AppSpacing.md),
                            SkeletonBox(
                                width: 90, height: 20, radius: AppRadius.xs),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Add-post bottom sheet body
/// ─────────────────────────────────────────────
class _AddPostSheet extends StatefulWidget {
  const _AddPostSheet({required this.controller, this.initialText});

  final SavedPostsController controller;
  final String? initialText;

  @override
  State<_AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends State<_AddPostSheet> {
  final _urlController = TextEditingController();
  final _collectionsController = CollectionsController();

  Metadata? _preview;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _urlController.text = widget.initialText!;
      _fetchPreview(widget.initialText!);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _fetchPreview(String url) async {
    if (url.length < 10) return;
    setState(() {
      _isLoading = true;
      _preview = null;
    });
    try {
      final data = await MetadataFetch.extract(url);
      if (mounted) setState(() => _preview = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSaving = true);
    final success = await widget.controller.addPost(
      url,
      collectionId: _selectedCollectionId,
    );
    if (mounted) setState(() => _isSaving = false);

    if (!success) {
      if (mounted) Navigator.pop(context);
      _showPaywall();
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _urlController,
            autofocus: true,
            hint: 'Paste a link…',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            onChanged: _fetchPreview,
          ),

          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: _buildPreviewArea(),
          ),

          const SizedBox(height: AppSpacing.xl),

          StreamBuilder<List<CollectionModel>>(
            stream: _collectionsController.getCollectionsStream(),
            builder: (context, snapshot) {
              final collections = snapshot.data ?? [];
              if (collections.isEmpty) return const SizedBox.shrink();
              _selectedCollectionId ??= collections.first.id;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add to collection',
                      style: context.text.labelMedium),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: collections.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final col = collections[index];
                        return AppChip(
                          label: col.name,
                          icon: Icons.folder_rounded,
                          selected: col.id == _selectedCollectionId,
                          onTap: () => setState(
                              () => _selectedCollectionId = col.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.xxl),

          AppButton(
            label: 'Save link',
            icon: Icons.check_rounded,
            loading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: Shimmer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 56, height: 56, radius: AppRadius.sm),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 13),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 160, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_preview != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: _PreviewCard(preview: _preview!),
      );
    }

    return const SizedBox.shrink();
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final Metadata preview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.c.surfaceVariant,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Thumbnail(image: preview.image, size: 56, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title ?? 'No title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                if (preview.description != null &&
                    preview.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
