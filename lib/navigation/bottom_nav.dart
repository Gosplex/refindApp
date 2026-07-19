import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/colors.dart';
import '../core/theme/theme_x.dart';
import '../core/widgets/motion.dart';
import '../features/analytics/screens/analytic_screen.dart';
import '../features/collection/screen/collection_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CollectionsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  static const List<_NavItem> _items = [
    _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem('Collections', Icons.folder_outlined, Icons.folder_rounded),
    _NavItem('Analytics', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _FloatingNavBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

/// A floating, rounded navigation bar with an expanding-pill selected tab.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: c.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 28,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return _NavTile(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final activeColor = AppColors.primary;
    final inactiveColor = c.textSecondary;

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? AppSpacing.lg : AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                size: 23,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            // Label expands into view only when selected.
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Text(
                        item.label,
                        style: context.text.labelMedium?.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
