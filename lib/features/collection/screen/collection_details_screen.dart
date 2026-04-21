import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../home/link_details_screen.dart';
import '../../home/widgets/post_card.dart';
import '../../saved_posts/models/saved_post_model.dart';
import '../../saved_posts/saved_posts_controller.dart';
import '../models/collection_model.dart';

class CollectionDetailScreen extends StatelessWidget {
  final CollectionModel collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final controller = SavedPostsController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          collection.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),

      body: StreamBuilder<List<SavedPost>>(
        stream: controller.getPostsByCollection(collection.id),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ShimmerList();
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return _EmptyState(collection: collection);
          }

          return ListView.builder(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              return PostCard(
                post: post,
                onDelete: () => controller.deletePost(post.id),
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
    );
  }
}

/// ─────────────────────────────────────────────
/// 🫙 Empty State
/// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final CollectionModel collection;

  const _EmptyState({required this.collection});

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
            'No links yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Save links into "${collection.name}"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// ✨ Shimmer List (same philosophy as Home)
/// ─────────────────────────────────────────────
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

    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: 5,
          itemBuilder: (_, __) => _ShimmerCard(
            progress: _anim.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  Color get _base =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;

  Color get _highlight =>
      isDark ? AppColors.surfaceVariantDark : AppColors.surface;

  Color get _shimmer =>
      Color.lerp(_base, _highlight, progress)!;

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
    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

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