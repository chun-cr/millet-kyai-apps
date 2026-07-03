// 个人中心模块远端数据源：`ProfileRemoteSource`。负责与后端接口交互，并把请求/响应细节限制在数据层内部。

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/profile_points_account_simple_entity.dart';
import '../../domain/entities/profile_points_account_stat_entity.dart';
import '../../domain/entities/profile_points_log_page_entity.dart';
import '../../domain/entities/profile_points_tasks_entity.dart';
import '../../domain/entities/profile_shipping_address_entity.dart';
import '../models/profile_me_model.dart';

class ProfileRemoteSource {
  ProfileRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Map<String, dynamic> _responseEnvelope(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('Invalid response envelope');
    }
    return responseData;
  }

  Map<String, dynamic> _dataMap(dynamic responseData) {
    final envelope = _responseEnvelope(responseData);
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing response data');
    }
    return data;
  }

  List<Map<String, dynamic>> _dataList(dynamic responseData) {
    final envelope = _responseEnvelope(responseData);
    final data = envelope['data'];
    if (data is! List) {
      throw const FormatException('Missing response data list');
    }
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  void _allowNullData(dynamic responseData) {
    final envelope = _responseEnvelope(responseData);
    if (!envelope.containsKey('data')) {
      throw const FormatException('Missing response data field');
    }
  }

  Future<ProfileMeModel> fetchMe() async {
    final response = await _dioClient.dio.get('/api/v1/saas/mobile/user/me');
    return ProfileMeModel.fromJson(_dataMap(response.data));
  }

  Future<List<ProfileShippingAddressEntity>> fetchShippingAddresses() async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/receiving-addresses',
    );
    return _dataList(
      response.data,
    ).map(ProfileShippingAddressEntity.fromJson).toList(growable: false);
  }

  Future<ProfileShippingAddressEntity> fetchDefaultShippingAddress() async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/receiving-addresses/default',
    );
    return ProfileShippingAddressEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfileShippingAddressEntity> fetchShippingAddressDetail(
    String id,
  ) async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/receiving-addresses/$id',
    );
    return ProfileShippingAddressEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfileShippingAddressEntity> createShippingAddress(
    ProfileShippingAddressEntity address,
  ) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/receiving-addresses',
      data: address.toCreateRequestJson(),
    );
    return ProfileShippingAddressEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfileShippingAddressEntity> updateShippingAddress(
    ProfileShippingAddressEntity address,
  ) async {
    final response = await _dioClient.dio.put(
      '/api/v1/saas/mobile/receiving-addresses/${address.id}',
      data: address.toCreateRequestJson(),
    );
    return ProfileShippingAddressEntity.fromJson(_dataMap(response.data));
  }

  Future<void> deleteShippingAddress(String id) async {
    final response = await _dioClient.dio.delete(
      '/api/v1/saas/mobile/receiving-addresses/$id',
    );
    _allowNullData(response.data);
  }

  Future<ProfileShippingAddressEntity> setDefaultShippingAddress(
    String id,
  ) async {
    final response = await _dioClient.dio.put(
      '/api/v1/saas/mobile/receiving-addresses/$id/default',
    );
    return ProfileShippingAddressEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfilePointsAccountStatEntity> signInPoints() async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/point/signin',
    );
    return ProfilePointsAccountStatEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfilePointsAccountSimpleEntity>
  fetchPointsAccountSimpleInfo() async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/point/account/info/simple',
    );
    return ProfilePointsAccountSimpleEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfilePointsAccountStatEntity> fetchPointsAccountStat() async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/point/account/stat',
    );
    return ProfilePointsAccountStatEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfilePointsTasksEntity> fetchPointsTasks() async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/point/tasks',
    );
    return ProfilePointsTasksEntity.fromJson(_dataMap(response.data));
  }

  Future<ProfilePointsLogPageEntity> fetchPointsLogs({
    required int pageNo,
    required int pageSize,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/point/account/log',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
    );
    return ProfilePointsLogPageEntity.fromJson(_dataMap(response.data));
  }
}
