import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/widgets.dart';
import '../../services/in_app_purchase_service.dart';
import '../auth/auth_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isYearly = true;

  final iap = InAppPurchaseService();
  final auth = AuthService();

  bool _loading = true;
  bool _isPurchasing = false;
  String? _error;

  Package? get _monthly => iap.monthlyPackage;
  Package? get _yearly => iap.yearlyPackage;

  String get currencySymbol {
    final package = _yearly ?? _monthly;
    if (package == null) return '';
    return package.storeProduct.priceString
        .replaceAll(RegExp(r'[0-9.,\s]'), '');
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      await iap.fetchCustomerInfo();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _displayPrice {
    final package = _isYearly ? _yearly : _monthly;
    return package?.storeProduct.priceString ?? '...';
  }

  String get _displayPeriod => _isYearly ? '/ year' : '/ month';

  String get _perMonthNote {
    if (!_isYearly || _yearly == null) return 'Billed monthly';
    final yearlyPrice = _yearly!.storeProduct.price;
    final perMonth = (yearlyPrice / 12).round();
    return '$currencySymbol$perMonth / month · billed yearly';
  }

  int get _savingPercent {
    if (_monthly == null || _yearly == null) return 0;
    final monthly = _monthly!.storeProduct.price;
    final yearly = _yearly!.storeProduct.price;
    final yearlyCostIfMonthly = monthly * 12;
    final savings =
        ((yearlyCostIfMonthly - yearly) / yearlyCostIfMonthly) * 100;
    return savings.round();
  }

  Future<void> _subscribe() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      if (auth.isAnonymous()) {
        final shouldLogin = await _showLoginRequiredSheet();
        if (shouldLogin != true) {
          setState(() => _isPurchasing = false);
          return;
        }
        final result = await auth.signInWithGoogle();
        if (result == null) {
          setState(() => _isPurchasing = false);
          return;
        }
        await auth.ensureDisplayName();
        await InAppPurchaseService().fetchCustomerInfo();
      }

      final package = _isYearly ? _yearly : _monthly;
      if (package == null) throw Exception('Package not available');

      final success = await iap.purchase(package);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're now Premium 🚀")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Purchase Error $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed or cancelled')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      if (auth.isAnonymous()) {
        final shouldLogin = await _showLoginRequiredSheet();
        if (shouldLogin != true) {
          setState(() => _isPurchasing = false);
          return;
        }
        final result = await auth.signInWithGoogle();
        if (result == null) {
          setState(() => _isPurchasing = false);
          return;
        }
        await auth.ensureDisplayName();
        await InAppPurchaseService().fetchCustomerInfo();
      }

      await iap.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restored successfully ✅")),
        );
      }
    } catch (e) {
      debugPrint("Restore Error $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restore failed")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<bool?> _showLoginRequiredSheet() {
    return showAppSheet<bool>(
      context: context,
      title: 'Sign in required',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To keep your subscription across devices, sign in with Google first.',
            style: ctx.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Continue with Google',
            icon: Icons.login_rounded,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildError(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade', style: context.text.titleLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeSlideIn(child: _Header()),
                  const SizedBox(height: AppSpacing.xxl),

                  FadeSlideIn(
                    index: 1,
                    child: _loading
                        ? const Shimmer(child: SkeletonBox(height: 46, radius: AppRadius.md))
                        : _BillingToggle(
                            isYearly: _isYearly,
                            savingPercent: _savingPercent,
                            onToggle: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _isYearly = val);
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  FadeSlideIn(
                    index: 2,
                    child: _loading
                        ? Shimmer(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(child: SkeletonBox(height: 210, radius: AppRadius.lg)),
                                SizedBox(width: AppSpacing.md),
                                Expanded(child: SkeletonBox(height: 210, radius: AppRadius.lg)),
                              ],
                            ),
                          )
                        : StreamBuilder<bool>(
                            stream: iap.proStatusStream,
                            initialData: iap.isPro,
                            builder: (context, snapshot) {
                              final isPro = snapshot.data ?? false;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _PlanCard(
                                      title: 'Free',
                                      price: '${currencySymbol}0',
                                      period: 'forever',
                                      isActive: !isPro,
                                      features: const [
                                        'Save a few things',
                                        'Basic reminders',
                                        'No visibility into what you use',
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _PlanCard(
                                      title: 'Premium',
                                      price: _displayPrice,
                                      period: _displayPeriod,
                                      perMonthNote:
                                          _isYearly ? _perMonthNote : null,
                                      highlight: true,
                                      isActive: isPro,
                                      features: const [
                                        'Save without limits',
                                        'Reminders at the right moment',
                                        'Control when things come back',
                                        'See what you revisit vs ignore',
                                        'A system you actually rely on',
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  FadeSlideIn(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What actually changes',
                            style: context.text.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        _loading
                            ? const Shimmer(
                                child: SkeletonBox(height: 160, radius: AppRadius.lg))
                            : const _FeatureList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CtaBar(
            isYearly: _isYearly,
            loading: _loading,
            isPurchasing: _isPurchasing,
            displayPrice: _displayPrice,
            displayPeriod: _displayPeriod,
            perMonthNote: _perMonthNote,
            onPressed: _subscribe,
            onRestore: _restore,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upgrade', style: context.text.titleLarge)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.c.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded,
                    size: 30, color: context.c.textTertiary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Could not load plans',
                  style: context.text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _error!,
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadProducts();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF5A8C69)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                size: 24, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "Stop saving things\nyou'll never use",
            style: context.text.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Turn your saved content into something you actually come back to.',
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Billing toggle (sliding pill)
// ─────────────────────────────────────────────
class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.isYearly,
    required this.savingPercent,
    required this.onToggle,
  });

  final bool isYearly;
  final int savingPercent;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border, width: 0.8),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            alignment:
                isYearly ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: c.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ToggleLabel(
                  label: 'Monthly',
                  selected: !isYearly,
                  onTap: () => onToggle(false),
                ),
              ),
              Expanded(
                child: _ToggleLabel(
                  label: 'Yearly',
                  selected: isYearly,
                  onTap: () => onToggle(true),
                  badge: savingPercent > 0 ? 'Save $savingPercent%' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: selected ? c.textPrimary : c.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.xs + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.xs - 2),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    this.isActive = false,
    this.highlight = false,
    this.perMonthNote,
  });

  final String title;
  final String price;
  final String period;
  final String? perMonthNote;
  final List<String> features;
  final bool isActive;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final titleColor = highlight ? c.primary : c.textSecondary;
    final priceColor = highlight ? c.primary : c.textPrimary;
    final featureColor = highlight ? c.primary : c.textSecondary;
    final checkColor = highlight ? c.primary : c.textTertiary;

    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.primarySurface,
                  Color.lerp(c.primarySurface, c.surface, 0.45)!,
                ],
              )
            : null,
        color: highlight ? null : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlight ? AppColors.primary : c.border,
          width: highlight ? 1.4 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: priceColor,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: ' $period',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          if (perMonthNote != null) ...[
            const SizedBox(height: 4),
            Text(
              perMonthNote!,
              style: TextStyle(
                fontSize: 10,
                color: titleColor.withValues(alpha: 0.75),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.check_rounded, size: 13, color: checkColor),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        color: featureColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: highlight
                    ? Colors.white.withValues(alpha: 0.6)
                    : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                'Current plan',
                style: TextStyle(
                  fontSize: 11,
                  color: highlight ? c.primary : c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Feature list
// ─────────────────────────────────────────────
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _features = [
    (
      title: 'Flexible organization',
      subtitle: 'Structure your ideas in a way that makes sense to you',
    ),
    (
      title: 'Right-time reminders',
      subtitle: 'Your content comes back when you actually have time',
    ),
    (
      title: 'Full control',
      subtitle: 'Decide how often, when, and when to stop',
    ),
    (
      title: 'Clarity on your behavior',
      subtitle: 'See what you use, ignore, and what truly matters',
    ),
    (
      title: 'Weekly reset',
      subtitle: 'A simple loop that keeps your saved content alive',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(_features.length, (i) {
          final f = _features[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.title, style: context.text.titleSmall),
                          const SizedBox(height: 2),
                          Text(f.subtitle, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _features.length - 1)
                Divider(
                  height: 0,
                  thickness: 0.8,
                  color: c.border,
                  indent: 56,
                  endIndent: AppSpacing.lg,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sticky CTA bar
// ─────────────────────────────────────────────
class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.isYearly,
    required this.loading,
    required this.isPurchasing,
    required this.displayPrice,
    required this.displayPeriod,
    required this.perMonthNote,
    required this.onPressed,
    required this.onRestore,
  });

  final bool isYearly;
  final bool loading;
  final bool isPurchasing;
  final String displayPrice;
  final String displayPeriod;
  final String perMonthNote;
  final VoidCallback onPressed;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final busy = loading || isPurchasing;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 0.8)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GradientCta(
            busy: busy,
            label: 'Upgrade to Premium  ·  $displayPrice$displayPeriod',
            onPressed: loading ? null : onPressed,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isYearly
                ? '$perMonthNote · Cancel anytime'
                : 'Billed monthly · Cancel anytime · Secure payment',
            textAlign: TextAlign.center,
            style: context.text.labelSmall,
          ),
          TextButton(
            onPressed: isPurchasing ? null : onRestore,
            child: const Text('Restore purchases'),
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return PressableScale(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      pressedScale: 0.97,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.7,
        duration: AppMotion.fast,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF5A8C69)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: context.text.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
