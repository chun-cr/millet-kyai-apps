// 认证模块展示层工具：`VerificationCodeFeedback`。负责承载展示层通用的计算、映射或调试辅助逻辑。

import 'package:flutter/widgets.dart';

String verificationCodeSentSuccessMessage(
  BuildContext context, {
  required bool isEmail,
  required String fallbackMessage,
}) {
  if (!isEmail) {
    return fallbackMessage;
  }
  final locale = Localizations.localeOf(context).languageCode;
  return switch (locale) {
    'en' =>
      'Verification code sent. If you do not see it, check your spam folder.',
    'ja' => '認証コードを送信しました。届かない場合は迷惑メールをご確認ください。',
    'ko' => '인증코드를 보냈어요. 받지 못했다면 스팸 메일함을 확인해 주세요.',
    _ => '验证码已发送，如未收到请检查垃圾邮件箱。',
  };
}
