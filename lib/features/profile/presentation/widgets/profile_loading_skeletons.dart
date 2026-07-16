// 个人中心模块共享组件：`ProfileLoadingSkeletons`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/widgets/app_skeleton.dart';

const _kProfilePageBg = Color(0xFFF4F1EB);
const _kProfileCardBg = Colors.white;
const _kProfilePrimary = Color(0xFF2D6A4F);
const _kProfileTextPrimary = Color(0xFF1E1810);
const _kProfileDivider = Color(0xFFF0EDE5);

const _kPointsPageBg = Color(0xFFF4F1EB);
const _kAddressPageBg = Color(0xFFF9FCF7);
const _kAddressTextPrimary = Color(0xFF1E1810);
const _kAddressNavBorder = Color(0xFFE6ECE3);

class ProfilePageLoadingSkeleton extends StatelessWidget {
  const ProfilePageLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kProfilePageBg,
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _kProfilePageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              context.l10n.profileTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kProfileTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: _kProfilePrimary,
                  size: 20,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: AppShimmer(
              child: KeyedSubtree(
                key: const ValueKey('profile_loading'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _ProfileHeroSkeleton(),
                      SizedBox(height: 20),
                      _ProfileSectionSkeleton(titleWidth: 126, cardHeight: 186),
                      SizedBox(height: 20),
                      _ProfileCabinSkeleton(),
                      SizedBox(height: 20),
                      _ProfileMenuSkeleton(),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: SkeletonLine(width: 108, height: 18),
                      ),
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
}

class PointsPageLoadingSkeleton extends StatelessWidget {
  const PointsPageLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPointsPageBg,
      appBar: AppBar(
        backgroundColor: _kPointsPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.profilePointsTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kProfileTextPrimary,
          ),
        ),
      ),
      body: AppShimmer(
        child: KeyedSubtree(
          key: const ValueKey('points_loading'),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: const [
              SkeletonBlock(
                height: 176,
                borderRadius: BorderRadius.all(Radius.circular(26)),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SkeletonBlock(
                      height: 128,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SkeletonBlock(
                      height: 128,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SkeletonBlock(
                      height: 128,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              SkeletonLine(width: 118, height: 16),
              SizedBox(height: 10),
              _ProfileListCardSkeleton(),
              SizedBox(height: 12),
              _ProfileListCardSkeleton(),
              SizedBox(height: 12),
              _ProfileListCardSkeleton(),
              SizedBox(height: 18),
              SkeletonLine(width: 132, height: 16),
              SizedBox(height: 10),
              _ProfileListCardSkeleton(compact: true),
              SizedBox(height: 12),
              _ProfileListCardSkeleton(compact: true),
              SizedBox(height: 12),
              _ProfileListCardSkeleton(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class ShippingAddressLoadingSkeleton extends StatelessWidget {
  const ShippingAddressLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAddressPageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: null,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 28,
            color: Color(0xFF6B6E67),
          ),
        ),
        title: Text(
          context.l10n.profileAddressTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kAddressTextPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kAddressNavBorder),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFBFDF9), Color(0xFFF7FBF5), Color(0xFFF9FCF8)],
          ),
        ),
        child: AppShimmer(
          child: KeyedSubtree(
            key: const ValueKey('shipping_address_loading'),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const _AddressCardSkeleton(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroSkeleton extends StatelessWidget {
  const _ProfileHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.75, -0.65),
          radius: 1.2,
          colors: [
            _kProfilePrimary.withValues(alpha: 0.13),
            const Color(0xFFB6DFCA).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.36, 1.0],
        ),
      ),
      child: const Row(
        children: [
          SkeletonCircle(size: 68),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 140, height: 22),
                SizedBox(height: 10),
                SkeletonLine(width: 184),
                SizedBox(height: 12),
                SkeletonLine(width: 92, height: 22),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonCircle(size: 34),
        ],
      ),
    );
  }
}

class _ProfileSectionSkeleton extends StatelessWidget {
  const _ProfileSectionSkeleton({
    required this.titleWidth,
    required this.cardHeight,
  });

  final double titleWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: titleWidth, height: 16),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kProfileCardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _kProfilePrimary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SkeletonBlock(
            height: cardHeight,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

class _ProfileCabinSkeleton extends StatelessWidget {
  const _ProfileCabinSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 102, height: 16),
        const SizedBox(height: 10),
        SizedBox(
          height: 138,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, _) => SkeletonBlock(
              width: 210,
              height: 138,
              borderRadius: BorderRadius.circular(20),
            ),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: 3,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuSkeleton extends StatelessWidget {
  const _ProfileMenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 116, height: 16),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kProfileCardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kProfilePrimary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              6,
              (index) => Column(
                children: [
                  const _ProfileMenuRowSkeleton(),
                  if (index < 5)
                    const Divider(
                      height: 0.5,
                      indent: 44,
                      endIndent: 16,
                      color: _kProfileDivider,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuRowSkeleton extends StatelessWidget {
  const _ProfileMenuRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SkeletonCircle(size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 96),
                SizedBox(height: 6),
                SkeletonLine(width: 164, height: 10),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonLine(width: 34, height: 10),
        ],
      ),
    );
  }
}

class _ProfileListCardSkeleton extends StatelessWidget {
  const _ProfileListCardSkeleton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kProfileCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 138),
          const SizedBox(height: 8),
          SkeletonLine(width: compact ? 164 : double.infinity, height: 10),
          const SizedBox(height: 8),
          if (!compact) ...[
            const SkeletonLine(width: double.infinity, height: 10),
            const SizedBox(height: 12),
            const SkeletonLine(width: 98, height: 34),
          ] else ...[
            const SkeletonLine(width: 112, height: 10),
          ],
        ],
      ),
    );
  }
}

class _AddressCardSkeleton extends StatelessWidget {
  const _AddressCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonLine(width: 120, height: 16)),
              SizedBox(width: 12),
              SkeletonLine(width: 68, height: 22),
            ],
          ),
          SizedBox(height: 14),
          SkeletonLine(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonLine(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonLine(width: 168, height: 12),
          SizedBox(height: 18),
          Row(
            children: [
              SkeletonLine(width: 62, height: 12),
              Spacer(),
              SkeletonLine(width: 56, height: 12),
              SizedBox(width: 16),
              SkeletonLine(width: 56, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
