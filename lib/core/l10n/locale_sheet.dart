// 语言切换底部弹层。封装语言列表、选中态和切换交互，供多个页面复用。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/locale_controller.dart';

String appLocaleLabel(BuildContext context, Locale? locale) {
  if (locale == null) {
    return context.l10n.localeFollowSystem;
  }
  switch (locale.languageCode) {
    case 'zh':
      return context.l10n.localeChineseSimplified;
    case 'en':
      return context.l10n.localeEnglish;
    case 'ja':
      return context.l10n.localeJapanese;
    case 'ko':
      return context.l10n.localeKorean;
    default:
      return context.l10n.localeFollowSystem;
  }
}

String appLocaleBadgeLabel(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return '中文';
    case 'en':
      return 'EN';
    case 'ja':
      return '日本語';
    case 'ko':
      return '한국어';
    default:
      return locale.languageCode.toUpperCase();
  }
}

Future<void> showAppLocaleSheet(
  BuildContext context,
  WidgetRef ref, {
  Locale? selectedLocale,
  Color backgroundColor = Colors.white,
  Color primaryColor = const Color(0xFF2D6A4F),
  Color dividerColor = const Color(0xFFF0EDE5),
  Color textPrimaryColor = const Color(0xFF1E1810),
  Color textHintColor = const Color(0xFFA09080),
}) async {
  final controller = ref.read(localeControllerProvider.notifier);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final options = <({Locale? locale, String label})>[
        (locale: null, label: context.l10n.localeFollowSystem),
        (
          locale: const Locale('zh'),
          label: context.l10n.localeChineseSimplified,
        ),
        (locale: const Locale('en'), label: context.l10n.localeEnglish),
        (locale: const Locale('ja'), label: context.l10n.localeJapanese),
        (locale: const Locale('ko'), label: context.l10n.localeKorean),
      ];

      bool isSelected(Locale? candidate) {
        if (candidate == null || selectedLocale == null) {
          return candidate == selectedLocale;
        }
        return candidate.languageCode == selectedLocale.languageCode;
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.localeSheetTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((option) {
                final selected = isSelected(option.locale);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await controller.setLocale(option.locale);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? primaryColor : textPrimaryColor,
                            ),
                          ),
                        ),
                        if (selected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.72),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                        else
                          const SizedBox(width: 22, height: 22),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
