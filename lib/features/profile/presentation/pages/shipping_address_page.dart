// 个人中心模块页面：`ShippingAddressPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_address_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/widgets/profile_loading_skeletons.dart';

part 'shipping_address/shipping_address_empty_state.dart';
part 'shipping_address/shipping_address_card.dart';
part 'shipping_address/shipping_address_editor_sheet.dart';
part 'shipping_address/shipping_address_editor_view.dart';

const _kAddressPageBg = Color(0xFFF6F2EA);
const _kAddressPageBgLight = Color(0xFFFBF8F2);
const _kAddressCardBg = Color(0xFFFFFDFC);
const _kAddressPrimary = Color(0xFF2D6A4F);
const _kAddressPrimarySoft = Color(0xFFEAF5EE);
const _kAddressGold = Color(0xFFC9A84C);
const _kAddressTextPrimary = Color(0xFF1E1810);
const _kAddressTextSecondary = Color(0xFF5F554B);
const _kAddressTextHint = Color(0xFF9A8D7E);
const _kAddressDivider = Color(0xFFECE3D8);
const _kAddressNavBorder = Color(0xFFE8E1D6);
const _kAddressDanger = Color(0xFFB85C4A);
const _kAddressFieldBg = Color(0xFFFBF7F0);
final _addressCodeRegExp = RegExp(r'^[A-Za-z0-9_-]+$');
final _addressPhoneDigitsRegExp = RegExp(r'^[0-9]{6,20}$');
final _addressCodeInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[A-Za-z0-9_-]'),
);
final _addressPhoneInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9+\-\s()]'),
);

class ShippingAddressPage extends ConsumerWidget {
  const ShippingAddressPage({super.key});

  void _showErrorToast(BuildContext context, String message) {
    showAppToast(context, message);
  }

  Future<void> _refreshAddresses(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileAddressesProvider.notifier).refresh();
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorToast(context, context.l10n.profileAddressLoadFailed);
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ProfileShippingAddressEntity? initial,
    required bool forceDefault,
  }) async {
    var editorInitial = initial;
    if (initial != null && initial.id.isNotEmpty) {
      try {
        editorInitial = await ref
            .read(profileAddressesProvider.notifier)
            .loadAddressDetail(initial.id);
      } on Object {
        if (context.mounted) {
          _showErrorToast(context, context.l10n.profileAddressLoadFailed);
        }
      }
    }
    if (!context.mounted) {
      return;
    }

    final result = await showModalBottomSheet<ProfileShippingAddressEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddressEditorSheet(
          initial: editorInitial,
          forceDefault: forceDefault,
        );
      },
    );
    if (result == null) {
      return;
    }
    try {
      await ref.read(profileAddressesProvider.notifier).upsertAddress(result);
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorToast(context, context.l10n.profileAddressSaveFailed);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProfileShippingAddressEntity address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.profileAddressDeleteTitle),
          content: Text(context.l10n.profileAddressDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.profileAddressDeleteAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(profileAddressesProvider.notifier)
          .deleteAddress(address.id);
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorToast(context, context.l10n.profileAddressDeleteFailed);
    }
  }

  Future<void> _setDefaultAddress(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(profileAddressesProvider.notifier).setDefaultAddress(id);
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorToast(context, context.l10n.profileAddressDefaultFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(profileAddressesProvider);
    final addresses = addressesAsync.asData?.value ?? const [];
    final showEmptyState = addressesAsync.hasValue && addresses.isEmpty;

    if (addressesAsync.isLoading && !addressesAsync.hasValue) {
      return const ShippingAddressLoadingSkeleton();
    }

    return Scaffold(
      backgroundColor: _kAddressPageBg,
      appBar: AppBar(
        backgroundColor: _kAddressPageBgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: _kAddressTextSecondary,
          ),
        ),
        title: Text(
          context.l10n.profileAddressTitle,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: _kAddressTextPrimary,
          ),
        ),
        actions: showEmptyState
            ? null
            : [
                IconButton(
                  tooltip: context.l10n.profileAddressAdd,
                  onPressed: () => _openEditor(
                    context,
                    ref,
                    forceDefault: addresses.isEmpty,
                  ),
                  icon: const Icon(
                    Icons.add_location_alt_outlined,
                    size: 25,
                    color: _kAddressPrimary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kAddressNavBorder),
        ),
      ),
      bottomNavigationBar: showEmptyState
          ? _AddressEmptyBottomBar(
              label: context.l10n.profileAddressAdd,
              onTap: () => _openEditor(context, ref, forceDefault: true),
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kAddressPageBgLight, _kAddressPageBg, _kAddressPageBg],
          ),
        ),
        child: addressesAsync.when(
          data: (addresses) {
            if (addresses.isEmpty) {
              return _AddressEmptyState(
                onRefresh: () => _refreshAddresses(context, ref),
                title: context.l10n.profileAddressEmptyTitle,
                body: context.l10n.profileAddressEmptyBody,
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refreshAddresses(context, ref),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: addresses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _AddressCard(
                    address: address,
                    onEdit: () => _openEditor(
                      context,
                      ref,
                      initial: address,
                      forceDefault: addresses.length == 1 && address.isDefault,
                    ),
                    onDelete: () => _confirmDelete(context, ref, address),
                    onSetDefault: address.isDefault
                        ? null
                        : () => _setDefaultAddress(context, ref, address.id),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.profileAddressLoadFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _kAddressTextSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _refreshAddresses(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kAddressPrimary,
                        side: const BorderSide(color: _kAddressNavBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
