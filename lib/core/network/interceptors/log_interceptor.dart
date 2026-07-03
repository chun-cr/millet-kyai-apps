// 网络日志拦截器。集中打印请求、响应和错误信息，便于排查接口联调与线上问题。

import 'dart:convert';

import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.network(
      'REQUEST[${options.method}] => PATH: ${options.path} '
      'HEADERS: ${_describeHeaders(options.headers)} '
      'QUERY: ${_describeJson(options.queryParameters)} '
      'BODY: ${_describeBody(options.data)}',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.network(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path} '
      'BODY: ${_describeJson(response.data)}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.network(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path} '
      'BODY: ${_describeJson(err.response?.data)}',
    );
    super.onError(err, handler);
  }

  String _describeHeaders(Map<String, dynamic> headers) {
    final summary = <String, dynamic>{};
    for (final entry in headers.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key.toLowerCase() == 'authorization') {
        final raw = value?.toString() ?? '';
        summary[key] = raw.isEmpty ? '' : '${raw.split(' ').first} ***';
        continue;
      }
      summary[key] = value?.toString() ?? '';
    }
    return _describeJson(summary);
  }

  String _describeBody(Object? data) {
    if (data is FormData) {
      final fields = Map<String, String>.fromEntries(data.fields);
      final files = <String, String>{
        for (final entry in data.files)
          entry.key: entry.value.filename ?? 'unnamed-file',
      };
      return _describeJson(<String, Object?>{'fields': fields, 'files': files});
    }
    return _describeJson(data);
  }

  String _describeJson(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      return _truncate(value);
    }
    try {
      return _truncate(jsonEncode(value));
    } on Object {
      return _truncate(value.toString());
    }
  }

  String _truncate(String value) {
    const maxLength = 500;
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}
