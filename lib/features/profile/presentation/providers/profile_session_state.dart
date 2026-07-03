// 个人中心模块状态提供层：`ProfileSessionState`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:millet_kyai_apps/features/profile/data/stores/profile_address_store.dart';

import 'profile_address_provider.dart';
import 'profile_points_provider.dart';
import 'profile_repository_provider.dart';

Future<void> clearProfileScopedPersistence() async {
  await ProfileAddressStore().clear();
}

void invalidateProfileScopedProvidersInContainer(ProviderContainer container) {
  container.invalidate(profileMeProvider);
  container.invalidate(profileAddressesProvider);
  container.invalidate(profileDefaultShippingAddressProvider);
  container.invalidate(profilePointsBalanceProvider);
  container.invalidate(profilePointsProvider);
}

void invalidateProfileScopedProviders(WidgetRef ref) {
  ref.invalidate(profileMeProvider);
  ref.invalidate(profileAddressesProvider);
  ref.invalidate(profileDefaultShippingAddressProvider);
  ref.invalidate(profilePointsBalanceProvider);
  ref.invalidate(profilePointsProvider);
}
