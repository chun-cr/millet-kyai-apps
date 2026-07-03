// 认证模块共享组件：`AuthLocaleButton`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/locale_controller.dart';
import 'package:millet_kyai_apps/core/l10n/locale_sheet.dart';

class AuthLocaleButton extends StatelessWidget {
  const AuthLocaleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final hasProviderScope = _hasProviderScope(context);
    if (!hasProviderScope) {
      return _AuthLocaleButtonBody(
        badgeLabel: appLocaleBadgeLabel(Localizations.localeOf(context)),
        semanticLabel: context.l10n.profileMenuLanguage,
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final selectedLocale = ref
            .watch(localeControllerProvider)
            .asData
            ?.value;
        final effectiveLocale =
            selectedLocale ?? Localizations.localeOf(context);
        return _AuthLocaleButtonBody(
          badgeLabel: appLocaleBadgeLabel(effectiveLocale),
          semanticLabel: context.l10n.profileMenuLanguage,
          onTap: () =>
              showAppLocaleSheet(context, ref, selectedLocale: selectedLocale),
        );
      },
    );
  }

  bool _hasProviderScope(BuildContext context) {
    try {
      ProviderScope.containerOf(context, listen: false);
      return true;
    } on StateError {
      return false;
    }
  }
}

class _AuthLocaleButtonBody extends StatelessWidget {
  const _AuthLocaleButtonBody({
    required this.badgeLabel,
    required this.semanticLabel,
    this.onTap,
  });

  final String badgeLabel;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 18,
                      color: Color(0xFF2D6A4F),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        badgeLabel,
                        key: ValueKey<String>(badgeLabel),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D6A4F),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
