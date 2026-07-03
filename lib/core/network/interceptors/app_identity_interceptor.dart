// 应用标识拦截器。为每个请求补充当前包标识和平台信息，方便后端识别客户端来源。

import 'package:dio/dio.dart';

import '../dio_client.dart';
import '../../platform/app_identity.dart';

class AppIdentityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[DioClient.skipPlatformHeadersExtraKey] == true) {
      options.headers.remove('X-Platform');
    }

    options.headers['X-App-Id'] = await AppIdentity.initialize();
    handler.next(options);
  }
}
