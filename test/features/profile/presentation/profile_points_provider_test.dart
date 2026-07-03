import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_account_stat_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_entry_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_task_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_tasks_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_log_page_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/repositories/profile_repository.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_points_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';

void main() {
  test('claimDailyCheckIn refreshes tasks and first page logs', () async {
    final repository = _FakeProfileRepository(
      initialStat: _buildStat(),
      initialTasks: _buildTasks(
        tasks: [
          _buildTask(
            code: 'browse',
            name: 'Browse content',
            btnName: 'Go',
            path: '/scan',
          ),
        ],
      ),
      initialLogs: _buildLogs(
        records: [
          _buildEntry(
            id: 'log-1',
            description: 'Initial reward',
            incomeAmount: 1,
          ),
        ],
      ),
      signInResponse: _buildStat(
        balance: 15,
        todayGainAmount: 5,
        weekGainAmount: 5,
        hisTotalAmount: 15,
        signIn: true,
      ),
      updatedTasks: _buildTasks(
        tasks: [
          _buildTask(
            code: 'scan',
            name: 'Complete a scan',
            btnName: 'Start',
            path: '/scan',
          ),
        ],
      ),
      updatedLogs: _buildLogs(
        records: [
          _buildEntry(
            id: 'log-2',
            description: 'Daily sign-in',
            incomeAmount: 5,
          ),
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(profilePointsProvider.future);
    expect(initial.balance, 10);
    expect(initial.tasks.single.name, 'Browse content');

    final updated = await container
        .read(profilePointsProvider.notifier)
        .claimDailyCheckIn();

    expect(updated.balance, 15);
    expect(updated.canCheckInToday, isFalse);
    expect(updated.tasks.single.name, 'Complete a scan');
    expect(updated.entries.single.title, 'Daily sign-in');
    expect(updated.isCheckingIn, isFalse);
    expect(repository.fetchPointsTasksCalls, 2);
    expect(repository.fetchPointsLogsCalls, 2);
    expect(repository.recordedPageNos, [1, 1]);
    expect(repository.recordedPageSizes, [20, 20]);
  });

  test('claimDailyCheckIn reuses the in-flight refresh request', () async {
    final signInCompleter = Completer<ProfilePointsAccountStatEntity>();
    final repository = _FakeProfileRepository(
      initialStat: _buildStat(),
      initialTasks: _buildTasks(
        tasks: [
          _buildTask(
            code: 'signin',
            name: 'Daily sign-in',
            btnName: 'Check in',
            path: '/profile/points',
          ),
        ],
      ),
      initialLogs: _buildLogs(
        records: [
          _buildEntry(
            id: 'log-1',
            description: 'Initial reward',
            incomeAmount: 1,
          ),
        ],
      ),
      signInHandler: () => signInCompleter.future,
      updatedTasks: _buildTasks(
        tasks: [
          _buildTask(
            code: 'scan',
            name: 'Complete a scan',
            btnName: 'Start',
            path: '/scan',
          ),
        ],
      ),
      updatedLogs: _buildLogs(
        records: [
          _buildEntry(
            id: 'log-2',
            description: 'Daily sign-in',
            incomeAmount: 5,
          ),
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(profilePointsProvider.future);

    final controller = container.read(profilePointsProvider.notifier);
    final future1 = controller.claimDailyCheckIn();
    final future2 = controller.claimDailyCheckIn();

    expect(identical(future1, future2), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(profilePointsProvider).requireValue.isCheckingIn,
      isTrue,
    );
    expect(repository.signInCalls, 1);

    signInCompleter.complete(
      _buildStat(
        balance: 15,
        todayGainAmount: 5,
        weekGainAmount: 5,
        hisTotalAmount: 15,
        signIn: true,
      ),
    );

    final updated = await future1;
    expect(updated.isCheckingIn, isFalse);
    expect(updated.canCheckInToday, isFalse);
    expect(repository.signInCalls, 1);
    expect(repository.fetchPointsTasksCalls, 2);
    expect(repository.fetchPointsLogsCalls, 2);
  });
}

class _FakeProfileRepository extends ProfileRepositoryAdapter {
  _FakeProfileRepository({
    required this.initialStat,
    required this.initialTasks,
    required this.initialLogs,
    required this.updatedTasks,
    required this.updatedLogs,
    this.signInResponse,
    this.signInHandler,
  });

  final ProfilePointsAccountStatEntity initialStat;
  final ProfilePointsTasksEntity initialTasks;
  final ProfilePointsLogPageEntity initialLogs;
  final ProfilePointsTasksEntity updatedTasks;
  final ProfilePointsLogPageEntity updatedLogs;
  final ProfilePointsAccountStatEntity? signInResponse;
  final Future<ProfilePointsAccountStatEntity> Function()? signInHandler;

  int signInCalls = 0;
  int fetchPointsAccountStatCalls = 0;
  int fetchPointsTasksCalls = 0;
  int fetchPointsLogsCalls = 0;
  final List<int> recordedPageNos = <int>[];
  final List<int> recordedPageSizes = <int>[];

  @override
  Future<ProfilePointsAccountStatEntity> fetchPointsAccountStat() async {
    fetchPointsAccountStatCalls += 1;
    return initialStat;
  }

  @override
  Future<ProfilePointsTasksEntity> fetchPointsTasks() async {
    fetchPointsTasksCalls += 1;
    return fetchPointsTasksCalls == 1 ? initialTasks : updatedTasks;
  }

  @override
  Future<ProfilePointsLogPageEntity> fetchPointsLogs({
    required int pageNo,
    required int pageSize,
  }) async {
    fetchPointsLogsCalls += 1;
    recordedPageNos.add(pageNo);
    recordedPageSizes.add(pageSize);
    return fetchPointsLogsCalls == 1 ? initialLogs : updatedLogs;
  }

  @override
  Future<ProfilePointsAccountStatEntity> signInPoints() {
    signInCalls += 1;
    final handler = signInHandler;
    if (handler != null) {
      return handler();
    }
    return Future<ProfilePointsAccountStatEntity>.value(
      signInResponse ?? initialStat,
    );
  }
}

ProfilePointsAccountStatEntity _buildStat({
  int balance = 10,
  int hisTotalAmount = 10,
  int todayGainAmount = 0,
  int weekGainAmount = 0,
  bool signIn = false,
}) {
  return ProfilePointsAccountStatEntity(
    id: 'points-account',
    userId: 'user-1',
    availableAmount: balance,
    hisTotalAmount: hisTotalAmount,
    todayGainAmount: todayGainAmount,
    weekGainAmount: weekGainAmount,
    signIn: signIn,
  );
}

ProfilePointsTasksEntity _buildTasks({
  ProfilePointsTaskEntity? registerTask,
  required List<ProfilePointsTaskEntity> tasks,
}) {
  return ProfilePointsTasksEntity(registerTask: registerTask, tasks: tasks);
}

ProfilePointsTaskEntity _buildTask({
  required String code,
  required String name,
  required String btnName,
  required String path,
}) {
  return ProfilePointsTaskEntity(
    code: code,
    name: name,
    amount: 5,
    description: '$name description',
    finishTimesTip: '1/1',
    extra: const {},
    btnName: btnName,
    path: path,
  );
}

ProfilePointsLogPageEntity _buildLogs({
  required List<ProfilePointsEntryEntity> records,
}) {
  return ProfilePointsLogPageEntity(
    records: records,
    total: records.length,
    pageNo: 1,
    pageSize: 20,
  );
}

ProfilePointsEntryEntity _buildEntry({
  required String id,
  required String description,
  required int incomeAmount,
}) {
  return ProfilePointsEntryEntity(
    id: id,
    description: description,
    remarks: '',
    incomeAmount: incomeAmount,
    createTime: DateTime.utc(2026, 1, 1),
  );
}
