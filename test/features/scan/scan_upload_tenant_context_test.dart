import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/utils/scan_upload_tenant_context.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/app_id_mapping_entity.dart';

void main() {
  test('resolveScanUploadTenantContext prefers explicit current ids', () {
    const mapping = AppIdMappingEntity(
      tenantId: '101',
      topOrgId: '102',
      storeId: '103',
      clinicId: '104',
      defaultStoreId: '105',
      defaultClinicId: '106',
    );

    final context = resolveScanUploadTenantContext(mapping);

    expect(context.tenantId, 101);
    expect(context.topOrgId, 102);
    expect(context.storeId, 103);
    expect(context.clinicId, 104);
  });

  test('resolveScanUploadTenantContext falls back to compat ids', () {
    const mapping = AppIdMappingEntity(
      topOrgId: '202',
      defaultStoreId: '203',
      defaultClinicId: '204',
    );

    final context = resolveScanUploadTenantContext(mapping);

    expect(context.tenantId, 202);
    expect(context.topOrgId, 202);
    expect(context.storeId, 203);
    expect(context.clinicId, 204);
  });
}
