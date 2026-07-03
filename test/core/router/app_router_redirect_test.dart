import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';

void main() {
  group('resolvePreviewAuthRedirect', () {
    test('redirects unauthenticated protected routes to login', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.home,
          currentUri: Uri(path: AppRoutes.home),
          isAuthenticated: false,
          bypassAuthGuard: false,
        ),
        Uri(
          path: AppRoutes.login,
          queryParameters: {'redirect': AppRoutes.home},
        ).toString(),
      );
    });

    test('keeps home accessible when web debug bypass is enabled', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.home,
          currentUri: Uri(path: AppRoutes.home),
          isAuthenticated: false,
          bypassAuthGuard: true,
        ),
        isNull,
      );
    });

    test('keeps complete profile route accessible without session', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.completeProfile,
          currentUri: Uri(path: AppRoutes.completeProfile),
          isAuthenticated: false,
          bypassAuthGuard: false,
        ),
        isNull,
      );
    });

    test('keeps report share landing accessible without session', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.reportShareLanding,
          currentUri: Uri(
            path: AppRoutes.reportShareLanding,
            queryParameters: {'reportId': 'report-1'},
          ),
          isAuthenticated: false,
          bypassAuthGuard: false,
        ),
        isNull,
      );
    });

    test('redirects authenticated users away from login', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.login,
          currentUri: Uri(path: AppRoutes.login),
          isAuthenticated: true,
          bypassAuthGuard: false,
        ),
        AppRoutes.home,
      );
    });
  });
}
