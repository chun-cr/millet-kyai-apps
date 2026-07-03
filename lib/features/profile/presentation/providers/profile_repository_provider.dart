// 个人中心模块状态提供层：`ProfileRepositoryProvider`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:millet_kyai_apps/features/profile/data/sources/profile_remote_source.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  initInjector();
  final dioClient = getIt<DioClient>();
  final remoteSource = ProfileRemoteSource(dioClient);
  return ProfileRepositoryImpl(remoteSource);
});

final profileMeProvider = FutureProvider<ProfileMeEntity>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMe();
});
