import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../core/theme/colors.dart';
import 'app_update_model.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({
    super.key,
    required this.model,
    this.onUpdate,
    this.onLater,
  });

  final AppUpdateModel model;

  final VoidCallback? onUpdate;

  final VoidCallback? onLater;

  bool get _isForced => model.forceUpdate;

  String get _updateNote =>
      Platform.isAndroid ? model.androidNote : model.iosNote;

  String get _storeLabel =>
      Platform.isAndroid ? 'Google Play' : 'App Store';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isForced) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(child: _Body(
            isDark:     isDark,
            updateNote: _updateNote,
            storeLabel: _storeLabel,
            isForced:   true,
            onUpdate:   onUpdate,
            onLater:    null,
          )),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Available',
            style: Theme.of(context).textTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onLater ?? () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: _Body(
          isDark:     isDark,
          updateNote: _updateNote,
          storeLabel: _storeLabel,
          isForced:   false,
          onUpdate:   onUpdate,
          onLater:    onLater ?? () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.isDark,
    required this.updateNote,
    required this.storeLabel,
    required this.isForced,
    required this.onUpdate,
    required this.onLater,
  });

  final bool          isDark;
  final String        updateNote;
  final String        storeLabel;
  final bool          isForced;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UpdateHeader(isDark: isDark, isForced: isForced),
                const SizedBox(height: 28),
                _WhatsNewCard(
                  isDark:     isDark,
                  updateNote: updateNote,
                ),
              ],
            ),
          ),
        ),
        _CtaBar(
          isDark:     isDark,
          isForced:   isForced,
          storeLabel: storeLabel,
          onUpdate:   onUpdate,
          onLater:    onLater,
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────

class _UpdateHeader extends StatelessWidget {
  const _UpdateHeader({required this.isDark, required this.isForced});

  final bool isDark;
  final bool isForced;

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
            Icons.system_update_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isForced
              ? 'Update required\nto continue'
              : 'A new version\nis available',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isForced
              ? 'This version is no longer supported. Please update to keep using the app.'
              : 'Get the latest features and improvements by updating now.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────
// What's New card — HTML rendered via flutter_html
// ─────────────────────────────────────────────────────────────

class _WhatsNewCard extends StatelessWidget {
  const _WhatsNewCard({required this.isDark, required this.updateNote});

  final bool   isDark;
  final String updateNote;

  @override
  Widget build(BuildContext context) {
    final bg          = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark  : AppColors.border;
    final bodySmall   = Theme.of(context).textTheme.bodySmall;
    final titleSmall  = Theme.of(context).textTheme.titleSmall;

    // Colours fed into flutter_html so the rendered HTML respects the theme.
    final textColor   = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final subtleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's new",
          style: titleSmall,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: borderColor, width: 0.8),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: updateNote.trim().isEmpty
              ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No release notes provided.',
              style: bodySmall,
            ),
          )
              : Html(
            data: updateNote,
            style: {
              // Root
              'body': Style(
                margin:     Margins.zero,
                padding:    HtmlPaddings.zero,
                fontSize:   FontSize(13),
                color:      textColor,
                fontFamily: 'inherit',
                lineHeight: const LineHeight(1.5),
              ),
              // Headings
              'h1,h2,h3,h4': Style(
                color:      textColor,
                fontWeight: FontWeight.w600,
                margin:     Margins.only(top: 8, bottom: 4),
              ),
              // Paragraph
              'p': Style(
                margin:  Margins.only(bottom: 8),
                color:   textColor,
                padding: HtmlPaddings.zero,
              ),
              // Lists
              'ul,ol': Style(
                margin:  Margins.only(bottom: 8, left: 16),
                padding: HtmlPaddings.zero,
                color:   textColor,
              ),
              'li': Style(
                color:  textColor,
                margin: Margins.only(bottom: 4),
              ),
              // Strong / bold
              'strong,b': Style(
                fontWeight: FontWeight.w600,
                color:      textColor,
              ),
              // Em / italic
              'em,i': Style(
                fontStyle: FontStyle.italic,
                color:     subtleColor,
              ),
              // Inline code
              'code': Style(
                backgroundColor: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                color:   subtleColor,
                padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 1),
              ),
              // Horizontal rule
              'hr': Style(
                color:  borderColor,
                margin: Margins.symmetric(vertical: 8),
              ),
              // Anchor (don't style as hyperlink blue)
              'a': Style(
                color:                AppColors.primary,
                textDecorationColor:  AppColors.primary,
              ),
            },
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────
// CTA bar (mirrors _CtaBar in subscription_screen.dart)
// ─────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.isDark,
    required this.isForced,
    required this.storeLabel,
    required this.onUpdate,
    required this.onLater,
  });

  final bool          isDark;
  final bool          isForced;
  final String        storeLabel;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor  = isDark ? AppColors.borderDark  : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color:  surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width:  double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onUpdate,
              child: Text('Update on $storeLabel'),
            ),
          ),
          if (!isForced) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onLater,
              child: const Text('Later'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'You must update to continue using the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}