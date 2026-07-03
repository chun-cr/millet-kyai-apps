// 全局依赖注入入口。集中注册网络、会话、扫描等跨模块共享的单例服务，避免页面层直接创建基础设施对象。

import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/auth_session_store.dart';
import '../security/login_password_store.dart';
import '../../features/scan/data/models/scan_session.dart';

final getIt = GetIt.instance;

/// 惰性注册跨模块共享服务。
/// 这样页面在每次进入时只需要取用依赖，不必重复构建整套容器。
void initInjector() {
  if (!getIt.isRegistered<AuthSessionStore>()) {
    getIt.registerLazySingleton<AuthSessionStore>(() => AuthSessionStore());
  }
  if (!getIt.isRegistered<LoginPasswordStore>()) {
    getIt.registerLazySingleton<LoginPasswordStore>(() => LoginPasswordStore());
  }
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(() => DioClient());
  }
  if (!getIt.isRegistered<ScanSession>()) {
    getIt.registerLazySingleton<ScanSession>(() => ScanSession());
  }
}
