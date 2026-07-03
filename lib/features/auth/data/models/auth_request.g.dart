// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthRequest _$AuthRequestFromJson(Map<String, dynamic> json) => _AuthRequest(
  countryCode: json['countryCode'] as String,
  phoneNumber: json['phoneNumber'] as String,
  password: json['password'] as String?,
  code: json['code'] as String?,
  inviteTicket: json['inviteTicket'] as String?,
);

Map<String, dynamic> _$AuthRequestToJson(_AuthRequest instance) =>
    <String, dynamic>{
      'countryCode': instance.countryCode,
      'phoneNumber': instance.phoneNumber,
      'password': instance.password,
      'code': instance.code,
      'inviteTicket': instance.inviteTicket,
    };
