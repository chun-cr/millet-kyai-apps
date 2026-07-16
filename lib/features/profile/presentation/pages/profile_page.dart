import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/layout/app_layout.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/locale_controller.dart';
import 'package:millet_kyai_apps/core/l10n/locale_sheet.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/utils/logger.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_session_state.dart';
import 'package:millet_kyai_apps/features/profile/presentation/widgets/profile_loading_skeletons.dart';

part 'profile_page_widgets.dart';

// ── 颜色常量（与全局 TCM 风格统一）────────────────────────────────
const _kPageBg = Color(0xFFF4F1EB); // 宣纸米色
const _kPrimary = Color(0xFF2D6A4F); // 墨绿
const _kGold = Color(0xFFC9A84C); // 金色
const _kTextPrimary = Color(0xFF1E1810);
const _kTextSecondary = Color(0xFF3A3028);
const _kTextHint = Color(0xFFA09080);
const _kDivider = Color(0xFFF0EDE5);
const _kCardBg = Color(0xFFFFFFFF);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileMeProvider);
    final profile = profileAsync.asData?.value;
    final isProfileLoading = profileAsync.isLoading && !profileAsync.hasValue;

    if (isProfileLoading) {
      return const ProfilePageLoadingSkeleton();
    }

    return Scaffold(
      backgroundColor: _kPageBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _kPageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              context.l10n.profileTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _kPrimary,
                  size: 20,
                ),
              ),
            ],
          ),

          // 内容区
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayoutMetrics.of(context).contentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppLayoutMetrics.of(context).pageHorizontalPadding,
                    0,
                    AppLayoutMetrics.of(context).pageHorizontalPadding,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 悬浮资料头
                      _buildHeroCard(
                        context,
                        profile,
                        isLoading: isProfileLoading,
                      ),
                      const SizedBox(height: 20),

                      // 功能菜单组
                      _buildMenuGroup(context, ref),
                      const SizedBox(height: 20),

                      // 退出登录
                      _buildLogoutButton(context, ref),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 悬浮资料头
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeroCard(
    BuildContext context,
    ProfileMeEntity? profile, {
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.75, -0.65),
          radius: 1.2,
          colors: [
            _kPrimary.withValues(alpha: 0.13),
            const Color(0xFFB6DFCA).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.36, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ProfileHeroBgPainter())),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(context, profile),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserInfo(context, profile, isLoading: isLoading),
              ),
              _buildEditButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ProfileMeEntity? profile) {
    final avatarUrl = _trimmedOrNull(profile?.avatarUrl);
    final displayName = _displayName(context, profile, isLoading: false);
    final initial = _avatarInitial(displayName);

    Widget fallbackAvatar() {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3D8A68), Color(0xFF2D6A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: initial.isEmpty
              ? const Icon(Icons.person_rounded, color: Colors.white, size: 26)
              : Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3D8A68), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox.expand(
              child: avatarUrl == null
                  ? fallbackAvatar()
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return fallbackAvatar();
                      },
                    ),
            ),
          ),
        ),
        // 体质徽章
        Positioned(
          bottom: -2,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kGold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              context.l10n.profileBadgeBalanced,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    ProfileMeEntity? profile, {
    required bool isLoading,
  }) {
    final displayName = _displayName(context, profile, isLoading: isLoading);
    final secondaryLine = _secondaryLine(
      context,
      profile,
      isLoading: isLoading,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        if (secondaryLine.isNotEmpty)
          Text(
            _sanitizeSecondaryLine(secondaryLine),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: _kTextSecondary.withValues(alpha: 0.58),
            ),
          ),
        SizedBox(height: secondaryLine.isEmpty ? 0 : 8),
        // 体质 pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  context.l10n.profileBalancedType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _displayName(
    BuildContext context,
    ProfileMeEntity? profile, {
    required bool isLoading,
  }) {
    final nickname = _trimmedOrNull(profile?.nickname);
    final realName = _trimmedOrNull(profile?.realName);
    final userNo = _trimmedOrNull(profile?.userNo);
    final displayName = nickname ?? realName ?? userNo;
    if (displayName != null) {
      return displayName;
    }
    return isLoading ? context.l10n.commonLoading : '';
  }

  String _secondaryLine(
    BuildContext context,
    ProfileMeEntity? profile, {
    required bool isLoading,
  }) {
    if (profile == null) {
      return isLoading ? context.l10n.commonLoading : '';
    }

    final displayName = _trimmedOrNull(
      _displayName(context, profile, isLoading: false),
    );
    final parts = <String>[];
    final realName = _trimmedOrNull(profile.realName);
    final maskedPhone = _maskedPhone(profile);
    final userNo = _trimmedOrNull(profile.userNo);

    if (realName != null && realName != displayName) {
      parts.add(realName);
    }
    if (maskedPhone != null) {
      parts.add(maskedPhone);
    } else if (userNo != null && userNo != displayName) {
      parts.add(userNo);
    }

    if (parts.isEmpty) {
      return isLoading ? context.l10n.commonLoading : '';
    }
    return parts.join(' · ');
  }

  String? _maskedPhone(ProfileMeEntity profile) {
    final phone = _trimmedOrNull(profile.phone);
    if (phone == null) {
      return null;
    }

    final countryCode = _trimmedOrNull(profile.countryCode);
    final maskedNumber = phone.length >= 7
        ? '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}'
        : phone;
    return [countryCode, maskedNumber].whereType<String>().join(' ');
  }

  String _avatarInitial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final runes = trimmed.runes;
    if (runes.isEmpty) {
      return '';
    }
    return String.fromCharCode(runes.first);
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _sanitizeSecondaryLine(String value) {
    return value.replaceAll('\u8def', '/');
  }

  Widget _buildEditButton() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.edit_outlined, size: 16, color: _kPrimary),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 菜单组
  // ══════════════════════════════════════════════════════════════
  Widget _buildMenuGroup(BuildContext context, WidgetRef ref) {
    final selectedLocale = ref.watch(localeControllerProvider).asData?.value;
    final items = [
      _MenuData(
        icon: Icons.people_outline,
        label: context.l10n.profileMenuAccount,
        sub: context.l10n.profileMenuAccountSub,
        color: Color(0xFF2D6A4F),
      ),
      _MenuData(
        icon: Icons.location_on_outlined,
        label: context.l10n.profileMenuShippingAddress,
        sub: context.l10n.profileMenuShippingAddressSub,
        color: Color(0xFF0D7A5A),
        onTap: () => context.push(AppRoutes.profileAddresses),
      ),
      _MenuData(
        icon: Icons.workspace_premium_outlined,
        label: context.l10n.profileMenuPoints,
        sub: context.l10n.profileMenuPointsSub,
        color: Color(0xFFC9A84C),
        onTap: () => context.push(AppRoutes.profilePoints),
      ),
      _MenuData(
        icon: Icons.settings_outlined,
        label: context.l10n.profileMenuSettings,
        sub: context.l10n.profileMenuSettingsSub,
        color: Color(0xFF8A6F3C),
        onTap: () => context.push(AppRoutes.settings),
      ),
      _MenuData(
        icon: Icons.calendar_month_outlined,
        label: context.l10n.profileMenuReminder,
        sub: context.l10n.profileMenuReminderSub,
        color: Color(0xFF6B5B95),
      ),
      _MenuData(
        icon: Icons.chat_bubble_outline,
        label: context.l10n.profileMenuAdvisor,
        sub: context.l10n.profileMenuAdvisorSub,
        color: Color(0xFF0D7A5A),
      ),
      _MenuData(
        icon: Icons.language_rounded,
        label: context.l10n.profileMenuLanguage,
        sub: context.l10n.profileMenuLanguageSub,
        color: Color(0xFF4A7FA8),
        trailingText: appLocaleLabel(context, selectedLocale),
        onTap: () => showAppLocaleSheet(
          context,
          ref,
          selectedLocale: selectedLocale,
          backgroundColor: _kCardBg,
          primaryColor: _kPrimary,
          dividerColor: _kDivider,
          textPrimaryColor: _kTextPrimary,
          textHintColor: _kTextHint,
        ),
      ),
      _MenuData(
        icon: Icons.auto_awesome_outlined,
        label: context.l10n.profileMenuAbout,
        sub: context.l10n.profileMenuAboutSub,
        color: Color(0xFFC9A84C),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSectionTitle(title: context.l10n.profileSectionServices),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  _MenuRow(item: item),
                  if (i < items.length - 1)
                    Divider(
                      height: 0.5,
                      indent: 44,
                      endIndent: 16,
                      color: _kDivider,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 退出登录按钮
  // ══════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final container = ProviderScope.containerOf(context, listen: false);
          final sessionStore = getIt<AuthSessionStore>();
          final refreshToken = await sessionStore.refreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              await ref
                  .read(authRepositoryProvider)
                  .logout(refreshToken: refreshToken);
            } on Object catch (error) {
              AppLogger.log('Logout request failed: $error');
            }
          }
          await sessionStore.clear();
          await clearProfileScopedPersistence();
          if (!context.mounted) {
            return;
          }
          setPreviewAuthenticated(false);
          context.go(AppRoutes.login);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            invalidateProfileScopedProvidersInContainer(container);
          });
        },
        icon: Icon(
          Icons.logout_rounded,
          color: _kTextHint.withValues(alpha: 0.82),
          size: 16,
        ),
        label: Text(
          context.l10n.profileLogout,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextHint.withValues(alpha: 0.82),
            letterSpacing: 0.4,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
            side: BorderSide(color: _kDivider, width: 1),
          ),
        ),
      ),
    );
  }
}
