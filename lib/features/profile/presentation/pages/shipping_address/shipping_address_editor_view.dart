part of '../shipping_address_page.dart';

mixin _AddressEditorSheetView on State<_AddressEditorSheet> {
  _AddressEditorSheetState get _state => this as _AddressEditorSheetState;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final regionListenables = Listenable.merge([
      _state._provinceNameController,
      _state._cityNameController,
      _state._districtNameController,
      _state._streetNameController,
      _state._detailController,
      _state._doorplateController,
    ]);

    return SizedBox(
      height: MediaQuery.of(context).size.height - 8,
      child: Material(
        color: _kAddressPageBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _kAddressTextSecondary,
                        ),
                      ),
                    ),
                    Text(
                      widget.initial == null
                          ? context.l10n.profileAddressFormAddTitle
                          : context.l10n.profileAddressFormEditTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _kAddressTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                  child: Form(
                    key: _state._formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kAddressCardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _kAddressNavBorder),
                        boxShadow: [
                          BoxShadow(
                            color: _kAddressPrimary.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _state._showRegionFields =
                                  !_state._showRegionFields,
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
                                        color: _kAddressTextSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AnimatedBuilder(
                                      animation: regionListenables,
                                      builder: (context, _) {
                                        return Text(
                                          _state._regionSummary(context),
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.45,
                                            color:
                                                _state._regionSummary(
                                                      context,
                                                    ) ==
                                                    _state._regionPlaceholder(
                                                      context,
                                                    )
                                                ? _kAddressTextHint
                                                : _kAddressTextPrimary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    _state._showRegionFields
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.chevron_right_rounded,
                                    size: 26,
                                    color: _kAddressPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 220),
                            crossFadeState: _state._showRegionFields
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                              child: Column(
                                children: [
                                  _AddressFieldRow(
                                    left: _AddressField(
                                      controller:
                                          _state._provinceNameController,
                                      label: context
                                          .l10n
                                          .profileAddressProvinceName,
                                      validator: (value) =>
                                          _state._validateRequiredText(
                                            value,
                                            context
                                                .l10n
                                                .profileAddressValidationProvinceName,
                                          ),
                                    ),
                                    right: _AddressField(
                                      controller:
                                          _state._provinceCodeController,
                                      label: context
                                          .l10n
                                          .profileAddressProvinceCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: (value) => _state._validateCode(
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
                                      controller: _state._cityNameController,
                                      label:
                                          context.l10n.profileAddressCityName,
                                      validator: (value) =>
                                          _state._validateRequiredText(
                                            value,
                                            context
                                                .l10n
                                                .profileAddressValidationCityName,
                                          ),
                                    ),
                                    right: _AddressField(
                                      controller: _state._cityCodeController,
                                      label:
                                          context.l10n.profileAddressCityCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: (value) => _state._validateCode(
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
                                      controller:
                                          _state._districtNameController,
                                      label: context
                                          .l10n
                                          .profileAddressDistrictName,
                                      validator: (value) =>
                                          _state._validateRequiredText(
                                            value,
                                            context
                                                .l10n
                                                .profileAddressValidationDistrictName,
                                          ),
                                    ),
                                    right: _AddressField(
                                      controller:
                                          _state._districtCodeController,
                                      label: context
                                          .l10n
                                          .profileAddressDistrictCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: (value) => _state._validateCode(
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
                                      controller: _state._streetNameController,
                                      label:
                                          context.l10n.profileAddressStreetName,
                                      validator: _state._validateStreetName,
                                    ),
                                    right: _AddressField(
                                      controller: _state._streetCodeController,
                                      label:
                                          context.l10n.profileAddressStreetCode,
                                      inputFormatters: [
                                        _addressCodeInputFormatter,
                                      ],
                                      validator: _state._validateStreetCode,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondChild: const SizedBox.shrink(),
                          ),
                          const Divider(height: 1, color: _kAddressDivider),
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
                                      color: _kAddressTextSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _state._detailController,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.45,
                                      color: _kAddressTextPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: _state._detailPlaceholder(
                                        context,
                                      ),
                                      hintStyle: const TextStyle(
                                        fontSize: 15,
                                        height: 1.45,
                                        color: _kAddressTextHint,
                                      ),
                                    ),
                                    validator: (value) =>
                                        _state._validateRequiredText(
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
                                    color: _kAddressPrimary,
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
                                        _kAddressPrimarySoft,
                                        _kAddressPageBgLight,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: _kAddressPrimarySoft,
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
                                            color: _kAddressCardBg.withValues(
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
                                            color: _kAddressGold.withValues(
                                              alpha: 0.12,
                                            ),
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
                                                    '${_state._currentLocationLabel(context)}: ${_state._locationTitle(context)}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          _kAddressTextPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    _state._locationSubtitle(
                                                      context,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          _kAddressTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            TDButton(
                                              text: _state._useThisAddressLabel(
                                                context,
                                              ),
                                              size: TDButtonSize.small,
                                              type: TDButtonType.outline,
                                              shape: TDButtonShape.round,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                              style: TDButtonStyle(
                                                backgroundColor: _kAddressCardBg
                                                    .withValues(alpha: 0.62),
                                                frameColor: _kAddressPrimary
                                                    .withValues(alpha: 0.28),
                                                frameWidth: 1,
                                                textColor: _kAddressPrimary,
                                                radius: BorderRadius.circular(
                                                  999,
                                                ),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              onTap:
                                                  _state._applySuggestedAddress,
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
                          const Divider(height: 1, color: _kAddressDivider),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    _state._doorplateLabel(context),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _kAddressTextSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _state._doorplateController,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.45,
                                          color: _kAddressTextPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          border: InputBorder.none,
                                          hintText: _state._doorplateHint(
                                            context,
                                          ),
                                          hintStyle: const TextStyle(
                                            fontSize: 15,
                                            color: _kAddressTextHint,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _state._doorplateHelper(context),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8A6F3C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: _kAddressDivider),
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
                                      color: _kAddressTextSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _state._receiverController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: _kAddressTextPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: _state._receiverPlaceholder(
                                        context,
                                      ),
                                      hintStyle: const TextStyle(
                                        fontSize: 15,
                                        color: _kAddressTextHint,
                                      ),
                                    ),
                                    validator: (value) =>
                                        _state._validateRequiredText(
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
                          const Divider(height: 1, color: _kAddressDivider),
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
                                      color: _kAddressTextSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _state._phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      _addressPhoneInputFormatter,
                                    ],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: _kAddressTextPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: '+1 555 012 3456',
                                      hintStyle: TextStyle(
                                        fontSize: 15,
                                        color: _kAddressTextHint,
                                      ),
                                    ),
                                    validator: _state._validatePhone,
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
                                              color: _kAddressTextSecondary,
                                            ),
                                          ),
                                        ),
                                        TDSwitch(
                                          isOn: _state._isDefault,
                                          size: TDSwitchSize.medium,
                                          trackOnColor: _kAddressPrimary,
                                          trackOffColor: _kAddressDivider,
                                          onChanged: (value) {
                                            setState(
                                              () => _state._isDefault = value,
                                            );
                                            return true;
                                          },
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
                                  _state._quickFillLabel(context),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kAddressTextHint,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: _kAddressTextHint,
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
                  20,
                  6,
                  20,
                  bottomInset > 0 ? bottomInset + 12 : 20,
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
                            color: _kAddressTextHint,
                          ),
                          children: [
                            TextSpan(text: _state._privacyNotice(context)),
                            TextSpan(
                              text: _state._privacyPolicy(context),
                              style: const TextStyle(color: _kAddressPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TDButton(
                      text: _state._saveAddressLabel(context),
                      size: TDButtonSize.large,
                      width: double.infinity,
                      height: 56,
                      style: TDButtonStyle(
                        backgroundColor: _kAddressPrimary,
                        frameColor: _kAddressPrimary,
                        textColor: Colors.white,
                        radius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: _state._submit,
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
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (field) {
        final hasError = field.errorText != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kAddressTextSecondary,
              ),
            ),
            const SizedBox(height: 7),
            TDInput(
              controller: controller,
              hintText: label,
              inputFormatters: inputFormatters,
              showBottomDivider: false,
              needClear: false,
              cursorColor: _kAddressPrimary,
              backgroundColor: Colors.transparent,
              textStyle: const TextStyle(
                fontSize: 15,
                color: _kAddressTextPrimary,
              ),
              hintTextStyle: const TextStyle(
                fontSize: 15,
                color: _kAddressTextHint,
              ),
              inputDecoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: _kAddressFieldBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: hasError ? _kAddressDanger : _kAddressDivider,
                  width: hasError ? 1.2 : 1,
                ),
              ),
              onChanged: field.didChange,
            ),
            if (hasError) ...[
              const SizedBox(height: 5),
              Text(
                field.errorText!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: _kAddressDanger,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
