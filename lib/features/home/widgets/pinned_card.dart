import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/colors.dart';
import '../../collection/models/collection_model.dart';
import '../../collection/screen/collection_details_screen.dart';

class PinnedCard extends StatelessWidget {
  final CollectionModel collection;

  const PinnedCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

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
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.folder_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.push_pin,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),

            const Spacer(),

            Text(
              collection.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}