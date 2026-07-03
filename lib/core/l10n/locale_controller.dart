// 语言状态控制器。负责持久化当前语言选择，并通过 Riverpod 向界面广播 locale 变化。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:millet_kyai_apps/core/l10n/l10n.dart';

const _localePreferenceKey = 'app_locale';

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale?> {
  @override
  FutureOr<Locale?> build() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_localePreferenceKey);
    return parseLocaleTag(storedValue);
  }

  Future<void> setLocale(Locale? locale) async {
    final preferences = await SharedPreferences.getInstance();
    if (locale == null) {
      await preferences.remove(_localePreferenceKey);
      state = const AsyncData(null);
      return;
    }

    final serialized = localeToLanguageTag(locale);
    if (serialized == null) {
      await preferences.remove(_localePreferenceKey);
      state = const AsyncData(null);
      return;
    }

    await preferences.setString(_localePreferenceKey, serialized);
    state = AsyncData(locale);
  }
}
