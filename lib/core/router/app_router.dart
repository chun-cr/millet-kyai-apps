// 应用级路由配置入口。统一收口登录、扫描、报告、个人中心等页面的路径声明与鉴权跳转规则。

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:millet_kyai_apps/features/home/presentation/pages/home_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/register_page.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/scan_guide_page.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/face_scan_page.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/tongue_scan_page.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/palm_scan_page.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/physique_question_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/settings_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/account_security_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/points_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/set_login_password_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/shipping_address_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_project_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_product_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_share_landing_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_checkout_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_project_detail_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_product_detail_page.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_page.dart';

// ─── 路由路径常量 ─────────────────────────────────────────────────
class AppRoutes {
  /// 路由常量集合。
  /// 统一给导航、重定向和深链解析使用，避免各页面散落硬编码路径。
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const completeProfile = '/complete-profile';
  static const scan = '/scan';
  static const scanFace = '/scan/face';
  static const scanTongue = '/scan/tongue';
  static const scanPalm = '/scan/palm';
  static const scanQuestionnaire = '/scan/questionnaire';
  static const report = '/report';
  static const reportShareLanding = '/report/share/landing';
  static const reportAnalysis = '/report/analysis';
  static const reportProjectDetail = '/report/project';
  static const reportProductDetail = '/report/product';
  static const reportCheckout = '/report/checkout';
  static const history = '/history';
  static const profile = '/profile';
  static const profileAddresses = '/profile/addresses';
  static const profilePoints = '/profile/points';
  static const settings = '/profile/settings';
  static const accountSecurity = '/profile/settings/account-security';
  static const setLoginPassword =
      '/profile/settings/account-security/set-login-password';
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _buildRedirectTarget(Uri uri) {
  final path = uri.path.trim();
  if (path.isEmpty || path == AppRoutes.login || path == AppRoutes.register) {
    return null;
  }
  final queryParameters = Map<String, String>.from(uri.queryParameters)
    ..remove('redirect');
  return Uri(
    path: path,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

Map<String, String> _buildAuthRedirectQueryParameters(Uri uri) {
  final queryParameters = <String, String>{};
  final shareId = _trimmedOrNull(uri.queryParameters['shareId']);
  final sharerId = _trimmedOrNull(uri.queryParameters['sharerId']);
  final visitorKey = _trimmedOrNull(uri.queryParameters['visitorKey']);
  final inviteTicket = _trimmedOrNull(uri.queryParameters['inviteTicket']);
  final redirect = _buildRedirectTarget(uri);

  if (shareId != null) {
    queryParameters['shareId'] = shareId;
  }
  if (sharerId != null) {
    queryParameters['sharerId'] = sharerId;
  }
  if (visitorKey != null) {
    queryParameters['visitorKey'] = visitorKey;
  }
  if (inviteTicket != null) {
    queryParameters['inviteTicket'] = inviteTicket;
  }
  if (redirect != null) {
    queryParameters['redirect'] = redirect;
  }

  return queryParameters;
}

final ValueNotifier<bool> _previewAuthState = ValueNotifier<bool>(false);

bool get isPreviewAuthenticated => _previewAuthState.value;

// 在 Web 调试态下放开预览鉴权拦截，方便浏览器联调；其它场景仍保持正常登录门槛。
bool get _bypassPreviewAuthGuardForWebDebug => kDebugMode && kIsWeb;

String? resolvePreviewAuthRedirect({
  required String matchedLocation,
  required Uri currentUri,
  required bool isAuthenticated,
  required bool bypassAuthGuard,
}) {
  // 登录/注册、资料补全、分享落地页属于预览态下允许无会话访问的入口。
  final isEntryAuthRoute =
      matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.register;
  final isProfileCompletionRoute = matchedLocation == AppRoutes.completeProfile;
  final isPublicLandingRoute = matchedLocation == AppRoutes.reportShareLanding;

  if (!bypassAuthGuard &&
      !isAuthenticated &&
      !isEntryAuthRoute &&
      !isProfileCompletionRoute &&
      !isPublicLandingRoute) {
    final queryParameters = _buildAuthRedirectQueryParameters(currentUri);
    if (queryParameters.isEmpty) {
      return AppRoutes.login;
    }
    return Uri(
      path: AppRoutes.login,
      queryParameters: queryParameters,
    ).toString();
  }

  if (isAuthenticated && isEntryAuthRoute) {
    return AppRoutes.home;
  }

  return null;
}

void setPreviewAuthenticated(bool value) {
  if (_previewAuthState.value == value) {
    return;
  }
  _previewAuthState.value = value;
}

// ─── 路由配置 ─────────────────────────────────────────────────────
ReportPage _buildReportPage(GoRouterState state) {
  final reportId =
      state.uri.queryParameters['reportId'] ??
      (state.extra is String ? state.extra as String : null);
  return ReportPage(reportId: reportId);
}

/// 应用共享路由实例。
/// 既提供给 `MaterialApp.router` 挂载，也承担预览态下的鉴权跳转逻辑。
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: true,
  refreshListenable: _previewAuthState,
  redirect: (context, state) => resolvePreviewAuthRedirect(
    matchedLocation: state.matchedLocation,
    currentUri: state.uri,
    isAuthenticated: isPreviewAuthenticated,
    bypassAuthGuard: _bypassPreviewAuthGuardForWebDebug,
  ),
  routes: [
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const MainShell(),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 首页从底层轻微放大、淡入显现（拨云见日）
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final scaleAnim = Tween<double>(
            begin: 0.96,
            end: 1.0,
          ).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: scaleAnim, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(
        inviteTicket: state.uri.queryParameters['inviteTicket'],
        initialMode: state.uri.queryParameters['mode'],
        shareId: state.uri.queryParameters['shareId'],
        sharerId: state.uri.queryParameters['sharerId'],
        visitorKey: state.uri.queryParameters['visitorKey'],
        redirectLocation: state.uri.queryParameters['redirect'],
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => LoginPage(
        inviteTicket: state.uri.queryParameters['inviteTicket'],
        initialMode: state.uri.queryParameters['mode'],
        shareId: state.uri.queryParameters['shareId'],
        sharerId: state.uri.queryParameters['sharerId'],
        visitorKey: state.uri.queryParameters['visitorKey'],
        redirectLocation: state.uri.queryParameters['redirect'],
      ),
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (context, state) => CompleteProfilePage(
        redirectLocation: state.uri.queryParameters['redirect'],
      ),
    ),
    GoRoute(
      path: AppRoutes.scan,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        child: const ScanGuidePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.scanFace,
      builder: (context, state) => const FaceScanPage(),
    ),
    GoRoute(
      path: AppRoutes.scanTongue,
      builder: (context, state) => const TongueScanPage(),
    ),
    GoRoute(
      path: AppRoutes.scanPalm,
      builder: (context, state) => const PalmScanPage(),
    ),
    GoRoute(
      path: AppRoutes.scanQuestionnaire,
      builder: (context, state) => const PhysiqueQuestionPage(),
    ),
    GoRoute(
      path: AppRoutes.reportShareLanding,
      builder: (context, state) =>
          ReportShareLandingPage(initialUri: state.uri),
    ),
    GoRoute(
      path: AppRoutes.reportProjectDetail,
      builder: (context, state) {
        final project = switch (state.extra) {
          final ReportProjectData extraProject => extraProject,
          _ => ReportProjectData.fromRouteQueryParameters(
            state.uri.queryParameters,
          ),
        };
        if (project == null) {
          return _buildReportPage(state);
        }
        return ReportProjectDetailPage(project: project);
      },
    ),
    GoRoute(
      path: AppRoutes.reportProductDetail,
      builder: (context, state) {
        final product = state.extra;
        if (product is! ReportProductData) {
          return _buildReportPage(state);
        }
        return ReportProductDetailPage(product: product);
      },
    ),
    GoRoute(
      path: AppRoutes.reportCheckout,
      builder: (context, state) {
        final args = state.extra;
        if (args is! ReportCheckoutArgs) {
          return _buildReportPage(state);
        }
        return ReportCheckoutPage(args: args);
      },
    ),
    GoRoute(
      path: AppRoutes.reportAnalysis,
      builder: (context, state) => _buildReportPage(state),
    ),
    GoRoute(
      path: AppRoutes.report,
      builder: (context, state) => _buildReportPage(state),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryReportPage(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.profileAddresses,
      builder: (context, state) => const ShippingAddressPage(),
    ),
    GoRoute(
      path: AppRoutes.profilePoints,
      builder: (context, state) => const PointsPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.accountSecurity,
      builder: (context, state) => const AccountSecurityPage(),
    ),
    GoRoute(
      path: AppRoutes.setLoginPassword,
      builder: (context, state) => const SetLoginPasswordPage(),
    ),
  ],
);
