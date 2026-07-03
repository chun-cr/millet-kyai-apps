// 个人中心模块状态提供层：`ProfileAddressProvider`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:millet_kyai_apps/features/profile/data/stores/profile_address_store.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/repositories/profile_repository.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';

final profileAddressStoreProvider = Provider<ProfileAddressStore>((ref) {
  return ProfileAddressStore();
});

final profileAddressesProvider =
    AsyncNotifierProvider<
      ProfileAddressesController,
      List<ProfileShippingAddressEntity>
    >(ProfileAddressesController.new);

final profileDefaultShippingAddressProvider =
    FutureProvider<ProfileShippingAddressEntity?>((ref) async {
      final repository = ref.watch(profileRepositoryProvider);
      try {
        return await repository.fetchDefaultShippingAddress();
      } on Object {
        final addresses = await ref.watch(profileAddressesProvider.future);
        return _resolveDefaultAddress(addresses);
      }
    });

class ProfileAddressesController
    extends AsyncNotifier<List<ProfileShippingAddressEntity>> {
  ProfileAddressStore get _store => ref.read(profileAddressStoreProvider);
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  FutureOr<List<ProfileShippingAddressEntity>> build() async {
    final cached = await _store.loadAddresses();
    try {
      return await _syncFromRemote();
    } on Object {
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<void> upsertAddress(ProfileShippingAddressEntity address) async {
    final nextAddress = address.id.isEmpty
        ? await _repository.createShippingAddress(address)
        : await _repository.updateShippingAddress(address);
    final updated = await _refreshWithFallback(
      fallback: () => _store.upsertAddress(nextAddress),
    );
    state = AsyncData(updated);
    ref.invalidate(profileDefaultShippingAddressProvider);
  }

  Future<void> deleteAddress(String id) async {
    await _repository.deleteShippingAddress(id);
    final updated = await _refreshWithFallback(
      fallback: () => _store.deleteAddress(id),
    );
    state = AsyncData(updated);
    ref.invalidate(profileDefaultShippingAddressProvider);
  }

  Future<void> setDefaultAddress(String id) async {
    final address = await _repository.setDefaultShippingAddress(id);
    final updated = await _refreshWithFallback(
      fallback: () => _store.setDefaultAddress(address.id),
    );
    state = AsyncData(updated);
    ref.invalidate(profileDefaultShippingAddressProvider);
  }

  Future<List<ProfileShippingAddressEntity>> refresh() async {
    final updated = await _syncFromRemote();
    state = AsyncData(updated);
    ref.invalidate(profileDefaultShippingAddressProvider);
    return updated;
  }

  Future<ProfileShippingAddressEntity> loadAddressDetail(String id) async {
    final detail = await _repository.fetchShippingAddressDetail(id);
    final updated = await _store.upsertAddress(detail);
    if (state.hasValue) {
      state = AsyncData(updated);
    }
    if (detail.isDefault) {
      ref.invalidate(profileDefaultShippingAddressProvider);
    }
    return detail;
  }

  Future<List<ProfileShippingAddressEntity>> _syncFromRemote() async {
    final remoteAddresses = await _repository.fetchShippingAddresses();
    return _store.replaceAll(remoteAddresses);
  }

  Future<List<ProfileShippingAddressEntity>> _refreshWithFallback({
    required Future<List<ProfileShippingAddressEntity>> Function() fallback,
  }) async {
    try {
      return await _syncFromRemote();
    } on Object {
      return fallback();
    }
  }
}

ProfileShippingAddressEntity? _resolveDefaultAddress(
  List<ProfileShippingAddressEntity> addresses,
) {
  for (final address in addresses) {
    if (address.isDefault) {
      return address;
    }
  }
  return addresses.isEmpty ? null : addresses.first;
}
