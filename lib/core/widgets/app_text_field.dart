import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// ─────────────────────────────────────────────
/// ⌨️  AppTextField
///
/// Thin wrapper over [TextField] that leans on the global
/// inputDecorationTheme, with optional leading icon and a consistent look.
/// ─────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.icon,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 19),
        suffixIcon: suffix,
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// 🔍  SearchField
///
/// A rounded, self-contained search box with an animated clear button.
/// ─────────────────────────────────────────────
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.hint = 'Search…',
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final has = v.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border, width: 0.8),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.search_rounded, size: 19, color: c.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: widget.hint,
                hintStyle: context.text.bodyMedium?.copyWith(
                  color: c.textTertiary,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
                    splashRadius: 18,
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  )
                : const SizedBox(key: ValueKey('empty'), width: AppSpacing.md),
          ),
        ],
      ),
    );
  }
}
