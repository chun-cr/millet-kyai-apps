// 个人中心模块仓储实现：`ProfileRepositoryImpl`。负责组合数据源结果，并向上层输出稳定的业务数据。

import '../../domain/entities/profile_me_entity.dart';
import '../../domain/entities/profile_points_account_simple_entity.dart';
import '../../domain/entities/profile_points_account_stat_entity.dart';
import '../../domain/entities/profile_points_log_page_entity.dart';
import '../../domain/entities/profile_points_tasks_entity.dart';
import '../../domain/entities/profile_shipping_address_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../sources/profile_remote_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remoteSource);

  final ProfileRemoteSource _remoteSource;

  @override
  Future<ProfileMeEntity> fetchMe() async {
    final model = await _remoteSource.fetchMe();
    return model.toEntity();
  }

  @override
  Future<List<ProfileShippingAddressEntity>> fetchShippingAddresses() {
    return _remoteSource.fetchShippingAddresses();
  }

  @override
  Future<ProfileShippingAddressEntity> fetchDefaultShippingAddress() {
    return _remoteSource.fetchDefaultShippingAddress();
  }

  @override
  Future<ProfileShippingAddressEntity> fetchShippingAddressDetail(String id) {
    return _remoteSource.fetchShippingAddressDetail(id);
  }

  @override
  Future<ProfileShippingAddressEntity> createShippingAddress(
    ProfileShippingAddressEntity address,
  ) {
    return _remoteSource.createShippingAddress(address);
  }

  @override
  Future<ProfileShippingAddressEntity> updateShippingAddress(
    ProfileShippingAddressEntity address,
  ) {
    return _remoteSource.updateShippingAddress(address);
  }

  @override
  Future<void> deleteShippingAddress(String id) {
    return _remoteSource.deleteShippingAddress(id);
  }

  @override
  Future<ProfileShippingAddressEntity> setDefaultShippingAddress(String id) {
    return _remoteSource.setDefaultShippingAddress(id);
  }

  @override
  Future<ProfilePointsAccountStatEntity> signInPoints() {
    return _remoteSource.signInPoints();
  }

  @override
  Future<ProfilePointsAccountSimpleEntity> fetchPointsAccountSimpleInfo() {
    return _remoteSource.fetchPointsAccountSimpleInfo();
  }

  @override
  Future<ProfilePointsAccountStatEntity> fetchPointsAccountStat() {
    return _remoteSource.fetchPointsAccountStat();
  }

  @override
  Future<ProfilePointsTasksEntity> fetchPointsTasks() {
    return _remoteSource.fetchPointsTasks();
  }

  @override
  Future<ProfilePointsLogPageEntity> fetchPointsLogs({
    required int pageNo,
    required int pageSize,
  }) {
    return _remoteSource.fetchPointsLogs(pageNo: pageNo, pageSize: pageSize);
  }
}
