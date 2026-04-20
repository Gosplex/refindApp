import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

import '../saved_posts/saved_posts_controller.dart';
import '../../core/theme/colors.dart';
import '../subscription/subscription_screen.dart';

class SaveLinkFromIntentScreen extends StatefulWidget {
  const SaveLinkFromIntentScreen({
    super.key,
    required this.sharedText,
  });

  final String sharedText;

  @override
  State<SaveLinkFromIntentScreen> createState() =>
      _SaveLinkFromIntentScreenState();
}

class _SaveLinkFromIntentScreenState
    extends State<SaveLinkFromIntentScreen>
    with SingleTickerProviderStateMixin {

  final SavedPostsController  controller     = SavedPostsController();
  final TextEditingController _urlController = TextEditingController();

  Metadata? _preview;
  bool      _isLoading = false;
  bool      _isSaving  = false;

  late final AnimationController _fadeController;
  late final Animation<double>  _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve:  Curves.easeOut,
    );

    _urlController.text = widget.sharedText;
    _fetchPreview(widget.sharedText);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview(String url) async {
    if (url.length < 10) return;

    _fadeController.reset();
    setState(() { _isLoading = true; _preview = null; });

    try {
      final data = await MetadataFetch.extract(url);
      if (mounted) {
        setState(() => _preview = data);
        _fadeController.forward();
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    final success = await controller.addPost(url);

    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Free limit reached")),
      );

      // 👇 open paywall
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
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final borderColor  = isDark ? AppColors.borderDark  : AppColors.border;
    final bgColor      = isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Save link',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: SizedBox.shrink(),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Where do you want to save this?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              TextField(
                controller:   _urlController,
                autofocus:    false,
                keyboardType: TextInputType.url,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText:   'Paste link...',
                  prefixIcon: Icon(Icons.link_rounded, size: 18),
                ),
                onChanged: _fetchPreview,
              ),

              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end:   Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildPreviewArea(
                  isDark:      isDark,
                  borderColor: borderColor,
                ),
              ),

              const Spacer(),

              _SaveButton(
                isSaving: _isSaving,
                onSave:   _save,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea({
    required bool  isDark,
    required Color borderColor,
  }) {
    if (_isLoading) {
      return const _IntentShimmer(key: ValueKey('shimmer'));
    }
    if (_preview != null) {
      return FadeTransition(
        key:     const ValueKey('preview'),
        opacity: _fadeAnim,
        child: _IntentPreviewCard(
          preview:     _preview!,
          borderColor: borderColor,
          isDark:      isDark,
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}


class _IntentPreviewCard extends StatelessWidget {
  const _IntentPreviewCard({
    required this.preview,
    required this.borderColor,
    required this.isDark,
  });

  final Metadata preview;
  final Color    borderColor;
  final bool     isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppColors.surfaceDark
        : AppColors.surface;
    final mutedBg = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (preview.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                preview.image!,
                width:      double.infinity,
                height:     180,
                fit:        BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (preview.url != null)
                  Container(
                    margin:  const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:        mutedBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      Uri.tryParse(preview.url!)?.host ?? preview.url!,
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w400,
                        color:      AppColors.textTertiary,
                      ),
                    ),
                  ),

                Text(
                  preview.title ?? 'No title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),

                if (preview.description != null &&
                    preview.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    preview.description!,
                    maxLines: 3,
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


class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.onSave,
  });

  final bool         isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSaving
              ? const SizedBox(
            key:    ValueKey('loading'),
            width:  18,
            height: 18,
            child:  CircularProgressIndicator(
              strokeWidth: 2,
              color:       Colors.white,
            ),
          )
              : const Text('Save', key: ValueKey('text')),
        ),
      ),
    );
  }
}


class _IntentShimmer extends StatefulWidget {
  const _IntentShimmer({super.key});

  @override
  State<_IntentShimmer> createState() => _IntentShimmerState();
}

class _IntentShimmerState extends State<_IntentShimmer>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>  _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base   = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceVariant;
    final hi     = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surface;
    final borderColor = isDark
        ? AppColors.borderDark
        : AppColors.border;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(base, hi, _anim.value)!;

        return Container(
          decoration: BoxDecoration(
            color:        isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width:  double.infinity,
                  height: 180,
                  color:  shimmer,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width:  80,
                      height: 18,
                      decoration: BoxDecoration(
                        color:        shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width:  double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color:        shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width:  220,
                      height: 12,
                      decoration: BoxDecoration(
                        color:        shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width:  160,
                      height: 12,
                      decoration: BoxDecoration(
                        color:        shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}