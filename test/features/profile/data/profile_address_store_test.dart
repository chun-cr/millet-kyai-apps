import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/profile/data/stores/profile_address_store.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';

void main() {
  test(
    'address store keeps one default address and persists updates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProfileAddressStore();

      final firstResult = await store.upsertAddress(
        const ProfileShippingAddressEntity(
          id: 'addr-1',
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
          isDefault: false,
        ),
      );
      expect(firstResult, hasLength(1));
      expect(firstResult.single.isDefault, isTrue);

      final secondResult = await store.upsertAddress(
        const ProfileShippingAddressEntity(
          id: 'addr-2',
          receiverName: 'Lee',
          receiverMobile: '13912345678',
          provinceCode: '310000',
          provinceName: 'Shanghai',
          cityCode: '310100',
          cityName: 'Shanghai',
          districtCode: '310115',
          districtName: 'Pudong',
          streetCode: '310115010',
          streetName: 'Lujiazui',
          detailAddress: 'Tower 9, Room 702',
          isDefault: true,
        ),
      );
      expect(secondResult, hasLength(2));
      expect(
        secondResult.firstWhere((item) => item.id == 'addr-2').isDefault,
        isTrue,
      );
      expect(
        secondResult.firstWhere((item) => item.id == 'addr-1').isDefault,
        isFalse,
      );

      final afterDelete = await store.deleteAddress('addr-2');
      expect(afterDelete, hasLength(1));
      expect(afterDelete.single.id, 'addr-1');
      expect(afterDelete.single.isDefault, isTrue);
    },
  );

  test('replaceAll normalizes remote cache and persists addresses', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProfileAddressStore();

    final replaced = await store.replaceAll([
      const ProfileShippingAddressEntity(
        id: 'addr-10',
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
        isDefault: false,
      ),
      const ProfileShippingAddressEntity(
        id: 'addr-11',
        receiverName: 'Lee',
        receiverMobile: '13912345678',
        provinceCode: '110000',
        provinceName: 'Beijing',
        cityCode: '110100',
        cityName: 'Beijing',
        districtCode: '110105',
        districtName: 'Chaoyang',
        streetCode: '110105001',
        streetName: 'Jianguomenwai',
        detailAddress: 'Tower 3, Room 901',
        isDefault: true,
      ),
    ]);

    expect(replaced, hasLength(2));
    expect(
      replaced.firstWhere((item) => item.id == 'addr-11').isDefault,
      isTrue,
    );
    expect(
      replaced.firstWhere((item) => item.id == 'addr-10').isDefault,
      isFalse,
    );

    final loaded = await store.loadAddresses();
    expect(loaded, hasLength(2));
    expect(loaded.firstWhere((item) => item.id == 'addr-11').isDefault, isTrue);
  });
}
