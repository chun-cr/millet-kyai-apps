// 扫描模块展示层工具：`ScanUploadTenantContext`。负责承载展示层通用的计算、映射或调试辅助逻辑。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/share/domain/entities/app_id_mapping_entity.dart';
import '../../../../features/share/domain/entities/share_referral_state.dart';
import '../../../../features/share/presentation/providers/share_referral_provider.dart';

class ScanUploadTenantContext {
  const ScanUploadTenantContext({
    this.tenantId,
    this.topOrgId,
    this.storeId,
    this.clinicId,
  });

  final int? tenantId;
  final int? topOrgId;
  final int? storeId;
  final int? clinicId;

  bool get isEmpty =>
      tenantId == null &&
      topOrgId == null &&
      storeId == null &&
      clinicId == null;
}

Future<ScanUploadTenantContext> loadScanUploadTenantContext(
  BuildContext context,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  return loadScanUploadTenantContextFromContainer(container);
}

Future<ScanUploadTenantContext> tryLoadScanUploadTenantContext(
  BuildContext context, {
  bool initializeIfEmpty = false,
}) async {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return loadScanUploadTenantContextFromContainer(
      container,
      initializeIfEmpty: initializeIfEmpty,
    );
  } on Object {
    return const ScanUploadTenantContext();
  }
}

Future<ScanUploadTenantContext> loadScanUploadTenantContextFromContainer(
  ProviderContainer container, {
  bool initializeIfEmpty = false,
}) async {
  ScanUploadTenantContext resolvedContext;
  try {
    final state = await container.read(shareReferralControllerProvider.future);
    resolvedContext = resolveScanUploadTenantContext(
      state.appIdMapping.isEmpty ? null : state.appIdMapping,
    );
  } on Object {
    final cached = container.read(shareReferralControllerProvider);
    if (cached case AsyncData<ShareReferralState>(:final value)) {
      resolvedContext = resolveScanUploadTenantContext(
        value.appIdMapping.isEmpty ? null : value.appIdMapping,
      );
    } else {
      resolvedContext = const ScanUploadTenantContext();
    }
  }

  if (!initializeIfEmpty || !resolvedContext.isEmpty) {
    return resolvedContext;
  }

  try {
    final state = await container
        .read(shareReferralControllerProvider.notifier)
        .initializeAfterAuth();
    return resolveScanUploadTenantContext(
      state.appIdMapping.isEmpty ? null : state.appIdMapping,
    );
  } on Object {
    return resolvedContext;
  }
}

ScanUploadTenantContext resolveScanUploadTenantContext(
  AppIdMappingEntity? appIdMapping,
) {
  if (appIdMapping == null || appIdMapping.isEmpty) {
    return const ScanUploadTenantContext();
  }

  return ScanUploadTenantContext(
    tenantId: _resolveOptionalInt(<String>[
      appIdMapping.tenantId,
      appIdMapping.topOrgId,
    ]),
    topOrgId: _resolveOptionalInt(<String>[
      appIdMapping.topOrgId,
      appIdMapping.tenantId,
    ]),
    storeId: _resolveOptionalInt(<String>[
      appIdMapping.storeId,
      appIdMapping.defaultStoreId,
      appIdMapping.clinicId,
      appIdMapping.defaultClinicId,
    ]),
    clinicId: _resolveOptionalInt(<String>[
      appIdMapping.clinicId,
      appIdMapping.defaultClinicId,
      appIdMapping.storeId,
      appIdMapping.defaultStoreId,
    ]),
  );
}

String describeScanUploadTenantContext(ScanUploadTenantContext context) {
  return 'tenantId=${context.tenantId ?? "null"}, '
      'topOrgId=${context.topOrgId ?? "null"}, '
      'storeId=${context.storeId ?? "null"}, '
      'clinicId=${context.clinicId ?? "null"}';
}

int? _resolveOptionalInt(List<String> values) {
  for (final value in values) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}
