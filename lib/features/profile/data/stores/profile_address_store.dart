// 个人中心模块本地存储：`ProfileAddressStore`。负责缓存本地状态，避免页面直接处理序列化和落盘细节。

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/profile_shipping_address_entity.dart';

class ProfileAddressStore {
  static const _addressesKey = 'profile_shipping_addresses';

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_addressesKey);
  }

  Future<List<ProfileShippingAddressEntity>> loadAddresses() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_addressesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final addresses = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(ProfileShippingAddressEntity.fromJson)
        .toList(growable: false);
    return _normalize(addresses);
  }

  Future<List<ProfileShippingAddressEntity>> replaceAll(
    List<ProfileShippingAddressEntity> addresses,
  ) async {
    final normalized = _normalize(addresses);
    await _saveAddresses(normalized);
    return normalized;
  }

  Future<List<ProfileShippingAddressEntity>> upsertAddress(
    ProfileShippingAddressEntity address,
  ) async {
    final current = await loadAddresses();
    final next = [...current];
    final index = next.indexWhere((item) => item.id == address.id);
    if (index >= 0) {
      next[index] = address;
    } else {
      next.insert(0, address);
    }

    final normalized = _normalize(next);
    await _saveAddresses(normalized);
    return normalized;
  }

  Future<List<ProfileShippingAddressEntity>> deleteAddress(String id) async {
    final current = await loadAddresses();
    final next = current.where((item) => item.id != id).toList(growable: false);
    final normalized = _normalize(next);
    await _saveAddresses(normalized);
    return normalized;
  }

  Future<List<ProfileShippingAddressEntity>> setDefaultAddress(
    String id,
  ) async {
    final current = await loadAddresses();
    final next = current
        .map((item) => item.copyWith(isDefault: item.id == id))
        .toList(growable: false);
    final normalized = _normalize(next);
    await _saveAddresses(normalized);
    return normalized;
  }

  Future<void> _saveAddresses(
    List<ProfileShippingAddressEntity> addresses,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(addresses.map((item) => item.toJson()).toList());
    await preferences.setString(_addressesKey, encoded);
  }

  List<ProfileShippingAddressEntity> _normalize(
    List<ProfileShippingAddressEntity> addresses,
  ) {
    if (addresses.isEmpty) {
      return const [];
    }

    String? defaultId;
    for (final item in addresses) {
      if (item.isDefault) {
        defaultId = item.id;
        break;
      }
    }
    defaultId ??= addresses.first.id;

    return addresses
        .map((item) => item.copyWith(isDefault: item.id == defaultId))
        .toList(growable: false);
  }
}
