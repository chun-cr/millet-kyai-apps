part of '../shipping_address_page.dart';

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
    final actionTextStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: _kAddressCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAddressNavBorder.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: _kAddressPrimary.withValues(alpha: 0.055),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kAddressPrimarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  size: 22,
                  color: _kAddressPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            address.receiverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _kAddressTextPrimary,
                            ),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          _AddressBadge(
                            label: context.l10n.profileAddressDefault,
                            backgroundColor: _kAddressPrimarySoft,
                            textColor: _kAddressPrimary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.receiverMobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kAddressTextSecondary,
                      ),
                    ),
                    if ((address.streetName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _AddressBadge(
                        label: address.streetName!.trim(),
                        backgroundColor: _kAddressGold.withValues(alpha: 0.12),
                        textColor: const Color(0xFF8A6F3C),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _kAddressPageBgLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kAddressDivider),
            ),
            child: Text(
              address.fullAddress,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                color: _kAddressTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kAddressDivider),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onSetDefault != null)
                TDButton(
                  text: context.l10n.profileAddressSetDefault,
                  size: TDButtonSize.small,
                  type: TDButtonType.text,
                  icon: Icons.check_circle_outline_rounded,
                  iconTextSpacing: 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  style: TDButtonStyle(
                    backgroundColor: _kAddressPrimarySoft,
                    frameColor: Colors.transparent,
                    frameWidth: 0,
                    textColor: _kAddressPrimary,
                    radius: BorderRadius.circular(12),
                  ),
                  activeStyle: TDButtonStyle(
                    backgroundColor: _kAddressPrimary.withValues(alpha: 0.12),
                    frameColor: Colors.transparent,
                    frameWidth: 0,
                    textColor: _kAddressPrimary,
                    radius: BorderRadius.circular(12),
                  ),
                  textStyle: actionTextStyle,
                  onTap: onSetDefault,
                ),
              TDButton(
                text: context.l10n.profileAddressEdit,
                size: TDButtonSize.small,
                type: TDButtonType.text,
                icon: Icons.edit_location_alt_outlined,
                iconTextSpacing: 4,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                style: TDButtonStyle(
                  backgroundColor: Colors.transparent,
                  frameColor: Colors.transparent,
                  frameWidth: 0,
                  textColor: _kAddressTextSecondary,
                  radius: BorderRadius.circular(12),
                ),
                activeStyle: TDButtonStyle(
                  backgroundColor: _kAddressDivider.withValues(alpha: 0.45),
                  frameColor: Colors.transparent,
                  frameWidth: 0,
                  textColor: _kAddressTextPrimary,
                  radius: BorderRadius.circular(12),
                ),
                textStyle: actionTextStyle,
                onTap: onEdit,
              ),
              TDButton(
                text: context.l10n.profileAddressDelete,
                size: TDButtonSize.small,
                type: TDButtonType.text,
                icon: Icons.delete_outline_rounded,
                iconTextSpacing: 4,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                style: TDButtonStyle(
                  backgroundColor: Colors.transparent,
                  frameColor: Colors.transparent,
                  frameWidth: 0,
                  textColor: _kAddressDanger,
                  radius: BorderRadius.circular(12),
                ),
                activeStyle: TDButtonStyle(
                  backgroundColor: _kAddressDanger.withValues(alpha: 0.08),
                  frameColor: Colors.transparent,
                  frameWidth: 0,
                  textColor: _kAddressDanger,
                  radius: BorderRadius.circular(12),
                ),
                textStyle: actionTextStyle,
                onTap: onDelete,
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
    return TDTag(
      label,
      size: TDTagSize.small,
      shape: TDTagShape.round,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontWeight: FontWeight.w700,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    );
  }
}
