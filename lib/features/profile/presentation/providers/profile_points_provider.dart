// 个人中心模块状态提供层：`ProfilePointsProvider`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_account_simple_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_account_stat_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_log_page_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_overview_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_tasks_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';

const _kDefaultPointsLogPageSize = 20;

final profilePointsBalanceProvider =
    FutureProvider<ProfilePointsAccountSimpleEntity>((ref) {
      return ref
          .watch(profileRepositoryProvider)
          .fetchPointsAccountSimpleInfo();
    });

final profilePointsProvider =
    AsyncNotifierProvider<ProfilePointsController, ProfilePointsOverviewEntity>(
      ProfilePointsController.new,
    );

class ProfilePointsController
    extends AsyncNotifier<ProfilePointsOverviewEntity> {
  Future<ProfilePointsOverviewEntity>? _checkInFuture;

  @override
  FutureOr<ProfilePointsOverviewEntity> build() {
    return _loadOverview();
  }

  Future<ProfilePointsOverviewEntity> refresh() async {
    final overview = await _loadOverview();
    state = AsyncData(overview);
    ref.invalidate(profilePointsBalanceProvider);
    return overview;
  }

  Future<ProfilePointsOverviewEntity> claimDailyCheckIn() {
    final inFlight = _checkInFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _claimDailyCheckInInternal();
    _checkInFuture = future;
    future.whenComplete(() {
      if (identical(_checkInFuture, future)) {
        _checkInFuture = null;
      }
    });
    return future;
  }

  Future<ProfilePointsOverviewEntity> _claimDailyCheckInInternal() async {
    final repository = ref.read(profileRepositoryProvider);
    final current = state.asData?.value;
    if (current != null && !current.canCheckInToday) {
      return current;
    }
    if (current != null) {
      state = AsyncData(current.copyWith(isCheckingIn: true));
    }

    try {
      final updatedStat = await repository.signInPoints();
      final results = await Future.wait<Object>([
        repository.fetchPointsTasks(),
        repository.fetchPointsLogs(
          pageNo: 1,
          pageSize: current?.pageSize ?? _kDefaultPointsLogPageSize,
        ),
      ]);

      final tasks = results[0] as ProfilePointsTasksEntity;
      final logs = results[1] as ProfilePointsLogPageEntity;

      final next = current == null
          ? const _NoPointsOverviewState().merge(
              stat: updatedStat,
              tasks: tasks,
              logs: logs,
            )
          : current.merge(stat: updatedStat, tasks: tasks, logs: logs);

      state = AsyncData(next);
      ref.invalidate(profilePointsBalanceProvider);
      return next;
    } on Object {
      if (current != null) {
        state = AsyncData(current.copyWith(isCheckingIn: false));
      }
      rethrow;
    }
  }

  Future<void> loadMoreLogs() async {
    final current = state.asData?.value;
    if (current == null || !current.canLoadMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = await ref
          .read(profileRepositoryProvider)
          .fetchPointsLogs(
            pageNo: current.pageNo + 1,
            pageSize: current.pageSize,
          );
      state = AsyncData(
        current.copyWith(
          entries: [...current.entries, ...nextPage.records],
          total: nextPage.total,
          pageNo: nextPage.pageNo,
          pageSize: nextPage.pageSize,
          isLoadingMore: false,
        ),
      );
    } on Object {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  Future<ProfilePointsOverviewEntity> _loadOverview() async {
    final repository = ref.read(profileRepositoryProvider);
    final results = await Future.wait<Object>([
      repository.fetchPointsAccountStat(),
      repository.fetchPointsTasks(),
      repository.fetchPointsLogs(
        pageNo: 1,
        pageSize: _kDefaultPointsLogPageSize,
      ),
    ]);

    final stat = results[0] as ProfilePointsAccountStatEntity;
    final tasks = results[1] as ProfilePointsTasksEntity;
    final logs = results[2] as ProfilePointsLogPageEntity;
    return ProfilePointsOverviewEntity(
      stat: stat,
      registerTask: tasks.registerTask,
      tasks: tasks.tasks,
      entries: logs.records,
      total: logs.total,
      pageNo: logs.pageNo,
      pageSize: logs.pageSize,
    );
  }
}

class _NoPointsOverviewState {
  const _NoPointsOverviewState();

  ProfilePointsOverviewEntity merge({
    required ProfilePointsAccountStatEntity stat,
    required ProfilePointsTasksEntity tasks,
    required ProfilePointsLogPageEntity logs,
  }) {
    return ProfilePointsOverviewEntity(
      stat: stat,
      registerTask: tasks.registerTask,
      tasks: tasks.tasks,
      entries: logs.records,
      total: logs.total,
      pageNo: logs.pageNo,
      pageSize: logs.pageSize,
    );
  }
}

extension on ProfilePointsOverviewEntity {
  ProfilePointsOverviewEntity merge({
    required ProfilePointsAccountStatEntity stat,
    required ProfilePointsTasksEntity tasks,
    required ProfilePointsLogPageEntity logs,
  }) {
    return copyWith(
      stat: stat,
      registerTask: tasks.registerTask,
      clearRegisterTask: tasks.registerTask == null,
      tasks: tasks.tasks,
      entries: logs.records,
      total: logs.total,
      pageNo: logs.pageNo,
      pageSize: logs.pageSize,
      isLoadingMore: false,
      isCheckingIn: false,
    );
  }
}
