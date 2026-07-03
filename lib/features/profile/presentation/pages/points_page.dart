// 个人中心模块页面：`PointsPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_entry_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_overview_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_task_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_points_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/widgets/profile_loading_skeletons.dart';

const _kPointsPageBg = Color(0xFFF4F1EB);
const _kPointsCardBg = Colors.white;
const _kPointsPrimary = Color(0xFF2D6A4F);
const _kPointsAccent = Color(0xFFC9A84C);
const _kPointsTextPrimary = Color(0xFF1E1810);
const _kPointsTextSecondary = Color(0xFF7A6F63);
const _kPointsDanger = Color(0xFFB04C37);
const _kSupportedTaskRoutes = <String>{
  AppRoutes.home,
  AppRoutes.scan,
  AppRoutes.scanFace,
  AppRoutes.scanTongue,
  AppRoutes.scanPalm,
  AppRoutes.report,
  AppRoutes.reportAnalysis,
  AppRoutes.history,
  AppRoutes.profile,
  AppRoutes.profileAddresses,
  AppRoutes.profilePoints,
  AppRoutes.settings,
  AppRoutes.accountSecurity,
  AppRoutes.setLoginPassword,
};

class PointsPage extends ConsumerWidget {
  const PointsPage({super.key});

  void _showToast(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.error,
  }) {
    showAppToast(context, message, kind: kind);
  }

  Future<void> _refreshPoints(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profilePointsProvider.notifier).refresh();
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showToast(context, context.l10n.profilePointsLoadFailed);
    }
  }

  Future<void> _claimPoints(BuildContext context, WidgetRef ref) async {
    final previousBalance =
        ref.read(profilePointsProvider).asData?.value.balance ?? 0;
    try {
      final overview = await ref
          .read(profilePointsProvider.notifier)
          .claimDailyCheckIn();
      if (!context.mounted) {
        return;
      }
      final reward = (overview.balance - previousBalance).toInt();
      if (reward > 0) {
        _showToast(
          context,
          context.l10n.profilePointsCheckInSuccess(reward),
          kind: AppToastKind.success,
        );
      }
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showToast(context, context.l10n.profilePointsCheckInFailed);
    }
  }

  Future<void> _handleTaskAction(
    BuildContext context,
    WidgetRef ref,
    ProfilePointsOverviewEntity overview,
    ProfilePointsTaskEntity task,
  ) async {
    if (_isCheckInTask(task)) {
      if (!overview.canCheckInToday || overview.isCheckingIn) {
        return;
      }
      await _claimPoints(context, ref);
      return;
    }

    final route = _resolveTaskRoute(task.path);
    if (route != null) {
      try {
        await context.push(route);
        return;
      } on Object {
        if (!context.mounted) {
          return;
        }
      }
    }

    if (!context.mounted) {
      return;
    }
    _showToast(
      context,
      context.l10n.profilePointsTaskActionUnsupported(
        _taskActionLabel(context, task),
      ),
      kind: AppToastKind.info,
    );
  }

  Future<void> _loadMoreLogs(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profilePointsProvider.notifier).loadMoreLogs();
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showToast(context, context.l10n.profilePointsLoadMoreFailed);
    }
  }

  bool _hasTaskAction(ProfilePointsTaskEntity task) {
    return _isCheckInTask(task) ||
        task.btnName.trim().isNotEmpty ||
        task.path.trim().isNotEmpty;
  }

  bool _isTaskActionEnabled(
    ProfilePointsOverviewEntity overview,
    ProfilePointsTaskEntity task,
  ) {
    if (_isCheckInTask(task)) {
      return overview.canCheckInToday && !overview.isCheckingIn;
    }
    return _hasTaskAction(task);
  }

  String _taskActionLabel(BuildContext context, ProfilePointsTaskEntity task) {
    final buttonName = task.btnName.trim();
    if (buttonName.isNotEmpty) {
      return buttonName;
    }
    if (_isCheckInTask(task)) {
      return context.l10n.profilePointsCheckIn;
    }
    return context.l10n.commonViewDetails;
  }

  bool _isCheckInTask(ProfilePointsTaskEntity task) {
    final lowered = '${task.code} ${task.name} ${task.btnName} ${task.path}'
        .toLowerCase();
    return lowered.contains('signin') ||
        lowered.contains('sign-in') ||
        lowered.contains('checkin') ||
        lowered.contains('check-in') ||
        task.name.contains('签到') ||
        task.btnName.contains('签到') ||
        task.path.contains('签到');
  }

  String? _resolveTaskRoute(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return null;
    }

    final routedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final routePath = uri?.path.isNotEmpty == true
        ? (uri!.path.startsWith('/') ? uri.path : '/${uri.path}')
        : routedPath;
    return _kSupportedTaskRoutes.contains(routePath) ? routedPath : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(profilePointsProvider);

    if (overviewAsync.isLoading && !overviewAsync.hasValue) {
      return const PointsPageLoadingSkeleton();
    }

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
            color: _kPointsTextPrimary,
          ),
        ),
      ),
      body: overviewAsync.when(
        data: (overview) {
          final allTasks = [
            if (overview.registerTask != null) overview.registerTask!,
            ...overview.tasks,
          ];

          return RefreshIndicator(
            onRefresh: () => _refreshPoints(context, ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _PointsHeroCard(
                  overview: overview,
                  onCheckIn: overview.canCheckInToday && !overview.isCheckingIn
                      ? () => _claimPoints(context, ref)
                      : null,
                ),
                const SizedBox(height: 16),
                _PointsStatsGrid(overview: overview),
                const SizedBox(height: 18),
                _SectionTitle(title: context.l10n.profilePointsTasks),
                const SizedBox(height: 10),
                if (allTasks.isEmpty)
                  const _PointsEmptyCard(kind: _PointsEmptyKind.tasks)
                else
                  ...allTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PointsTaskCard(
                        task: task,
                        isRegisterTask: identical(task, overview.registerTask),
                        actionLabel: _taskActionLabel(context, task),
                        isActionEnabled: _isTaskActionEnabled(overview, task),
                        isActionLoading:
                            overview.isCheckingIn && _isCheckInTask(task),
                        onAction: _hasTaskAction(task)
                            ? () => _handleTaskAction(
                                context,
                                ref,
                                overview,
                                task,
                              )
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _SectionTitle(title: context.l10n.profilePointsHistory),
                const SizedBox(height: 10),
                if (overview.entries.isEmpty)
                  const _PointsEmptyCard(kind: _PointsEmptyKind.history)
                else
                  ...overview.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PointsEntryCard(entry: entry),
                    ),
                  ),
                if (overview.canLoadMore) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: OutlinedButton(
                      onPressed: overview.isLoadingMore
                          ? null
                          : () => _loadMoreLogs(context, ref),
                      child: overview.isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.profilePointsLoadMore),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.profilePointsLoadFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _kPointsTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _refreshPoints(context, ref),
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PointsHeroCard extends StatelessWidget {
  const _PointsHeroCard({required this.overview, required this.onCheckIn});

  final ProfilePointsOverviewEntity overview;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPointsPrimary,
            _kPointsPrimary.withValues(alpha: 0.88),
            _kPointsAccent.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _kPointsPrimary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.profilePointsBalance,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${overview.balance}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: context.l10n.unitPoints,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.profilePointsCheckInHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCheckIn,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kPointsPrimary,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.72),
              disabledForegroundColor: _kPointsPrimary.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: overview.isCheckingIn
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    overview.canCheckInToday
                        ? Icons.add_task_rounded
                        : Icons.verified_rounded,
                  ),
            label: Text(
              overview.isCheckingIn
                  ? context.l10n.commonLoading
                  : overview.canCheckInToday
                  ? context.l10n.profilePointsCheckIn
                  : context.l10n.profilePointsCheckInDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsStatsGrid extends StatelessWidget {
  const _PointsStatsGrid({required this.overview});

  final ProfilePointsOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PointsMetricCard(
            label: context.l10n.profilePointsTodayGain,
            value: '${overview.todayGainAmount}${context.l10n.unitPoints}',
            color: _kPointsPrimary,
            icon: Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PointsMetricCard(
            label: context.l10n.profilePointsWeekGain,
            value: '${overview.weekGainAmount}${context.l10n.unitPoints}',
            color: _kPointsAccent,
            icon: Icons.date_range_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PointsMetricCard(
            label: context.l10n.profilePointsHisTotal,
            value: '${overview.hisTotalAmount}${context.l10n.unitPoints}',
            color: const Color(0xFF8A6F3C),
            icon: Icons.workspace_premium_outlined,
          ),
        ),
      ],
    );
  }
}

class _PointsMetricCard extends StatelessWidget {
  const _PointsMetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPointsCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kPointsTextSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPointsTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsTaskCard extends StatelessWidget {
  const _PointsTaskCard({
    required this.task,
    required this.isRegisterTask,
    required this.actionLabel,
    required this.isActionEnabled,
    required this.isActionLoading,
    required this.onAction,
  });

  final ProfilePointsTaskEntity task;
  final bool isRegisterTask;
  final String actionLabel;
  final bool isActionEnabled;
  final bool isActionLoading;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPointsCardBg,
        borderRadius: BorderRadius.circular(20),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kPointsTextPrimary,
                          ),
                        ),
                        if (isRegisterTask)
                          _Badge(
                            label: context.l10n.profilePointsRegisterTask,
                            backgroundColor: _kPointsAccent.withValues(
                              alpha: 0.12,
                            ),
                            textColor: const Color(0xFF8A6F3C),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: _kPointsTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Badge(
                label: '+${task.amount}${context.l10n.unitPoints}',
                backgroundColor: _kPointsPrimary.withValues(alpha: 0.10),
                textColor: _kPointsPrimary,
              ),
            ],
          ),
          if (task.finishTimesTip.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              task.finishTimesTip,
              style: TextStyle(
                fontSize: 11,
                color: _kPointsTextSecondary.withValues(alpha: 0.92),
              ),
            ),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: isActionEnabled ? onAction : null,
                style: FilledButton.styleFrom(
                  foregroundColor: _kPointsPrimary,
                  backgroundColor: const Color(0xFFEDE7D9),
                  disabledForegroundColor: _kPointsTextSecondary.withValues(
                    alpha: 0.74,
                  ),
                  disabledBackgroundColor: const Color(
                    0xFFEDE7D9,
                  ).withValues(alpha: 0.72),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isActionLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointsEntryCard extends StatelessWidget {
  const _PointsEntryCard({required this.entry});

  final ProfilePointsEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat('MM.dd HH:mm', locale);
    final amountColor = entry.isIncome ? _kPointsPrimary : _kPointsDanger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPointsCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              entry.isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kPointsTextPrimary,
                  ),
                ),
                if (entry.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: _kPointsTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  formatter.format(entry.createTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: _kPointsTextSecondary.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.incomeAmount >= 0 ? '+' : ''}${entry.incomeAmount}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPointsTextPrimary,
      ),
    );
  }
}

enum _PointsEmptyKind { tasks, history }

class _PointsEmptyCard extends StatelessWidget {
  const _PointsEmptyCard({required this.kind});

  final _PointsEmptyKind kind;

  @override
  Widget build(BuildContext context) {
    final message = kind == _PointsEmptyKind.tasks
        ? context.l10n.profilePointsTaskEmpty
        : context.l10n.profilePointsEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPointsCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: _kPointsTextSecondary),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
