// 分享链路状态提供层。负责串起分享归因、本地持久化和邀约票据刷新，供登录前后流程复用。

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/share/data/repositories/share_referral_repository_impl.dart';
import 'package:millet_kyai_apps/features/share/data/sources/share_remote_source.dart';
import 'package:millet_kyai_apps/features/share/data/stores/share_referral_store.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/app_id_mapping_entity.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/guest_invite_context_entity.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/share_identity_entity.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/share_referral_state.dart';
import 'package:millet_kyai_apps/features/share/domain/repositories/share_referral_repository.dart';

final shareReferralStoreProvider = Provider<ShareReferralStore>((ref) {
  return ShareReferralStore();
});

final shareReferralRepositoryProvider = Provider<ShareReferralRepository>((
  ref,
) {
  initInjector();
  final dioClient = getIt<DioClient>();
  return ShareReferralRepositoryImpl(ShareRemoteSource(dioClient));
});

final shareReferralControllerProvider =
    AsyncNotifierProvider<ShareReferralController, ShareReferralState>(
      ShareReferralController.new,
    );

class ShareReferralController extends AsyncNotifier<ShareReferralState> {
  /// 分享链路控制器。
  /// 负责串起参数解析、本地状态持久化和邀约票据刷新，让登录前后的跳转意图保持连续。
  ShareReferralStore get _store => ref.read(shareReferralStoreProvider);
  ShareReferralRepository get _repository =>
      ref.read(shareReferralRepositoryProvider);

  @override
  FutureOr<ShareReferralState> build() async {
    return _store.loadState();
  }

  Future<ShareReferralState> handleIncomingShare({
    String? shareId,
    String? sharerId,
    String? visitorKey,
    String? redirect,
    bool isAuthenticated = false,
  }) async {
    final resolvedShareId = _resolveShareId(
      shareId,
      sharerId,
      fallbackSharerId: '',
    );
    final current = await _currentState();
    if (resolvedShareId.isEmpty) {
      return current;
    }

    if (isAuthenticated) {
      // 已登录时只需要记住来源 sharerId，避免再次走游客邀约票据刷新。
      return _persist(current.copyWith(sharerId: resolvedShareId));
    }

    final next = await _persist(
      current.copyWith(
        sharerId: resolvedShareId,
        guestAuthContext: _mergeGuestInviteContext(
          current.guestAuthContext,
          shareId: resolvedShareId,
          visitorKey: visitorKey,
          redirect: redirect,
        ),
      ),
    );
    final guestContext = next.guestAuthContext;
    if (guestContext != null && guestContext.hasReusableInviteTicket()) {
      // 游客态已有可复用票据时直接沿用，减少重复 touch 请求。
      return next;
    }

    return _refreshInviteTicket(
      current: next,
      shareId: resolvedShareId,
      visitorKey: guestContext?.visitorKey ?? _readString(visitorKey),
      redirect: guestContext?.redirect ?? redirect ?? '/',
    );
  }

  Future<String?> resolveInviteTicketForAuth({
    String? explicitInviteTicket,
    String? shareId,
    String? sharerId,
    String? visitorKey,
    String? redirect,
  }) async {
    final directInviteTicket = _readString(explicitInviteTicket);
    if (directInviteTicket.isNotEmpty) {
      return directInviteTicket;
    }

    final current = await _currentState();
    final resolvedShareId = _resolveShareId(
      shareId,
      sharerId,
      fallbackSharerId:
          current.guestAuthContext?.inviteShareId.isNotEmpty == true
          ? current.guestAuthContext!.inviteShareId
          : current.sharerId,
    );
    if (resolvedShareId.isEmpty) {
      return null;
    }

    final guestContext = current.guestAuthContext;
    if (guestContext != null &&
        guestContext.inviteShareId == resolvedShareId &&
        guestContext.hasReusableInviteTicket()) {
      // 登录前拿到的邀约票据优先复用，避免同一跳转链路重复失效。
      return guestContext.inviteTicket;
    }

    final prepared = await _persist(
      current.copyWith(
        sharerId: resolvedShareId,
        guestAuthContext: _mergeGuestInviteContext(
          current.guestAuthContext,
          shareId: resolvedShareId,
          visitorKey: visitorKey,
          redirect: redirect,
        ),
      ),
    );
    final refreshed = await _refreshInviteTicket(
      current: prepared,
      shareId: resolvedShareId,
      visitorKey:
          prepared.guestAuthContext?.visitorKey ?? _readString(visitorKey),
      redirect: prepared.guestAuthContext?.redirect ?? redirect ?? '/',
    );
    final refreshedGuestContext = refreshed.guestAuthContext;
    if (refreshedGuestContext == null ||
        refreshedGuestContext.inviteShareId != resolvedShareId ||
        refreshedGuestContext.inviteTicket.isEmpty) {
      return null;
    }

    return refreshedGuestContext.inviteTicket;
  }

  Future<ShareReferralState> initializeAfterAuth() async {
    final current = await _currentState();
    AppIdMappingEntity appIdMapping = current.appIdMapping;
    ShareIdentityEntity shareIdentity = current.shareIdentity;
    Object? firstError;

    try {
      appIdMapping = await _repository.getAppIdMapping();
    } on Object catch (error) {
      firstError ??= error;
    }

    try {
      shareIdentity = await _repository.getRefererId();
    } on Object catch (error) {
      firstError ??= error;
    }

    final next = await _persist(
      current.copyWith(
        appIdMapping: appIdMapping,
        shareIdentity: shareIdentity,
        clearGuestAuthContext: true,
      ),
    );

    if (firstError != null && appIdMapping.isEmpty && shareIdentity.isEmpty) {
      throw firstError;
    }
    return next;
  }

  Future<String> ensureRefererId() async {
    final current = await _currentState();
    if (current.refererId.isNotEmpty) {
      return current.refererId;
    }

    final shareIdentity = await _repository.getRefererId();
    final next = await _persist(current.copyWith(shareIdentity: shareIdentity));
    if (next.refererId.isEmpty) {
      throw StateError('Missing shareId from /api/v1/saas/mobile/shares/me');
    }
    return next.refererId;
  }

  Future<ShareReferralState> _refreshInviteTicket({
    required ShareReferralState current,
    required String shareId,
    required String visitorKey,
    required String redirect,
  }) async {
    final landingPage = _resolveLandingPage(
      redirect,
      current.guestAuthContext?.redirect,
    );
    try {
      final touchResult = await _repository.createShareTouch(
        shareId: shareId,
        landingPage: landingPage,
        visitorKey: visitorKey,
      );
      if (!touchResult.hasInviteTicket) {
        return _clearGuestInviteContext(current, shareId);
      }

      final nextGuestContext =
          _mergeGuestInviteContext(
            current.guestAuthContext,
            shareId: shareId,
            visitorKey: visitorKey,
            redirect: landingPage,
          ).copyWith(
            inviteTicket: touchResult.inviteTicket,
            inviteTicketExpireTime: touchResult.expireTime,
          );
      return _persist(
        current.copyWith(sharerId: shareId, guestAuthContext: nextGuestContext),
      );
    } on Object {
      return _clearGuestInviteContext(current, shareId);
    }
  }

  Future<ShareReferralState> _clearGuestInviteContext(
    ShareReferralState current,
    String sharerId,
  ) {
    return _persist(
      current.copyWith(sharerId: sharerId, clearGuestAuthContext: true),
    );
  }

  GuestInviteContextEntity _mergeGuestInviteContext(
    GuestInviteContextEntity? current, {
    required String shareId,
    String? visitorKey,
    String? redirect,
  }) {
    final reusesCurrentShare =
        current != null && current.inviteShareId == shareId;
    final currentContext = reusesCurrentShare ? current : null;
    final normalizedVisitorKey = _readString(visitorKey);
    final normalizedRedirect = _sanitizeRedirect(redirect);

    return GuestInviteContextEntity(
      inviteShareId: shareId,
      inviteTicket: currentContext?.inviteTicket ?? '',
      inviteTicketExpireTime: currentContext?.inviteTicketExpireTime ?? '',
      visitorKey: normalizedVisitorKey.isNotEmpty
          ? normalizedVisitorKey
          : currentContext?.visitorKey ?? '',
      redirect: normalizedRedirect.isNotEmpty
          ? normalizedRedirect
          : currentContext?.redirect ?? '',
      wechatCode: currentContext?.wechatCode ?? '',
    );
  }

  Future<ShareReferralState> _currentState() async {
    final currentState = state;
    if (currentState is AsyncData<ShareReferralState>) {
      return currentState.value;
    }

    try {
      return await future;
    } on Object {
      final fallback = await _store.loadState();
      state = AsyncData(fallback);
      return fallback;
    }
  }

  Future<ShareReferralState> _persist(ShareReferralState next) async {
    await _store.saveState(next);
    state = AsyncData(next);
    return next;
  }

  String _resolveShareId(
    String? shareId,
    String? sharerId, {
    required String fallbackSharerId,
  }) {
    final normalizedShareId = _readString(shareId);
    if (normalizedShareId.isNotEmpty) {
      return normalizedShareId;
    }

    final normalizedSharerId = _readString(sharerId);
    if (normalizedSharerId.isNotEmpty) {
      return normalizedSharerId;
    }

    return _readString(fallbackSharerId);
  }

  String _resolveLandingPage(String? redirect, String? fallbackRedirect) {
    final normalizedRedirect = _sanitizeRedirect(redirect);
    if (normalizedRedirect.isNotEmpty) {
      return normalizedRedirect;
    }

    final normalizedFallbackRedirect = _sanitizeRedirect(fallbackRedirect);
    if (normalizedFallbackRedirect.isNotEmpty) {
      return normalizedFallbackRedirect;
    }

    return '/';
  }

  String _sanitizeRedirect(String? value) {
    final normalized = _readString(value);
    if (normalized.isEmpty || !normalized.startsWith('/')) {
      return '';
    }
    return normalized;
  }
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
