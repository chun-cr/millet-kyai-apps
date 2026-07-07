part of '../shipping_address_page.dart';

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.initial, required this.forceDefault});

  final ProfileShippingAddressEntity? initial;
  final bool forceDefault;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet>
    with _AddressEditorSheetView {
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
}
