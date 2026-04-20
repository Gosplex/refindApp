import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../core/theme/colors.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];

  static const List<_NavItem> _items = [
    _NavItem(
      label:         'Home',
      icon:          Icons.home_outlined,
      activeIcon:    Icons.home_rounded,
    ),
    _NavItem(
      label:         'Settings',
      icon:          Icons.settings_outlined,
      activeIcon:    Icons.settings_rounded,
    ),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor  = isDark ? AppColors.borderDark  : AppColors.border;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_items.length, (index) {
                final item     = _items[index];
                final selected = index == _currentIndex;
                return Expanded(
                  child: _NavTile(
                    item:     item,
                    selected: selected,
                    onTap:    () => _onTap(index),
                    isDark:   isDark,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}


class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final _NavItem  item;
  final bool     selected;
  final VoidCallback onTap;
  final bool     isDark;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double>  _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _)   => _controller.reverse();
  void _onTapCancel()               => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final activeColor   = AppColors.primary;
    final inactiveColor = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return GestureDetector(
      onTap:       widget.onTap,
      onTapDown:   _onTapDown,
      onTapUp:     _onTapUp,
      onTapCancel: _onTapCancel,
      behavior:    HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve:    Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve:    Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical:   4,
                ),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.primaryMuted
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.selected ? widget.item.activeIcon : widget.item.icon,
                  size:  22,
                  color: widget.selected ? activeColor : inactiveColor,
                ),
              ),

              const SizedBox(height: 3),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: widget.selected
                      ? FontWeight.w500
                      : FontWeight.w400,
                  color: widget.selected ? activeColor : inactiveColor,
                ),
                child: Text(widget.item.label),
              ),

            ],
          ),
        ),
      ),
    );
  }
}


class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String   label;
  final IconData icon;
  final IconData activeIcon;
}