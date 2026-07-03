// 认证模块数据模型：`AuthRequest`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_request.freezed.dart';
part 'auth_request.g.dart';

@freezed
abstract class AuthRequest with _$AuthRequest {
  const factory AuthRequest({
    required String countryCode,
    required String phoneNumber,
    String? password,
    String? code,
    String? inviteTicket,
  }) = _AuthRequest;

  factory AuthRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthRequestFromJson(json);
}
