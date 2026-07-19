import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/widgets.dart';
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

  String get _storeLabel => Platform.isAndroid ? 'Google Play' : 'App Store';

  @override
  Widget build(BuildContext context) {
    if (_isForced) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: _Body(
              updateNote: _updateNote,
              storeLabel: _storeLabel,
              isForced: true,
              onUpdate: onUpdate,
              onLater: null,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Update available', style: context.text.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onLater ?? () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: _Body(
          updateNote: _updateNote,
          storeLabel: _storeLabel,
          isForced: false,
          onUpdate: onUpdate,
          onLater: onLater ?? () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.updateNote,
    required this.storeLabel,
    required this.isForced,
    required this.onUpdate,
    required this.onLater,
  });

  final String updateNote;
  final String storeLabel;
  final bool isForced;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                AppSpacing.xxl, AppSpacing.screen, AppSpacing.xxl),
            child: FadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UpdateHeader(isForced: isForced),
                  const SizedBox(height: AppSpacing.xxl),
                  _WhatsNewCard(updateNote: updateNote),
                ],
              ),
            ),
          ),
        ),
        _CtaBar(
          isForced: isForced,
          storeLabel: storeLabel,
          onUpdate: onUpdate,
          onLater: onLater,
        ),
      ],
    );
  }
}

class _UpdateHeader extends StatelessWidget {
  const _UpdateHeader({required this.isForced});

  final bool isForced;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF5A8C69)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.system_update_rounded,
              size: 28, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isForced ? 'Update required\nto continue' : 'A new version\nis available',
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isForced
              ? 'This version is no longer supported. Please update to keep using the app.'
              : 'Get the latest features and improvements by updating now.',
          style: context.text.bodyMedium,
        ),
      ],
    );
  }
}

class _WhatsNewCard extends StatelessWidget {
  const _WhatsNewCard({required this.updateNote});

  final String updateNote;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final textColor = c.textPrimary;
    final subtleColor = c.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What's new", style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
          child: updateNote.trim().isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text('No release notes provided.',
                      style: context.text.bodySmall),
                )
              : Html(
                  data: updateNote,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(13),
                      color: textColor,
                      fontFamily: 'inherit',
                      lineHeight: const LineHeight(1.5),
                    ),
                    'h1,h2,h3,h4': Style(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      margin: Margins.only(top: 8, bottom: 4),
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 8),
                      color: textColor,
                      padding: HtmlPaddings.zero,
                    ),
                    'ul,ol': Style(
                      margin: Margins.only(bottom: 8, left: 16),
                      padding: HtmlPaddings.zero,
                      color: textColor,
                    ),
                    'li': Style(
                      color: textColor,
                      margin: Margins.only(bottom: 4),
                    ),
                    'strong,b': Style(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    'em,i': Style(
                      fontStyle: FontStyle.italic,
                      color: subtleColor,
                    ),
                    'code': Style(
                      backgroundColor: c.surfaceVariant,
                      color: subtleColor,
                      padding:
                          HtmlPaddings.symmetric(horizontal: 4, vertical: 1),
                    ),
                    'hr': Style(
                      color: c.border,
                      margin: Margins.symmetric(vertical: 8),
                    ),
                    'a': Style(
                      color: AppColors.primary,
                      textDecorationColor: AppColors.primary,
                    ),
                  },
                ),
        ),
      ],
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.isForced,
    required this.storeLabel,
    required this.onUpdate,
    required this.onLater,
  });

  final bool isForced;
  final String storeLabel;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 0.8)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
          AppSpacing.screen, AppSpacing.md + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'Update on $storeLabel',
            icon: Icons.download_rounded,
            onPressed: onUpdate,
          ),
          if (!isForced) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton.ghost(label: 'Later', onPressed: onLater),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You must update to continue using the app.',
              textAlign: TextAlign.center,
              style: context.text.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
