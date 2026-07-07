// 应用启动入口。这里负责初始化依赖、恢复本地状态，并挂载带路由和国际化能力的根组件。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

import 'core/layout/app_layout.dart';
import 'core/error/app_error_handling.dart';
import 'core/l10n/l10n.dart';
import 'core/l10n/locale_controller.dart';
import 'core/di/injector.dart';
import 'core/network/auth_session_store.dart';
import 'core/platform/app_identity.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandling();

  // 状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await AppIdentity.initialize();
  initInjector();
  setPreviewAuthenticated(await getIt<AuthSessionStore>().hasSession());

  runZonedGuarded(() {
    runApp(const ProviderScope(child: MyApp()));
  }, reportZoneError);
}

class MyApp extends ConsumerWidget {
  /// 应用根组件。统一挂载主题、路由和国际化配置，让整棵页面树共享同一套应用级上下文。
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    initInjector();
    final locale = ref.watch(localeControllerProvider).asData?.value;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) =>
          AppOrientationGate(child: child ?? const SizedBox.shrink()),
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F6FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A8FE8),
          brightness: Brightness.light,
        ),
        // 全局去掉 AppBar 阴影
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F2540)),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2540),
          ),
        ),
        // 输入框全局样式
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F9FF),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x264A8FE8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x264A8FE8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A8FE8), width: 1.5),
          ),
        ),
        // 主按钮全局样式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
