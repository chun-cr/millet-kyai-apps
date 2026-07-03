// 个人中心模块领域实体：`ProfilePointsOverviewEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

import 'profile_points_account_stat_entity.dart';
import 'profile_points_entry_entity.dart';
import 'profile_points_task_entity.dart';

class ProfilePointsOverviewEntity {
  const ProfilePointsOverviewEntity({
    required this.stat,
    required this.registerTask,
    required this.tasks,
    required this.entries,
    required this.total,
    required this.pageNo,
    required this.pageSize,
    this.isLoadingMore = false,
    this.isCheckingIn = false,
  });

  final ProfilePointsAccountStatEntity stat;
  final ProfilePointsTaskEntity? registerTask;
  final List<ProfilePointsTaskEntity> tasks;
  final List<ProfilePointsEntryEntity> entries;
  final int total;
  final int pageNo;
  final int pageSize;
  final bool isLoadingMore;
  final bool isCheckingIn;

  int get balance => stat.availableAmount;
  int get hisTotalAmount => stat.hisTotalAmount;
  int get todayGainAmount => stat.todayGainAmount;
  int get weekGainAmount => stat.weekGainAmount;
  bool get canCheckInToday => !stat.signIn;
  bool get canLoadMore => entries.length < total;

  ProfilePointsOverviewEntity copyWith({
    ProfilePointsAccountStatEntity? stat,
    ProfilePointsTaskEntity? registerTask,
    bool clearRegisterTask = false,
    List<ProfilePointsTaskEntity>? tasks,
    List<ProfilePointsEntryEntity>? entries,
    int? total,
    int? pageNo,
    int? pageSize,
    bool? isLoadingMore,
    bool? isCheckingIn,
  }) {
    return ProfilePointsOverviewEntity(
      stat: stat ?? this.stat,
      registerTask: clearRegisterTask
          ? null
          : registerTask ?? this.registerTask,
      tasks: tasks ?? this.tasks,
      entries: entries ?? this.entries,
      total: total ?? this.total,
      pageNo: pageNo ?? this.pageNo,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
    );
  }
}
