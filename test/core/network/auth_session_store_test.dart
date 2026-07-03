import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthSessionStore.debugUseMemoryBackend = true;
  });

  tearDown(() {
    AuthSessionStore.debugUseMemoryBackend = false;
  });

  test(
    'migrates legacy plaintext session into the active backend and clears it',
    () async {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'legacy-access',
        'auth_refresh_token': 'legacy-refresh',
        'auth_token_type': 'Bearer',
        'auth_expires_in': 3600,
        'auth_expires_at_epoch_ms': expiresAt.millisecondsSinceEpoch,
        'auth_scope': 'mobile',
      });

      final store = AuthSessionStore();

      expect(await store.hasSession(), isTrue);
      expect(await store.authorizationHeader(), 'Bearer legacy-access');
      expect(await store.refreshToken(), 'legacy-refresh');
      expect(
        await store.shouldRefreshAccessToken(
          now: expiresAt.subtract(const Duration(minutes: 5)),
        ),
        isFalse,
      );

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('auth_access_token'), isNull);
      expect(preferences.getString('auth_refresh_token'), isNull);
      expect(preferences.getString('auth_token_type'), isNull);
      expect(preferences.getInt('auth_expires_in'), isNull);
      expect(preferences.getInt('auth_expires_at_epoch_ms'), isNull);
      expect(preferences.getString('auth_scope'), isNull);
    },
  );
}
