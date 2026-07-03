import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/features/profile/data/sources/profile_remote_source.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';

typedef _AdapterHandler = ResponseBody Function(RequestOptions options);

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._handler);

  final _AdapterHandler _handler;

  late RequestOptions lastRequestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return _handler(options);
  }
}

ResponseBody _jsonResponse(Object? data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ProfileShippingAddressEntity _addressFromList(
  List<ProfileShippingAddressEntity> value,
) {
  return value.single;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app/info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAppId');
      return 'com.permillet.myapp.dev';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppIdentity.resetForTest();
  });

  test('fetch shipping addresses parses list response', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': [
          {
            'addressId': 'addr-list-1',
            'receiverName': 'Amin',
            'receiverMobile': '13812345678',
            'provinceCode': '310000',
            'provinceName': 'Shanghai',
            'cityCode': '310100',
            'cityName': 'Shanghai',
            'districtCode': '310104',
            'districtName': 'Xuhui',
            'streetCode': '310104001',
            'streetName': 'Tianlin',
            'detailAddress': 'Lane 88, Room 1801',
            'defaultAddress': true,
          },
        ],
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final addresses = await remoteSource.fetchShippingAddresses();

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses',
    );
    expect(
      adapter.lastRequestOptions.headers['X-App-Id'],
      'com.permillet.myapp.dev',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(addresses, hasLength(1));
    expect(_addressFromList(addresses).id, 'addr-list-1');
    expect(_addressFromList(addresses).isDefault, isTrue);
  });

  test('fetch default shipping address hits default endpoint', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'addressId': 'addr-default-1',
          'receiverName': 'Lee',
          'receiverMobile': '13912345678',
          'provinceCode': '110000',
          'provinceName': 'Beijing',
          'cityCode': '110100',
          'cityName': 'Beijing',
          'districtCode': '110105',
          'districtName': 'Chaoyang',
          'streetCode': '110105001',
          'streetName': 'Jianguomenwai',
          'detailAddress': 'Tower 3, Room 901',
          'defaultAddress': true,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final address = await remoteSource.fetchDefaultShippingAddress();

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses/default',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(address.id, 'addr-default-1');
    expect(address.cityName, 'Beijing');
  });

  test('fetch shipping address detail hits detail endpoint', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'addressId': 'addr-detail-1',
          'receiverName': 'Amin',
          'receiverMobile': '13812345678',
          'provinceCode': '440000',
          'provinceName': 'Guangdong',
          'cityCode': '440300',
          'cityName': 'Shenzhen',
          'districtCode': '440305',
          'districtName': 'Nanshan',
          'streetCode': '440305001',
          'streetName': 'Yuehai',
          'detailAddress': 'Building A, Room 1602',
          'defaultAddress': false,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final address = await remoteSource.fetchShippingAddressDetail(
      'addr-detail-1',
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses/addr-detail-1',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(address.districtName, 'Nanshan');
  });

  test('create shipping address posts API contract payload', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'addressId': 'addr-remote-1',
          'receiverName': 'Amin',
          'receiverMobile': '13812345678',
          'provinceCode': '310000',
          'provinceName': 'Shanghai',
          'cityCode': '310100',
          'cityName': 'Shanghai',
          'districtCode': '310104',
          'districtName': 'Xuhui',
          'streetCode': '310104001',
          'streetName': 'Tianlin',
          'detailAddress': 'Lane 88, Room 1801',
          'defaultAddress': true,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final created = await remoteSource.createShippingAddress(
      const ProfileShippingAddressEntity(
        id: '',
        receiverName: 'Amin',
        receiverMobile: '13812345678',
        provinceCode: '310000',
        provinceName: 'Shanghai',
        cityCode: '310100',
        cityName: 'Shanghai',
        districtCode: '310104',
        districtName: 'Xuhui',
        streetCode: '310104001',
        streetName: 'Tianlin',
        detailAddress: 'Lane 88, Room 1801',
        isDefault: true,
      ),
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses',
    );
    expect(adapter.lastRequestOptions.method, 'POST');
    expect(adapter.lastRequestOptions.data, {
      'receiverName': 'Amin',
      'receiverMobile': '13812345678',
      'provinceCode': '310000',
      'provinceName': 'Shanghai',
      'cityCode': '310100',
      'cityName': 'Shanghai',
      'districtCode': '310104',
      'districtName': 'Xuhui',
      'streetCode': '310104001',
      'streetName': 'Tianlin',
      'detailAddress': 'Lane 88, Room 1801',
      'defaultAddress': true,
    });
    expect(created.id, 'addr-remote-1');
    expect(created.receiverMobile, '13812345678');
    expect(created.provinceName, 'Shanghai');
    expect(created.streetName, 'Tianlin');
    expect(created.isDefault, isTrue);
  });

  test('update shipping address puts API contract payload', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'addressId': 'addr-update-1',
          'receiverName': 'Amin Updated',
          'receiverMobile': '13812345679',
          'provinceCode': '310000',
          'provinceName': 'Shanghai',
          'cityCode': '310100',
          'cityName': 'Shanghai',
          'districtCode': '310104',
          'districtName': 'Xuhui',
          'streetCode': '310104001',
          'streetName': 'Tianlin',
          'detailAddress': 'Lane 99, Room 1001',
          'defaultAddress': false,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final updated = await remoteSource.updateShippingAddress(
      const ProfileShippingAddressEntity(
        id: 'addr-update-1',
        receiverName: 'Amin Updated',
        receiverMobile: '13812345679',
        provinceCode: '310000',
        provinceName: 'Shanghai',
        cityCode: '310100',
        cityName: 'Shanghai',
        districtCode: '310104',
        districtName: 'Xuhui',
        streetCode: '310104001',
        streetName: 'Tianlin',
        detailAddress: 'Lane 99, Room 1001',
        isDefault: false,
      ),
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses/addr-update-1',
    );
    expect(adapter.lastRequestOptions.method, 'PUT');
    expect(adapter.lastRequestOptions.data, {
      'receiverName': 'Amin Updated',
      'receiverMobile': '13812345679',
      'provinceCode': '310000',
      'provinceName': 'Shanghai',
      'cityCode': '310100',
      'cityName': 'Shanghai',
      'districtCode': '310104',
      'districtName': 'Xuhui',
      'streetCode': '310104001',
      'streetName': 'Tianlin',
      'detailAddress': 'Lane 99, Room 1001',
      'defaultAddress': false,
    });
    expect(updated.detailAddress, 'Lane 99, Room 1001');
    expect(updated.isDefault, isFalse);
  });

  test('delete shipping address calls delete endpoint', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    await remoteSource.deleteShippingAddress('addr-delete-1');

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses/addr-delete-1',
    );
    expect(adapter.lastRequestOptions.method, 'DELETE');
  });

  test('set default shipping address calls default endpoint', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'addressId': 'addr-default-2',
          'receiverName': 'Lee',
          'receiverMobile': '13912345678',
          'provinceCode': '110000',
          'provinceName': 'Beijing',
          'cityCode': '110100',
          'cityName': 'Beijing',
          'districtCode': '110105',
          'districtName': 'Chaoyang',
          'streetCode': '110105001',
          'streetName': 'Jianguomenwai',
          'detailAddress': 'Tower 3, Room 901',
          'defaultAddress': true,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final address = await remoteSource.setDefaultShippingAddress(
      'addr-default-2',
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/receiving-addresses/addr-default-2/default',
    );
    expect(adapter.lastRequestOptions.method, 'PUT');
    expect(address.id, 'addr-default-2');
    expect(address.isDefault, isTrue);
  });

  test('sign in points posts endpoint and parses stat response', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'id': 'point-stat-1',
          'userId': 'user-1',
          'availableAmount': 120,
          'hisTotalAmount': 200,
          'todayGainAmount': 5,
          'weekGainAmount': 15,
          'signIn': true,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final stat = await remoteSource.signInPoints();

    expect(adapter.lastRequestOptions.path, '/api/v1/saas/mobile/point/signin');
    expect(adapter.lastRequestOptions.method, 'POST');
    expect(stat.availableAmount, 120);
    expect(stat.signIn, isTrue);
  });

  test('fetch points account simple info gets balance summary', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'id': 'point-simple-1',
          'userId': 'user-1',
          'availableAmount': 88,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final simple = await remoteSource.fetchPointsAccountSimpleInfo();

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/point/account/info/simple',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(simple.availableAmount, 88);
  });

  test('fetch points account stat gets full stat summary', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'id': 'point-stat-2',
          'userId': 'user-2',
          'availableAmount': 220,
          'hisTotalAmount': 560,
          'todayGainAmount': 10,
          'weekGainAmount': 35,
          'signIn': false,
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final stat = await remoteSource.fetchPointsAccountStat();

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/point/account/stat',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(stat.hisTotalAmount, 560);
    expect(stat.signIn, isFalse);
  });

  test('fetch points tasks parses register task and task list', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'registerTask': {
            'code': 'register',
            'name': 'Complete registration',
            'amount': 20,
            'description': 'Finish signup to get points',
            'finishTimesTip': '1/1',
            'extra': {'scene': 'register'},
            'btnName': 'Go',
            'path': '/register',
          },
          'tasks': [
            {
              'code': 'signin',
              'name': 'Daily sign in',
              'amount': 5,
              'description': 'Sign in every day',
              'finishTimesTip': '0/1',
              'extra': {'scene': 'signin'},
              'btnName': 'Check in',
              'path': '/points',
            },
          ],
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ProfileRemoteSource(dioClient);

    final tasks = await remoteSource.fetchPointsTasks();

    expect(adapter.lastRequestOptions.path, '/api/v1/saas/mobile/point/tasks');
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(tasks.registerTask?.code, 'register');
    expect(tasks.tasks.single.code, 'signin');
    expect(tasks.tasks.single.amount, 5);
  });

  test(
    'fetch points logs passes pagination query and parses records',
    () async {
      final dioClient = DioClient();
      final adapter = _CaptureAdapter((options) {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'records': [
              {
                'id': 'log-1',
                'incomeAmount': 5,
                'description': 'Daily sign in',
                'remarks': 'Received daily reward',
                'createTime': '2019-08-24T14:15:22.123Z',
              },
            ],
            'total': 12,
            'pageNo': 2,
            'pageSize': 10,
          },
        });
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ProfileRemoteSource(dioClient);

      final logs = await remoteSource.fetchPointsLogs(pageNo: 2, pageSize: 10);

      expect(
        adapter.lastRequestOptions.path,
        '/api/v1/saas/mobile/point/account/log',
      );
      expect(adapter.lastRequestOptions.method, 'GET');
      expect(adapter.lastRequestOptions.queryParameters, {
        'pageNo': 2,
        'pageSize': 10,
      });
      expect(logs.records.single.incomeAmount, 5);
      expect(logs.records.single.remarks, 'Received daily reward');
      expect(logs.total, 12);
      expect(logs.pageNo, 2);
      expect(logs.pageSize, 10);
    },
  );
}
