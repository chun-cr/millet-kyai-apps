// 个人中心模块页面：`ShippingAddressPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_address_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/widgets/profile_loading_skeletons.dart';

const _kAddressPageBg = Color(0xFFF9FCF7);
const _kAddressCardBg = Colors.white;
const _kAddressPrimary = Color(0xFF2D6A4F);
const _kAddressTextPrimary = Color(0xFF1E1810);
const _kAddressTextSecondary = Color(0xFF7A6F63);
const _kAddressDivider = Color(0xFFF0EDE5);
const _kAddressNavBorder = Color(0xFFE6ECE3);
const _kAddressGlowMint = Color(0xFFE7F8E8);
const _kAddressGlowGreen = Color(0xFFD9F2DE);
const _kAddressButtonStart = Color(0xFF8EDC9D);
const _kAddressButtonEnd = Color(0xFF9AE1B6);
const _kAddressIllustration = Color(0xFF8BCF9A);
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 28,
            color: Color(0xFF6B6E67),
          ),
        ),
        title: Text(
          context.l10n.profileAddressTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kAddressTextPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kAddressNavBorder),
        ),
      ),
      floatingActionButton: showEmptyState
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _kAddressPrimary,
              foregroundColor: Colors.white,
              onPressed: () =>
                  _openEditor(context, ref, forceDefault: addresses.isEmpty),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(context.l10n.profileAddressAdd),
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
            colors: [Color(0xFFFBFDF9), Color(0xFFF7FBF5), Color(0xFFF9FCF8)],
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: addresses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
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

class _AddressEmptyState extends StatelessWidget {
  const _AddressEmptyState({
    required this.onRefresh,
    required this.title,
    required this.body,
  });

  final Future<void> Function() onRefresh;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            const Positioned.fill(child: _AddressAtmosphere()),
            RefreshIndicator(
              onRefresh: onRefresh,
              color: _kAddressPrimary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
                      child: Column(
                        children: [
                          const SizedBox(height: 96),
                          const _ShippingAddressIllustration(),
                          const SizedBox(height: 42),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              height: 1.15,
                              fontWeight: FontWeight.w500,
                              color: _kAddressTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF4D534D),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddressAtmosphere extends StatelessWidget {
  const _AddressAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            left: -84,
            top: 62,
            child: _AddressGlowOrb(
              size: 250,
              startColor: _kAddressGlowMint,
              endColor: Color(0x00E7F8E8),
            ),
          ),
          Positioned(
            right: -88,
            top: 132,
            child: _AddressGlowOrb(
              size: 286,
              startColor: _kAddressGlowGreen,
              endColor: Color(0x00D9F2DE),
            ),
          ),
          Positioned(
            left: 34,
            top: 344,
            child: _AddressGlowOrb(
              size: 196,
              startColor: _kAddressGlowMint,
              endColor: Color(0x00E7F8E8),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 164,
            child: _AddressGlowOrb(
              size: 172,
              startColor: _kAddressGlowGreen,
              endColor: Color(0x00D9F2DE),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressGlowOrb extends StatelessWidget {
  const _AddressGlowOrb({
    required this.size,
    required this.startColor,
    required this.endColor,
  });

  final double size;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [startColor, endColor]),
      ),
    );
  }
}

class _ShippingAddressIllustration extends StatefulWidget {
  const _ShippingAddressIllustration();

  @override
  State<_ShippingAddressIllustration> createState() =>
      _ShippingAddressIllustrationState();
}

class _ShippingAddressIllustrationState
    extends State<_ShippingAddressIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(
      begin: 8,
      end: -6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1.015,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: SizedBox(
        width: 252,
        height: 248,
        child: CustomPaint(
          painter: _ShippingAddressIllustrationPainter(
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _ShippingAddressIllustrationPainter extends CustomPainter {
  const _ShippingAddressIllustrationPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.5 - (progress - 0.5).abs();
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..color = _kAddressIllustration.withValues(alpha: 0.88);

    fillPaint.color = _kAddressIllustration.withValues(
      alpha: 0.10 + (pulse * 0.08),
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 - 12),
      72 + (pulse * 4),
      fillPaint,
    );

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kAddressIllustration.withValues(alpha: 0.14 + (pulse * 0.12));
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 - 12),
      78 + (pulse * 10),
      haloPaint,
    );

    final pinPath = Path()
      ..moveTo(size.width / 2, size.height - 10)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.67,
        size.width * 0.12,
        size.height * 0.47,
        size.width * 0.12,
        size.height * 0.29,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.10,
        size.width * 0.28,
        0,
        size.width / 2,
        0,
      )
      ..cubicTo(
        size.width * 0.72,
        0,
        size.width * 0.88,
        size.height * 0.10,
        size.width * 0.88,
        size.height * 0.29,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.47,
        size.width * 0.69,
        size.height * 0.67,
        size.width / 2,
        size.height - 10,
      )
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.24),
    );
    canvas.drawPath(pinPath, strokePaint);

    final innerCenter = Offset(size.width / 2, size.height * 0.31);
    canvas.drawCircle(
      innerCenter,
      54,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.26),
    );
    canvas.drawCircle(innerCenter, 54, strokePaint);

    final housePath = Path()
      ..moveTo(innerCenter.dx - 30, innerCenter.dy - 2)
      ..lineTo(innerCenter.dx, innerCenter.dy - 30)
      ..lineTo(innerCenter.dx + 30, innerCenter.dy - 2)
      ..lineTo(innerCenter.dx + 21, innerCenter.dy - 2)
      ..lineTo(innerCenter.dx + 21, innerCenter.dy + 26)
      ..lineTo(innerCenter.dx + 8, innerCenter.dy + 26)
      ..lineTo(innerCenter.dx + 8, innerCenter.dy + 8)
      ..lineTo(innerCenter.dx - 8, innerCenter.dy + 8)
      ..lineTo(innerCenter.dx - 8, innerCenter.dy + 26)
      ..lineTo(innerCenter.dx - 21, innerCenter.dy + 26)
      ..lineTo(innerCenter.dx - 21, innerCenter.dy - 2)
      ..close();

    canvas.drawPath(
      housePath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            _kAddressIllustration.withValues(alpha: 0.22 + (pulse * 0.08)),
            _kAddressIllustration.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromCircle(center: innerCenter, radius: 48)),
    );
    canvas.drawPath(
      housePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4
        ..color = _kAddressIllustration.withValues(alpha: 0.82),
    );
  }

  @override
  bool shouldRepaint(
    covariant _ShippingAddressIllustrationPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

class _AddressEmptyBottomBar extends StatelessWidget {
  const _AddressEmptyBottomBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_kAddressButtonStart, _kAddressButtonEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: _kAddressPrimary.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final ProfileShippingAddressEntity address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAddressCardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kAddressPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      address.receiverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kAddressTextPrimary,
                      ),
                    ),
                    Text(
                      address.receiverMobile,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kAddressTextSecondary,
                      ),
                    ),
                    if (address.isDefault)
                      _AddressBadge(
                        label: context.l10n.profileAddressDefault,
                        backgroundColor: _kAddressPrimary.withValues(
                          alpha: 0.10,
                        ),
                        textColor: _kAddressPrimary,
                      ),
                    if ((address.streetName ?? '').trim().isNotEmpty)
                      _AddressBadge(
                        label: address.streetName!.trim(),
                        backgroundColor: const Color(
                          0xFFC9A84C,
                        ).withValues(alpha: 0.12),
                        textColor: const Color(0xFF8A6F3C),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _kAddressTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kAddressDivider),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onSetDefault != null)
                OutlinedButton(
                  onPressed: onSetDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAddressPrimary,
                    side: BorderSide(
                      color: _kAddressPrimary.withValues(alpha: 0.28),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.l10n.profileAddressSetDefault),
                ),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAddressTextPrimary,
                  side: const BorderSide(color: _kAddressDivider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.l10n.profileAddressEdit),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB04C37),
                ),
                child: Text(context.l10n.profileAddressDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressBadge extends StatelessWidget {
  const _AddressBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.initial, required this.forceDefault});

  final ProfileShippingAddressEntity? initial;
  final bool forceDefault;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _receiverController;
  late final TextEditingController _phoneController;
  late final TextEditingController _provinceNameController;
  late final TextEditingController _provinceCodeController;
  late final TextEditingController _cityNameController;
  late final TextEditingController _cityCodeController;
  late final TextEditingController _districtNameController;
  late final TextEditingController _districtCodeController;
  late final TextEditingController _streetNameController;
  late final TextEditingController _streetCodeController;
  late final TextEditingController _detailController;
  late final TextEditingController _doorplateController;
  late bool _isDefault;
  late bool _showRegionFields;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _receiverController = TextEditingController(
      text: initial?.receiverName ?? '',
    );
    _phoneController = TextEditingController(
      text: initial?.receiverMobile ?? '',
    );
    _provinceNameController = TextEditingController(
      text: initial?.provinceName ?? '',
    );
    _provinceCodeController = TextEditingController(
      text: initial?.provinceCode ?? '',
    );
    _cityNameController = TextEditingController(text: initial?.cityName ?? '');
    _cityCodeController = TextEditingController(text: initial?.cityCode ?? '');
    _districtNameController = TextEditingController(
      text: initial?.districtName ?? '',
    );
    _districtCodeController = TextEditingController(
      text: initial?.districtCode ?? '',
    );
    _streetNameController = TextEditingController(
      text: initial?.streetName ?? '',
    );
    _streetCodeController = TextEditingController(
      text: initial?.streetCode ?? '',
    );
    _detailController = TextEditingController(
      text: initial?.detailAddress ?? '',
    );
    _doorplateController = TextEditingController();
    _isDefault = initial?.isDefault ?? widget.forceDefault;
    _showRegionFields = widget.initial == null;
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _phoneController.dispose();
    _provinceNameController.dispose();
    _provinceCodeController.dispose();
    _cityNameController.dispose();
    _cityCodeController.dispose();
    _districtNameController.dispose();
    _districtCodeController.dispose();
    _streetNameController.dispose();
    _streetCodeController.dispose();
    _detailController.dispose();
    _doorplateController.dispose();
    super.dispose();
  }

  String _textOf(TextEditingController controller) => controller.text.trim();

  String _languageCode(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  String _regionPlaceholder(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Select province / city / district';
      case 'ja':
        return '都道府県・市区町村・地域を入力';
      case 'ko':
        return '시/도 · 시 · 구를 입력해 주세요';
      default:
        return '请选择省 / 市 / 区';
    }
  }

  String _detailPlaceholder(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Enter street, building, and more';
      case 'ja':
        return '通り名・建物名などを入力';
      case 'ko':
        return '도로명, 건물명 등을 입력해 주세요';
      default:
        return '请填写街道、小区、写字楼等';
    }
  }

  String _doorplateLabel(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Doorplate';
      case 'ja':
        return '部屋番号';
      case 'ko':
        return '상세 호수';
      default:
        return '门牌号';
    }
  }

  String _doorplateHint(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Enter unit, floor, and door number';
      case 'ja':
        return '号室・階数・部屋番号を入力';
      case 'ko':
        return '동, 층, 호수를 입력해 주세요';
      default:
        return '请填写单元、楼层、门牌号';
    }
  }

  String _doorplateHelper(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Include the door number for easier delivery';
      case 'ja':
        return '部屋番号まで入力してください';
      case 'ko':
        return '상세 호수까지 입력해 주세요';
      default:
        return '记得完善门牌号~';
    }
  }

  String _useThisAddressLabel(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Use this address';
      case 'ja':
        return 'この住所を使う';
      case 'ko':
        return '이 주소 사용';
      default:
        return '使用该地址';
    }
  }

  String _currentLocationLabel(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Current location';
      case 'ja':
        return '現在地';
      case 'ko':
        return '현재 위치';
      default:
        return '当前位置';
    }
  }

  String _quickFillLabel(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Paste shipping info for quick fill';
      case 'ja':
        return 'お届け先情報を貼り付けてすばやく入力';
      case 'ko':
        return '배송 정보를 붙여 빠르게 입력';
      default:
        return '粘贴收货信息，快速填写';
    }
  }

  String _privacyNotice(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Location access may be requested to fill your area. For details on use or revocation, see ';
      case 'ja':
        return '地域を補完する際は位置情報へのアクセスが必要になる場合があります。利用方法や許可の停止については';
      case 'ko':
        return '현재 지역을 채우려면 위치 권한이 필요할 수 있습니다. 권한 사용 및 해제 방법은 ';
      default:
        return '当您需要定位至所在地区时，系统需要申请访问位置权限。关于该权限如何使用及停止授权等内容，您可阅读';
    }
  }

  String _privacyPolicy(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Location Privacy Policy';
      case 'ja':
        return '位置情報プライバシーポリシー';
      case 'ko':
        return '위치정보 개인정보처리방침';
      default:
        return '《位置信息隐私政策》';
    }
  }

  String _saveAddressLabel(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Save address';
      case 'ja':
        return '住所を保存';
      case 'ko':
        return '주소 저장';
      default:
        return '保存地址';
    }
  }

  String _receiverPlaceholder(BuildContext context) {
    switch (_languageCode(context)) {
      case 'en':
        return 'Enter contact name';
      case 'ja':
        return '受取人名を入力';
      case 'ko':
        return '연락처 이름을 입력해 주세요';
      default:
        return '请输入联系人姓名';
    }
  }

  String _regionSummary(BuildContext context) {
    final parts = [
      _textOf(_provinceNameController),
      _textOf(_cityNameController),
      _textOf(_districtNameController),
    ].where((item) => item.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) {
      return _regionPlaceholder(context);
    }
    return parts.join('  ');
  }

  String _locationTitle(BuildContext context) {
    final doorplate = _textOf(_doorplateController);
    if (doorplate.isNotEmpty) {
      return doorplate;
    }
    final detail = _textOf(_detailController);
    if (detail.isNotEmpty) {
      return detail;
    }
    return _regionSummary(context);
  }

  String _locationSubtitle(BuildContext context) {
    final parts = [
      _regionSummary(context) == _regionPlaceholder(context)
          ? ''
          : _regionSummary(context),
      _textOf(_detailController),
      _textOf(_doorplateController),
    ].where((item) => item.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) {
      return _detailPlaceholder(context);
    }
    return parts.join(' ');
  }

  String _buildFinalDetailAddress() {
    final detail = _textOf(_detailController);
    final doorplate = _textOf(_doorplateController);
    if (detail.isEmpty) {
      return doorplate;
    }
    if (doorplate.isEmpty) {
      return detail;
    }
    if (detail.contains(doorplate)) {
      return detail;
    }
    return '$detail $doorplate';
  }

  bool _validateRegionBeforeSubmit() {
    final requiredValues = [
      _textOf(_provinceNameController),
      _textOf(_provinceCodeController),
      _textOf(_cityNameController),
      _textOf(_cityCodeController),
      _textOf(_districtNameController),
      _textOf(_districtCodeController),
    ];
    if (requiredValues.any((item) => item.isEmpty)) {
      setState(() => _showRegionFields = true);
      return false;
    }

    final codeErrors = [
      _validateCode(
        _provinceCodeController.text,
        context.l10n.profileAddressValidationProvinceCode,
      ),
      _validateCode(
        _cityCodeController.text,
        context.l10n.profileAddressValidationCityCode,
      ),
      _validateCode(
        _districtCodeController.text,
        context.l10n.profileAddressValidationDistrictCode,
      ),
      _validateStreetCode(_streetCodeController.text),
      _validateStreetName(_streetNameController.text),
    ];

    if (codeErrors.any((item) => item != null)) {
      setState(() => _showRegionFields = true);
      return false;
    }
    return true;
  }

  void _applySuggestedAddress() {
    final subtitle = _locationSubtitle(context);
    if (_textOf(_detailController).isEmpty &&
        subtitle != _detailPlaceholder(context)) {
      _detailController.text = subtitle;
      setState(() {});
    }
  }

  void _submit() {
    if (!_validateRegionBeforeSubmit()) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ProfileShippingAddressEntity(
        id: widget.initial?.id ?? '',
        receiverName: _receiverController.text.trim(),
        receiverMobile: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        provinceCode: _provinceCodeController.text.trim(),
        provinceName: _provinceNameController.text.trim(),
        cityCode: _cityCodeController.text.trim(),
        cityName: _cityNameController.text.trim(),
        districtCode: _districtCodeController.text.trim(),
        districtName: _districtNameController.text.trim(),
        streetCode: _streetCodeController.text.trim(),
        streetName: _streetNameController.text.trim(),
        detailAddress: _buildFinalDetailAddress(),
        isDefault: widget.forceDefault ? true : _isDefault,
      ),
    );
  }

  String? _validateRequiredText(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (!_addressPhoneDigitsRegExp.hasMatch(normalized)) {
      return context.l10n.profileAddressValidationPhone;
    }
    return null;
  }

  String? _validateCode(String? value, String emptyError) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return emptyError;
    }
    if (!_addressCodeRegExp.hasMatch(trimmed)) {
      return context.l10n.profileAddressValidationCodeFormat;
    }
    return null;
  }

  String? _validateStreetName(String? value) {
    final name = value?.trim() ?? '';
    final code = _streetCodeController.text.trim();
    if (name.isEmpty && code.isEmpty) {
      return null;
    }
    if (name.isEmpty || code.isEmpty) {
      return context.l10n.profileAddressValidationStreetPair;
    }
    return null;
  }

  String? _validateStreetCode(String? value) {
    final code = value?.trim() ?? '';
    final name = _streetNameController.text.trim();
    if (name.isEmpty && code.isEmpty) {
      return null;
    }
    if (name.isEmpty || code.isEmpty) {
      return context.l10n.profileAddressValidationStreetPair;
    }
    if (!_addressCodeRegExp.hasMatch(code)) {
      return context.l10n.profileAddressValidationCodeFormat;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final regionListenables = Listenable.merge([
      _provinceNameController,
      _cityNameController,
      _districtNameController,
      _streetNameController,
      _detailController,
      _doorplateController,
    ]);

    return SizedBox(
      height: MediaQuery.of(context).size.height - 8,
      child: Material(
        color: const Color(0xFFF6F6F6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    Text(
                      widget.initial == null
                          ? context.l10n.profileAddressFormAddTitle
                          : context.l10n.profileAddressFormEditTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_border_rounded,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            '4.6',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF1A1A1A),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.radio_button_checked,
                              size: 12,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _showRegionFields = !_showRegionFields,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                18,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      context.l10n.profileAddressRegion,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF161616),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AnimatedBuilder(
                                      animation: regionListenables,
                                      builder: (context, _) {
                                        return Text(
                                          _regionSummary(context),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.45,
                                            color:
                                                _regionSummary(context) ==
                                                    _regionPlaceholder(context)
                                                ? const Color(0xFFBEBEBE)
                                                : const Color(0xFF222222),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    _showRegionFields
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.chevron_right_rounded,
                                    size: 26,
                                    color: const Color(0xFF1C1C1C),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 220),
                            crossFadeState: _showRegionFields
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                              child: Column(
                                children: [
                                  _AddressFieldRow(
                                    left: _AddressField(
                                      controller: _provinceNameController,
                                      label: context
                                          .l10n
                                          .profileAddressProvinceName,
                                      validator: (value) => _validateRequiredText(
                                        value,
                                        context
                                            .l10n
                                            .profileAddressValidationProvinceName,
                                      ),
                                    ),
                                    right: _AddressField(
                                      controller: _provinceCodeController,
                                      label: context
                                          .l10n
                                          .profileAddressProvinceCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: (value) => _validateCode(
                                        value,
                                        context
                                            .l10n
                                            .profileAddressValidationProvinceCode,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _AddressFieldRow(
                                    left: _AddressField(
                                      controller: _cityNameController,
                                      label:
                                          context.l10n.profileAddressCityName,
                                      validator: (value) => _validateRequiredText(
                                        value,
                                        context
                                            .l10n
                                            .profileAddressValidationCityName,
                                      ),
                                    ),
                                    right: _AddressField(
                                      controller: _cityCodeController,
                                      label:
                                          context.l10n.profileAddressCityCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: (value) => _validateCode(
                                        value,
                                        context
                                            .l10n
                                            .profileAddressValidationCityCode,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _AddressFieldRow(
                                    left: _AddressField(
                                      controller: _districtNameController,
                                      label: context
                                          .l10n
                                          .profileAddressDistrictName,
                                      validator: (value) => _validateRequiredText(
                                        value,
                                        context
                                            .l10n
                                            .profileAddressValidationDistrictName,
                                      ),
                                    ),
                                    right: _AddressField(
                                      controller: _districtCodeController,
                                      label: context
                                          .l10n
                                          .profileAddressDistrictCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: (value) => _validateCode(
                                        value,
                                        context
                                            .l10n
                                            .profileAddressValidationDistrictCode,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _AddressFieldRow(
                                    left: _AddressField(
                                      controller: _streetNameController,
                                      label:
                                          context.l10n.profileAddressStreetName,
                                      validator: _validateStreetName,
                                    ),
                                    right: _AddressField(
                                      controller: _streetCodeController,
                                      label:
                                          context.l10n.profileAddressStreetCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: _validateStreetCode,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondChild: const SizedBox.shrink(),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F1F1)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    context.l10n.profileAddressDetail,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF161616),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _detailController,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.45,
                                      color: Color(0xFF222222),
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: _detailPlaceholder(context),
                                      hintStyle: const TextStyle(
                                        fontSize: 15,
                                        height: 1.45,
                                        color: Color(0xFFBEBEBE),
                                      ),
                                    ),
                                    validator: (value) => _validateRequiredText(
                                      value,
                                      context
                                          .l10n
                                          .profileAddressValidationDetail,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 22,
                                    color: Color(0xFF141414),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            child: AnimatedBuilder(
                              animation: regionListenables,
                              builder: (context, _) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF2F5FF),
                                        Color(0xFFEAF8FF),
                                        Color(0xFFE7F8F4),
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: -28,
                                        top: 18,
                                        child: Container(
                                          width: 110,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: -12,
                                        top: -8,
                                        child: Container(
                                          width: 92,
                                          height: 92,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(
                                              0xFF7CE5D4,
                                            ).withValues(alpha: 0.18),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          18,
                                          18,
                                          18,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${_currentLocationLabel(context)}: ${_locationTitle(context)}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF111111),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    _locationSubtitle(context),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF8A8A8A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            OutlinedButton(
                                              onPressed: _applySuggestedAddress,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF1E1E1E,
                                                ),
                                                side: BorderSide(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.25),
                                                ),
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.28),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                              ),
                                              child: Text(
                                                _useThisAddressLabel(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F1F1)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    _doorplateLabel(context),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF161616),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _doorplateController,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.45,
                                          color: Color(0xFF222222),
                                        ),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          border: InputBorder.none,
                                          hintText: _doorplateHint(context),
                                          hintStyle: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFFCACACA),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _doorplateHelper(context),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFD7B554),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F1F1)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    context.l10n.profileAddressReceiver,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF161616),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _receiverController,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF222222),
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: _receiverPlaceholder(context),
                                      hintStyle: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFFCACACA),
                                      ),
                                    ),
                                    validator: (value) => _validateRequiredText(
                                      value,
                                      context
                                          .l10n
                                          .profileAddressValidationReceiver,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F1F1)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    context.l10n.profileAddressPhone,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF161616),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      _addressPhoneInputFormatter,
                                    ],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF222222),
                                    ),
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: '13782904156',
                                      hintStyle: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFFCACACA),
                                      ),
                                    ),
                                    validator: _validatePhone,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!widget.forceDefault)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 4, 10, 0),
                              child: Row(
                                children: [
                                  const SizedBox(width: 86),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            context
                                                .l10n
                                                .profileAddressDefaultToggle,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF8D8D8D),
                                            ),
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: _isDefault,
                                          activeThumbColor: const Color(
                                            0xFFFF2844,
                                          ),
                                          activeTrackColor: const Color(
                                            0xFFFF2844,
                                          ).withValues(alpha: 0.35),
                                          onChanged: (value) => setState(
                                            () => _isDefault = value,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _quickFillLabel(context),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFA0A0A0),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Color(0xFFA0A0A0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  bottomInset > 0 ? bottomInset + 12 : 18,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: Color(0xFFA7A7A7),
                          ),
                          children: [
                            TextSpan(text: _privacyNotice(context)),
                            TextSpan(
                              text: _privacyPolicy(context),
                              style: const TextStyle(color: Color(0xFF6CAED7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1535),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(_saveAddressLabel(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressFieldRow extends StatelessWidget {
  const _AddressFieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.validator,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F5F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kAddressPrimary),
        ),
      ),
    );
  }
}
