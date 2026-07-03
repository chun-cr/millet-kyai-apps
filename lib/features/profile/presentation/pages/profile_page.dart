import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
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

// ── 颜色常量（与全局 TCM 风格统一）────────────────────────────────
const _kPageBg = Color(0xFFF4F1EB); // 宣纸米色
const _kPrimary = Color(0xFF2D6A4F); // 墨绿
const _kPrimaryMid = Color(0xFF0D7A5A);
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 悬浮资料头
                  _buildHeroCard(context, profile, isLoading: isProfileLoading),
                  const SizedBox(height: 20),

                  // 健康总览指标
                  _buildHealthMetrics(context),
                  const SizedBox(height: 20),

                  // 健康基底
                  _buildInsightRow(context),
                  const SizedBox(height: 20),

                  // 我的调理舱
                  _buildPrescriptionCabin(context),
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

  Widget _buildHealthMetrics(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildStatCell(
              '12',
              context.l10n.unitTimes,
              context.l10n.profileMetricConsultCount,
            ),
            _buildStatDivider(),
            _buildStatCell(
              '86',
              context.l10n.unitPoints,
              context.l10n.profileMetricHealthScore,
            ),
            _buildStatDivider(),
            _buildStatCell(
              '3',
              context.l10n.unitStage,
              context.l10n.profileMetricConstitutionStages,
            ),
          ],
        ),
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

  Widget _buildStatCell(String value, String unit, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextHint.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _kTextHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: _kDivider);
  }

  // ══════════════════════════════════════════════════════════════
  //  健康基底
  // ══════════════════════════════════════════════════════════════
  Widget _buildInsightRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSectionTitle(title: context.l10n.profileSectionFoundation),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatLine(
                          icon: Icons.height_outlined,
                          iconColor: _kPrimary,
                          label: context.l10n.profileHeight,
                          value: '178',
                          unit: 'cm',
                        ),
                        const SizedBox(height: 10),
                        _StatLine(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: _kPrimaryMid,
                          label: context.l10n.profileWeight,
                          value: '72',
                          unit: 'kg',
                        ),
                        const SizedBox(height: 12),
                        _BmiBar(bmi: 22.7),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 108,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: _kDivider,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BaselineSummary(
                          label: context.l10n.profileInnateBase,
                          value: context.l10n.profileInnateBaseValue,
                          note: context.l10n.profileInnateBaseNote,
                          color: _kGold,
                        ),
                        const SizedBox(height: 12),
                        _BaselineSummary(
                          label: context.l10n.profileCurrentBias,
                          value: context.l10n.profileCurrentBiasValue,
                          note: context.l10n.profileCurrentBiasNote,
                          color: _kPrimaryMid,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.profileHealthScore30Days,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kTextHint,
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 40, child: _HealthSparkline()),
                    SizedBox(height: 6),
                    Text(
                      context.l10n.profileHealthScoreTrendNote,
                      style: TextStyle(fontSize: 11, color: _kTextHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionCabin(BuildContext context) {
    final items = [
      _CabinData(
        context.l10n.profileCabinAcupoints,
        context.l10n.profileCabinAcupointsValue,
        Icons.hub_outlined,
        _kPrimary,
      ),
      _CabinData(
        context.l10n.profileCabinDiet,
        context.l10n.profileCabinDietValue,
        Icons.restaurant_menu_outlined,
        _kGold,
      ),
      _CabinData(
        context.l10n.profileCabinFollowup,
        context.l10n.profileCabinFollowupValue,
        Icons.event_note_outlined,
        _kPrimaryMid,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSectionTitle(title: context.l10n.profileSectionCabin),
        const SizedBox(height: 10),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, index) => _CabinCard(item: items[index]),
          ),
        ),
      ],
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

// ══════════════════════════════════════════════════════════════════
// 洞察卡容器
// ══════════════════════════════════════════════════════════════════
class _ProfileSectionTitle extends StatelessWidget {
  final String title;
  const _ProfileSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _BaselineSummary extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final Color color;

  const _BaselineSummary({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _kTextHint.withValues(alpha: 0.86),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          note,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: _kTextSecondary.withValues(alpha: 0.58),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── 数据行（图标 + 标签 + 数值）──────────────────────────────────
class _StatLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _StatLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kTextHint),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  height: 1,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 10,
                  color: _kTextHint.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── BMI 状态条 ────────────────────────────────────────────────────
class _BmiBar extends StatelessWidget {
  final double bmi;
  const _BmiBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // 18.5~24 正常区间，映射到 0~1
    final norm = ((bmi - 15) / 25).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BMI ${bmi.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                context.l10n.profileBmiNormal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            // 轨道
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // 进度
            FractionallySizedBox(
              widthFactor: norm,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 体质点状时间轴
class _HealthSparkline extends StatelessWidget {
  const _HealthSparkline();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HealthSparklinePainter(),
      child: const SizedBox.expand(),
    );
  }
}

// 菜单行
class _MenuData {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String? trailingText;
  final VoidCallback? onTap;

  const _MenuData({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    this.trailingText,
    this.onTap,
  });
}

class _MenuRow extends StatefulWidget {
  final _MenuData item;
  const _MenuRow({required this.item});

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed
            ? widget.item.color.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(
              widget.item.icon,
              size: 18,
              color: widget.item.color.withValues(alpha: 0.86),
            ),
            const SizedBox(width: 12),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextHint.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.item.trailingText != null) ...[
              Text(
                widget.item.trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextHint.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right,
              size: 18,
              color: _kPrimary.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Hero 背景装饰 Painter
// ══════════════════════════════════════════════════════════════════
class _ProfileHeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.18),
      86,
      Paint()
        ..color = const Color(0xFFB6DFCA).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.42),
      62,
      Paint()
        ..color = const Color(0xFFC9A84C).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CabinData {
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _CabinData(this.title, this.detail, this.icon, this.color);
}

class _CabinCard extends StatelessWidget {
  final _CabinData item;
  const _CabinCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: item.color.withValues(alpha: 0.82)),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              item.detail,
              style: TextStyle(
                fontSize: 12,
                height: 1.55,
                color: _kTextSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${context.l10n.commonViewDetails} >',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: item.color.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSparklinePainter extends CustomPainter {
  static const _scores = [
    68.0,
    70.0,
    73.0,
    71.0,
    75.0,
    77.0,
    76.0,
    82.0,
    86.0,
    84.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final min = _scores.reduce((a, b) => a < b ? a : b);
    final max = _scores.reduce((a, b) => a > b ? a : b);
    final span = (max - min).clamp(1.0, double.infinity);

    final grid = Paint()
      ..color = _kDivider
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      grid,
    );

    final path = Path();
    for (var i = 0; i < _scores.length; i++) {
      final dx = size.width * i / (_scores.length - 1);
      final dy =
          size.height - ((_scores[i] - min) / span) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastDx = size.width;
    final lastDy =
        size.height - ((_scores.last - min) / span) * (size.height - 6) - 3;
    canvas.drawCircle(Offset(lastDx, lastDy), 3.2, Paint()..color = _kPrimary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
