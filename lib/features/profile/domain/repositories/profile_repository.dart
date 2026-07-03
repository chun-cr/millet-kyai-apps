// 个人中心模块仓储契约：`ProfileRepository`。对上提供稳定业务接口，对下屏蔽远端与本地数据细节。

import '../entities/profile_me_entity.dart';
import '../entities/profile_points_account_simple_entity.dart';
import '../entities/profile_points_account_stat_entity.dart';
import '../entities/profile_points_log_page_entity.dart';
import '../entities/profile_points_tasks_entity.dart';
import '../entities/profile_shipping_address_entity.dart';

abstract class ProfileRepository {
  Future<ProfileMeEntity> fetchMe();

  Future<List<ProfileShippingAddressEntity>> fetchShippingAddresses();

  Future<ProfileShippingAddressEntity> fetchDefaultShippingAddress();

  Future<ProfileShippingAddressEntity> fetchShippingAddressDetail(String id);

  Future<ProfileShippingAddressEntity> createShippingAddress(
    ProfileShippingAddressEntity address,
  );

  Future<ProfileShippingAddressEntity> updateShippingAddress(
    ProfileShippingAddressEntity address,
  );

  Future<void> deleteShippingAddress(String id);

  Future<ProfileShippingAddressEntity> setDefaultShippingAddress(String id);

  Future<ProfilePointsAccountStatEntity> signInPoints();

  Future<ProfilePointsAccountSimpleEntity> fetchPointsAccountSimpleInfo();

  Future<ProfilePointsAccountStatEntity> fetchPointsAccountStat();

  Future<ProfilePointsTasksEntity> fetchPointsTasks();

  Future<ProfilePointsLogPageEntity> fetchPointsLogs({
    required int pageNo,
    required int pageSize,
  });
}

class ProfileRepositoryAdapter implements ProfileRepository {
  @override
  Future<ProfileMeEntity> fetchMe() {
    throw UnimplementedError();
  }

  @override
  Future<List<ProfileShippingAddressEntity>> fetchShippingAddresses() {
    throw UnimplementedError();
  }

  @override
  Future<ProfileShippingAddressEntity> fetchDefaultShippingAddress() {
    throw UnimplementedError();
  }

  @override
  Future<ProfileShippingAddressEntity> fetchShippingAddressDetail(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ProfileShippingAddressEntity> createShippingAddress(
    ProfileShippingAddressEntity address,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ProfileShippingAddressEntity> updateShippingAddress(
    ProfileShippingAddressEntity address,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteShippingAddress(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ProfileShippingAddressEntity> setDefaultShippingAddress(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ProfilePointsAccountStatEntity> signInPoints() {
    throw UnimplementedError();
  }

  @override
  Future<ProfilePointsAccountSimpleEntity> fetchPointsAccountSimpleInfo() {
    throw UnimplementedError();
  }

  @override
  Future<ProfilePointsAccountStatEntity> fetchPointsAccountStat() {
    throw UnimplementedError();
  }

  @override
  Future<ProfilePointsTasksEntity> fetchPointsTasks() {
    throw UnimplementedError();
  }

  @override
  Future<ProfilePointsLogPageEntity> fetchPointsLogs({
    required int pageNo,
    required int pageSize,
  }) {
    throw UnimplementedError();
  }
}
