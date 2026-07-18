import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import '../../core/theme/colors.dart';
import '../../services/in_app_purchase_service.dart';
import 'package:intl/intl.dart';

import '../auth/auth_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isYearly = true;

  final iap = InAppPurchaseService();

  bool _loading = true;
  bool _isPurchasing = false;
  String? _error;

  Package? get _monthly => iap.monthlyPackage;
  Package? get _yearly => iap.yearlyPackage;

  NumberFormat _currencyFormatter(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return NumberFormat.simpleCurrency(locale: locale);
  }

  String get currencySymbol {
    final package = _yearly ?? _monthly;

    if (package == null) return '';

    return package.storeProduct.priceString.replaceAll(
      RegExp(r'[0-9.,\s]'),
      '',
    );
  }

  final auth = AuthService();

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
    return '$perMonth / month · billed yearly';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("You're now Premium 🚀")));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Purchase Error $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed or cancelled')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
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
      print("Restore Error $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Restore failed")));
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<bool?> _showLoginRequiredSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Icon(Icons.lock_outline, size: 40),

              const SizedBox(height: 16),

              Text(
                "Sign in required",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              Text(
                "To keep your subscription across devices, please sign in with Google.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Continue with Google"),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Upgrade',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load plans',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadProducts();
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(isDark: isDark),

                  const SizedBox(height: 28),

                  // Billing toggle — shimmer while loading
                  _loading
                      ? _ShimmerBlock(
                          width: double.infinity,
                          height: 46,
                          radius: 12,
                          isDark: isDark,
                        )
                      : _BillingToggle(
                          isYearly: _isYearly,
                          savingPercent: _savingPercent,
                          isDark: isDark,
                          onToggle: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _isYearly = val);
                          },
                        ),

                  const SizedBox(height: 16),

                  // Plan cards — shimmer while loading
                  _loading
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ShimmerBlock(
                                width: double.infinity,
                                height: 200,
                                radius: 16,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ShimmerBlock(
                                width: double.infinity,
                                height: 200,
                                radius: 16,
                                isDark: isDark,
                              ),
                            ),
                          ],
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
                                    // price: _currencyFormatter(context).format(0),
                                    period: 'forever',
                                    isActive: !isPro,
                                    isDark: isDark,
                                    features: const [
                                      'Save a few things',
                                      'Basic reminders',
                                      'No visibility into what you actually use',
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PlanCard(
                                    title: 'Premium',
                                    price: _displayPrice,
                                    period: _displayPeriod,
                                    perMonthNote: _isYearly
                                        ? _perMonthNote
                                        : null,
                                    highlight: true,
                                    isActive: isPro,
                                    isDark: isDark,
                                    features: const [
                                      'Save without limits',
                                      'Get reminded at the right moment',
                                      'Control when things come back',
                                      'Understand what you actually revisit vs ignore',
                                      'Turn saved content into a system you rely on',
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                  const SizedBox(height: 32),

                  Text(
                    'What actually changes',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),

                  const SizedBox(height: 12),

                  _loading
                      ? _ShimmerBlock(
                          width: double.infinity,
                          height: 160,
                          radius: 16,
                          isDark: isDark,
                        )
                      : _FeatureList(isDark: isDark),
                ],
              ),
            ),
          ),

          _CtaBar(
            isDark: isDark,
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
}

// ─────────────────────────────────────────────────────────────
// Shimmer primitives (no external package needed)
// ─────────────────────────────────────────────────────────────

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
    required this.isDark,
  });

  final double width;
  final double height;
  final double radius;
  final bool isDark;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
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
    final base = widget.isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceVariant;
    final hi = widget.isDark ? AppColors.surfaceVariantDark : AppColors.surface;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, hi, _anim.value)!,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Remaining widgets — unchanged from your existing code
// ─────────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.isYearly,
    required this.savingPercent,
    required this.isDark,
    required this.onToggle,
  });

  final bool isYearly;
  final int savingPercent;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final activeText = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final inactiveText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !isYearly ? bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: !isYearly
                      ? Border.all(color: borderColor, width: 0.8)
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Monthly',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: !isYearly ? FontWeight.w500 : FontWeight.w400,
                      color: !isYearly ? activeText : inactiveText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isYearly ? bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: isYearly
                      ? Border.all(color: borderColor, width: 0.8)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yearly',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isYearly
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: isYearly ? activeText : inactiveText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Save $savingPercent%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bookmark_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Stop saving things\nyou’ll never use',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Turn your saved content into something you actually come back to.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isDark,
    this.isActive = false,
    this.highlight = false,
    this.perMonthNote,
  });

  final String title;
  final String price;
  final String period;
  final String? perMonthNote;
  final List<String> features;
  final bool isDark;
  final bool isActive;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? AppColors.primaryMuted
        : (isDark ? AppColors.surfaceDark : AppColors.surface);
    final borderColor = highlight
        ? AppColors.primaryLight
        : (isDark ? AppColors.borderDark : AppColors.border);
    final titleColor = highlight
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);
    final priceColor = highlight
        ? AppColors.primary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final featureColor = highlight
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);
    final checkColor = highlight ? AppColors.primary : AppColors.textTertiary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: highlight ? 1.5 : 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: titleColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w400,
                color: titleColor.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: checkColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Current plan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.isDark});
  final bool isDark;

  static const _features = [
    (
      title: 'Flexible organization',
      subtitle: 'Structure your ideas in a way that actually makes sense to you',
    ),
    (
      title: 'Right-time reminders',
      subtitle: 'Your content comes back when you actually have time for it',
    ),
    (
      title: 'Full control',
      subtitle: 'Decide how often, when, and when to stop',
    ),
    (
      title: 'Clarity on your behavior',
      subtitle: 'See what you use, what you ignore, and what truly matters',
    ),
    (
      title: 'Weekly reset',
      subtitle: 'A simple loop that keeps your saved content alive and useful',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: List.generate(_features.length, (i) {
          final f = _features[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
                  color: borderColor,
                  indent: 56,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.isDark,
    required this.isYearly,
    required this.loading,
    required this.isPurchasing,
    required this.displayPrice,
    required this.displayPeriod,
    required this.perMonthNote,
    required this.onPressed,
    required this.onRestore,
  });

  final bool isDark;
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              child: loading || isPurchasing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Upgrade to Premium  ·  $displayPrice$displayPeriod'),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isYearly
                ? '$perMonthNote · Cancel anytime'
                : 'Billed monthly · Cancel anytime · Secure payment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),

          TextButton(
            onPressed: isPurchasing ? null : onRestore,
            child: const Text("Restore purchases"),
          ),
        ],
      ),
    );
  }
}
