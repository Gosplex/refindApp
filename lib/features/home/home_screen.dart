import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:refind_app/features/home/widgets/pinned_card.dart';
import 'package:refind_app/features/home/widgets/pinned_shimmer.dart';
import 'package:refind_app/features/subscription/subscription_screen.dart';

import '../../core/theme/colors.dart';
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

  _showAddPostSheet({String? initialText}) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddPostSheet(controller: controller, initialText: initialText),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text(
            'This action cannot be undone.',
          ),
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

    return result ?? false;
  }

  void _showUsageInfo() {
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
                "Usage limit",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              Text(
                "This counter tracks the total number of links you've saved over time.",
              ),

              const SizedBox(height: 8),

              Text(
                "Even if you delete posts, your usage remains the same.",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 20),

              // 👇 subtle upsell
              Text(
                "Upgrade to unlock unlimited saves.",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              StreamBuilder<bool>(
                stream: InAppPurchaseService().proStatusStream,
                initialData: InAppPurchaseService().isPro,
                builder: (context, snapshot) {
                  final isPro = snapshot.data ?? false;

                  if (isPro) return const SizedBox.shrink();

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SubscriptionScreen(),
                          ),
                        );
                      },
                      child: const Text("Upgrade"),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageIndicator() {
    return Consumer<UsageProvider>(
      builder: (context, usage, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isNearLimit = usage.total >= (usage.limit * 0.8).floor();
        final isAtLimit = usage.total >= usage.limit;

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
          onTap: _showUsageInfo,
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
                  '${usage.total}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1,
                  ),
                ),
                Text(
                  '/${usage.limit}',
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
        title: Text('Refind', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildUsageIndicator(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: _showAddPostSheet,
        child: const Icon(Icons.add_rounded, size: 26),
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search saved links...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                ),
              ),
            ),
            StreamBuilder<List<CollectionModel>>(
              stream: CollectionsController().getCollectionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PinnedShimmer();
                }

                final collections = snapshot.data ?? [];

                final pinned = collections.where((c) => c.isPinned).toList();

                if (pinned.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Pinned Collections',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: pinned.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final col = pinned[index];

                          return PinnedCard(collection: col);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: StreamBuilder<List<SavedPost>>(
                stream: controller.getPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _ShimmerList();
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const _EmptyState();
                  }

                  final posts = snapshot.data!;

                  final filteredPosts = filterPosts(posts, _searchQuery);

                  return ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return PostCard(
                        post: post,
                        onDelete: () async {
                          final confirm = await _confirmDelete();
                          if (confirm) {
                            controller.deletePost(post.id);
                          }
                        },
                        onDismiss: () => controller.dismissPost(post.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LinkDetailScreen(post: post),
                            ),
                          );
                        },
                      );
                    },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved posts yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Save links and revisit them later',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: 5,
          itemBuilder: (_, __) =>
              _ShimmerCard(progress: _anim.value, isDark: isDark),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  Color get _base => isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;

  Color get _highlight =>
      isDark ? AppColors.surfaceVariantDark : AppColors.surface;

  Color get _shimmer => Color.lerp(_base, _highlight, progress)!;

  Widget _block(double w, double h, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _shimmer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(62, 62, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(double.infinity, 14),
                const SizedBox(height: 8),
                _block(140, 11),
                const SizedBox(height: 12),
                _block(90, 20, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPostSheet extends StatefulWidget {
  const _AddPostSheet({required this.controller, this.initialText});

  final SavedPostsController controller;
  final String? initialText;

  @override
  State<_AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends State<_AddPostSheet> {
  final _urlController = TextEditingController();

  Metadata? _preview;
  bool _isLoading = false;
  bool _isSaving = false;

  String? _selectedCollectionId;

  final _collectionsController = CollectionsController();

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
      collectionId: _selectedCollectionId, // 👈 PASS HERE
    );

    setState(() => _isSaving = false);

    if (!success) {
      Navigator.pop(context);
      _showPaywall();
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

          /// Handle bar
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

          Text('Save a link', style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 16),

          /// URL Input
          TextField(
            controller: _urlController,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Paste link...',
              prefixIcon: Icon(Icons.link_rounded, size: 18),
            ),
            onChanged: _fetchPreview,
          ),

          /// Loading
          if (_isLoading) ...[
            const SizedBox(height: 20),
            const _InlineShimmer(),
          ],

          /// Preview
          if (_preview != null && !_isLoading) ...[
            const SizedBox(height: 16),
            PreviewCard(
              preview: _preview!,
              borderColor: borderColor,
              isDark: isDark,
            ),
          ],

          /// 🔥 COLLECTION SELECTOR (NEW)
          const SizedBox(height: 16),

          Text(
            'Select a collection',
            style: Theme.of(context).textTheme.labelMedium,
          ),

          const SizedBox(height: 16),

          StreamBuilder<List<CollectionModel>>(
            stream: _collectionsController.getCollectionsStream(),
            builder: (context, snapshot) {
              final collections = snapshot.data ?? [];

              if (collections.isEmpty) return const SizedBox.shrink();

              // 👇 Auto-select first collection (simple suggestion)
              _selectedCollectionId ??= collections.first.id;

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: collections.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    final isSelected =
                        col.id == _selectedCollectionId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCollectionId = col.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryMuted
                              : (isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariant),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              col.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          /// Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
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

class PreviewCard extends StatelessWidget {
  const PreviewCard({
    required this.preview,
    required this.borderColor,
    required this.isDark,
  });

  final Metadata preview;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                preview.image!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.link_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title ?? 'No title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (preview.description != null &&
                    preview.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _InlineShimmer extends StatefulWidget {
  const _InlineShimmer();

  @override
  State<_InlineShimmer> createState() => _InlineShimmerState();
}

class _InlineShimmerState extends State<_InlineShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;
    final hi = isDark ? AppColors.borderDark : AppColors.border;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(base, hi, _anim.value)!;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 160,
                    height: 11,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
