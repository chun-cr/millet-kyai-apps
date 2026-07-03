// 国际化格式化辅助函数。封装日期、数字等展示层常用格式，减少页面里散落的本地化拼装逻辑。

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatShortDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMd(locale).format(date);
}

String formatIsoLikeDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  if (locale.startsWith('zh')) {
    return DateFormat('yyyy-MM-dd', locale).format(date);
  }
  return DateFormat.yMd(locale).format(date);
}
