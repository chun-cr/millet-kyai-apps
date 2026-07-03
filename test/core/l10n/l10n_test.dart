import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';

void main() {
  group('parseLocaleTag', () {
    test('returns null for empty input', () {
      expect(parseLocaleTag(null), isNull);
      expect(parseLocaleTag(''), isNull);
    });

    test('parses language-only tags', () {
      expect(parseLocaleTag('zh'), const Locale('zh'));
      expect(parseLocaleTag('en'), const Locale('en'));
      expect(parseLocaleTag('ja'), const Locale('ja'));
      expect(parseLocaleTag('ko'), const Locale('ko'));
    });

    test('parses locale tags with country code', () {
      expect(parseLocaleTag('en_US'), const Locale('en', 'US'));
      expect(parseLocaleTag('zh-CN'), const Locale('zh', 'CN'));
    });
  });

  group('localeToLanguageTag', () {
    test('serializes locale safely', () {
      expect(localeToLanguageTag(null), isNull);
      expect(localeToLanguageTag(const Locale('zh')), 'zh');
      expect(localeToLanguageTag(const Locale('en', 'US')), 'en_US');
      expect(localeToLanguageTag(const Locale('ja')), 'ja');
      expect(localeToLanguageTag(const Locale('ko')), 'ko');
    });
  });
}
