import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/widgets.dart';
import '../../collection/models/collection_model.dart';
import '../../collection/screen/collection_details_screen.dart';

/// Horizontal quick-access tile for a pinned collection.
class PinnedCard extends StatelessWidget {
  const PinnedCard({super.key, required this.collection});

  final CollectionModel collection;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(collection: collection),
          ),
        );
      },
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.primarySurface,
              Color.lerp(c.primarySurface, c.surface, 0.35)!,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.folder_rounded,
                      size: 17, color: AppColors.primary),
                ),
                const Spacer(),
                const Icon(Icons.push_pin_rounded,
                    size: 13, color: AppColors.primary),
              ],
            ),
            const Spacer(),
            Text(
              collection.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall?.copyWith(
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
