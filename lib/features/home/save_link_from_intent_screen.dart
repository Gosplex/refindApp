import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';
import '../collection/collection_controller.dart';
import '../collection/models/collection_model.dart';
import '../saved_posts/saved_posts_controller.dart';
import '../subscription/subscription_screen.dart';

class SaveLinkFromIntentScreen extends StatefulWidget {
  const SaveLinkFromIntentScreen({super.key, required this.sharedText});

  final String sharedText;

  @override
  State<SaveLinkFromIntentScreen> createState() =>
      _SaveLinkFromIntentScreenState();
}

class _SaveLinkFromIntentScreenState extends State<SaveLinkFromIntentScreen> {
  final SavedPostsController controller = SavedPostsController();
  final TextEditingController _urlController = TextEditingController();
  final _collectionsController = CollectionsController();

  Metadata? _preview;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.sharedText;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Eager anonymous sign-in was removed from launch; this is an explicit
    // save action, so guarantee an account exists (guest is fine) first.
    await AuthController().ensureSignedIn();
    if (!mounted) return;
    _fetchPreview(widget.sharedText);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    final success = await controller.addPost(
      url,
      collectionId: _selectedCollectionId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Free limit reached")),
      );
      _showPaywall();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved ✅")),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    SystemNavigator.pop();
  }

  void _showPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Save link', style: context.text.titleLarge),
        leading: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Where do you want to save this?',
                  style: context.text.bodyMedium),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _urlController,
                hint: 'Paste link…',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
                onChanged: _fetchPreview,
              ),

              const SizedBox(height: AppSpacing.xl),

              AnimatedSwitcher(
                duration: AppMotion.medium,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildPreviewArea(),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('Add to collection', style: context.text.labelMedium),
              const SizedBox(height: AppSpacing.md),

              StreamBuilder<List<CollectionModel>>(
                stream: _collectionsController.getCollectionsStream(),
                builder: (context, snapshot) {
                  final collections = snapshot.data ?? [];
                  if (collections.isEmpty) return const SizedBox.shrink();
                  _selectedCollectionId ??= collections.first.id;

                  return SizedBox(
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
                          onTap: () =>
                              setState(() => _selectedCollectionId = col.id),
                        );
                      },
                    ),
                  );
                },
              ),

              const Spacer(),

              AppButton(
                label: 'Save',
                icon: Icons.check_rounded,
                loading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_isLoading) {
      return const _IntentSkeleton(key: ValueKey('shimmer'));
    }
    if (_preview != null) {
      return _IntentPreviewCard(key: const ValueKey('preview'), preview: _preview!);
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

class _IntentPreviewCard extends StatelessWidget {
  const _IntentPreviewCard({super.key, required this.preview});

  final Metadata preview;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.image != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: Image.network(
                preview.image!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preview.url != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      Uri.tryParse(preview.url!)?.host ?? preview.url!,
                      style: context.text.labelSmall,
                    ),
                  ),
                Text(
                  preview.title ?? 'No title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                if (preview.description != null &&
                    preview.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    preview.description!,
                    maxLines: 3,
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

class _IntentSkeleton extends StatelessWidget {
  const _IntentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
              child: SkeletonBox(height: 180, radius: 0),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 90, height: 16),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(height: 13),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 200, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
