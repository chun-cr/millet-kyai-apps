// 认证模块状态提供层：`AuthProvider`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/auth_request.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_repository_provider.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  UserEntity? build() {
    return null; // Not authenticated by default
  }

  Future<void> login(AuthRequest request) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.login(request);
  }

  Future<void> register(AuthRequest request) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.register(request);
  }

  void logout() {
    state = null;
  }
}
