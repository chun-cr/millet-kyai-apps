// 登录会话存储层。负责持久化 accessToken、refreshToken，并提供会话读写与清理能力。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';

class AuthSessionStore {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _expiresInKey = 'auth_expires_in';
  static const _expiresAtEpochMsKey = 'auth_expires_at_epoch_ms';
  static const _scopeKey = 'auth_scope';

  @visibleForTesting
  static bool debugUseMemoryBackend = false;

  final _SessionBackend _backend = _SessionBackend.create();
  bool _legacyHydrated = false;

  Future<void> saveSession(
    AuthSessionEntity session, {
    DateTime? savedAt,
  }) async {
    await _ensureLegacySessionMigrated();
    final issuedAt = savedAt ?? DateTime.now();
    final expiresAt = issuedAt.add(Duration(seconds: session.expiresIn));
    await _backend.write(<String, Object>{
      _accessTokenKey: session.accessToken,
      _refreshTokenKey: session.refreshToken,
      _tokenTypeKey: session.tokenType,
      _expiresInKey: session.expiresIn,
      _expiresAtEpochMsKey: expiresAt.millisecondsSinceEpoch,
      _scopeKey: session.scope,
    });
    await _clearLegacyPreferences();
  }

  Future<void> clear() async {
    await _ensureLegacySessionMigrated();
    await _backend.clear();
    await _clearLegacyPreferences();
  }

  Future<bool> hasSession() async {
    final session = await _readSession();
    return _requiredString(session, _accessTokenKey) != null;
  }

  Future<String?> refreshToken() async {
    final session = await _readSession();
    return _requiredString(session, _refreshTokenKey);
  }

  Future<String?> authorizationHeader() async {
    final session = await _readSession();
    final accessToken = _requiredString(session, _accessTokenKey);
    if (accessToken == null) {
      return null;
    }

    final tokenType = _requiredString(session, _tokenTypeKey);
    final normalizedType = (tokenType == null || tokenType.isEmpty)
        ? 'Bearer'
        : tokenType;

    return '$normalizedType $accessToken';
  }

  Future<bool> shouldRefreshAccessToken({
    Duration threshold = const Duration(minutes: 1),
    DateTime? now,
  }) async {
    final session = await _readSession();
    final expiresAtEpochMs = _requiredInt(session, _expiresAtEpochMsKey);
    if (expiresAtEpochMs == null) {
      return false;
    }

    final currentTime = now ?? DateTime.now();
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtEpochMs);
    return !expiresAt.isAfter(currentTime.add(threshold));
  }

  Future<Map<String, Object?>> _readSession() async {
    await _ensureLegacySessionMigrated();
    return _backend.read();
  }

  Future<void> _ensureLegacySessionMigrated() async {
    if (_legacyHydrated) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final hasLegacyValues =
        (preferences.getString(_accessTokenKey) ?? '').isNotEmpty ||
        (preferences.getString(_refreshTokenKey) ?? '').isNotEmpty ||
        (preferences.getString(_tokenTypeKey) ?? '').isNotEmpty ||
        (preferences.getInt(_expiresInKey) != null) ||
        (preferences.getInt(_expiresAtEpochMsKey) != null) ||
        (preferences.getString(_scopeKey) ?? '').isNotEmpty;

    if (!hasLegacyValues) {
      _legacyHydrated = true;
      return;
    }

    final existingSession = await _backend.read();
    if (existingSession.isEmpty) {
      final legacyAccessToken = preferences.getString(_accessTokenKey);
      final legacyRefreshToken = preferences.getString(_refreshTokenKey);
      final legacyTokenType = preferences.getString(_tokenTypeKey);
      final legacyExpiresIn = preferences.getInt(_expiresInKey);
      final legacyScope = preferences.getString(_scopeKey);
      final expiresAtEpochMs =
          preferences.getInt(_expiresAtEpochMsKey) ??
          DateTime.now().millisecondsSinceEpoch;

      if ((legacyAccessToken ?? '').isNotEmpty &&
          (legacyRefreshToken ?? '').isNotEmpty &&
          (legacyTokenType ?? '').isNotEmpty &&
          legacyExpiresIn != null &&
          (legacyScope ?? '').isNotEmpty) {
        await _backend.write(<String, Object>{
          _accessTokenKey: legacyAccessToken!,
          _refreshTokenKey: legacyRefreshToken!,
          _tokenTypeKey: legacyTokenType!,
          _expiresInKey: legacyExpiresIn,
          _expiresAtEpochMsKey: expiresAtEpochMs,
          _scopeKey: legacyScope!,
        });
      }
    }

    await _clearLegacyPreferences();
    _legacyHydrated = true;
  }

  Future<void> _clearLegacyPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_expiresInKey);
    await preferences.remove(_expiresAtEpochMsKey);
    await preferences.remove(_scopeKey);
  }

  String? _requiredString(Map<String, Object?>? values, String key) {
    final value = values?[key];
    if (value is! String || value.isEmpty) {
      return null;
    }
    return value;
  }

  int? _requiredInt(Map<String, Object?>? values, String key) {
    final value = values?[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}

abstract class _SessionBackend {
  factory _SessionBackend.create() {
    if (AuthSessionStore.debugUseMemoryBackend || kIsWeb) {
      return _MemorySessionBackend();
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => _HybridSessionBackend(
        _PlatformSecureSessionBackend(),
      ),
      _ => _MemorySessionBackend(),
    };
  }

  Future<Map<String, Object?>> read();
  Future<void> write(Map<String, Object> values);
  Future<void> clear();
}

class _HybridSessionBackend implements _SessionBackend {
  _HybridSessionBackend(this._primary);

  final _SessionBackend _primary;
  final _MemorySessionBackend _fallback = _MemorySessionBackend();
  bool _usingFallback = false;

  @override
  Future<void> clear() async {
    if (_usingFallback) {
      await _fallback.clear();
      return;
    }

    try {
      await _primary.clear();
      await _fallback.clear();
    } on MissingPluginException {
      _usingFallback = true;
      await _fallback.clear();
    } on PlatformException {
      _usingFallback = true;
      await _fallback.clear();
    }
  }

  @override
  Future<Map<String, Object?>> read() async {
    if (_usingFallback) {
      return _fallback.read();
    }

    try {
      return await _primary.read();
    } on MissingPluginException {
      _usingFallback = true;
      return _fallback.read();
    } on PlatformException {
      _usingFallback = true;
      return _fallback.read();
    }
  }

  @override
  Future<void> write(Map<String, Object> values) async {
    if (_usingFallback) {
      await _fallback.write(values);
      return;
    }

    try {
      await _primary.write(values);
      await _fallback.clear();
    } on MissingPluginException {
      _usingFallback = true;
      await _fallback.write(values);
    } on PlatformException {
      _usingFallback = true;
      await _fallback.write(values);
    }
  }
}

class _MemorySessionBackend implements _SessionBackend {
  Map<String, Object?> _session = const <String, Object?>{};

  @override
  Future<void> clear() async {
    _session = const <String, Object?>{};
  }

  @override
  Future<Map<String, Object?>> read() async {
    return Map<String, Object?>.from(_session);
  }

  @override
  Future<void> write(Map<String, Object> values) async {
    _session = Map<String, Object?>.from(values);
  }
}

class _PlatformSecureSessionBackend implements _SessionBackend {
  static const _channel = MethodChannel('auth/session');

  @override
  Future<void> clear() async {
    await _channel.invokeMethod<void>('clear');
  }

  @override
  Future<Map<String, Object?>> read() async {
    final values = await _channel.invokeMapMethod<String, dynamic>('readAll');
    if (values == null || values.isEmpty) {
      return const <String, Object?>{};
    }
    return Map<String, Object?>.from(values);
  }

  @override
  Future<void> write(Map<String, Object> values) async {
    await _channel.invokeMethod<void>('writeAll', values);
  }
}
