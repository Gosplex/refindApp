import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/widgets.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name, style: context.text.titleLarge),
      ),
      body: StreamBuilder<List<SavedPost>>(
        stream: controller.getPostsByCollection(collection.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DetailSkeleton();
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return _EmptyDetail(collection: collection);
          }

          return ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 100),
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return FadeSlideIn(child: _Header(collection: collection, count: posts.length));
              }
              final post = posts[index - 1];
              return FadeSlideIn(
                index: index,
                child: PostCard(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.collection, required this.count});

  final CollectionModel collection;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 15, color: c.textSecondary),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                '$count ${count == 1 ? 'link' : 'links'}',
                style: context.text.labelMedium,
              ),
            ],
          ),
          if (collection.description.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                collection.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.collection});

  final CollectionModel collection;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.folder_open_rounded,
      title: 'No links yet',
      message: 'Links you add to "${collection.name}" will show up here.',
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.lg),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
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
                      SkeletonBox(width: 90, height: 20, radius: AppRadius.xs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
