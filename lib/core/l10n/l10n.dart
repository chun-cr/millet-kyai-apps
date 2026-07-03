// 本地化取词扩展。把 generated l10n 的访问方式收敛成更短的 BuildContext 扩展入口。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

const supportedAppLocales = <Locale>[
  Locale('zh'),
  Locale('en'),
  Locale('ja'),
  Locale('ko'),
];

Locale? parseLocaleTag(String? tag) {
  if (tag == null || tag.isEmpty) {
    return null;
  }

  final normalized = tag.replaceAll('-', '_');
  final parts = normalized.split('_');
  if (parts.isEmpty || parts.first.isEmpty) {
    return null;
  }

  final languageCode = parts.first;
  final countryCode = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  return Locale(languageCode, countryCode);
}

String? localeToLanguageTag(Locale? locale) {
  if (locale == null) {
    return null;
  }
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) {
    return locale.languageCode;
  }
  return '${locale.languageCode}_$countryCode';
}
