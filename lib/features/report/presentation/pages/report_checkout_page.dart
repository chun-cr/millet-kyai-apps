// 报告模块页面：`ReportCheckoutPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';
import 'package:millet_kyai_apps/features/report/application/mock_product_checkout.dart';
import 'package:millet_kyai_apps/features/report/application/retail_checkout_service.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_product_detail_page.dart';

part 'report_checkout_widgets.dart';

class ReportCheckoutPage extends StatefulWidget {
  final ReportCheckoutArgs args;

  const ReportCheckoutPage({super.key, required this.args});

  @override
  State<ReportCheckoutPage> createState() => _ReportCheckoutPageState();
}

class _ReportCheckoutPageState extends State<ReportCheckoutPage> {
  late final TextEditingController _recipientController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final RetailCheckoutService _checkoutService;
  bool _isPreviewLoading = false;
  bool _isSubmitting = false;
  bool _isRefreshingStatus = false;
  RetailCheckoutPreview? _remotePreview;
  RetailCheckoutFlowResult? _flowResult;
  String? _checkoutError;
  String? _checkoutNotice;

  @override
  void initState() {
    super.initState();
    initInjector();
    _checkoutService = RetailCheckoutService(
      ReportRemoteSource(getIt<DioClient>()),
    );
    _recipientController = TextEditingController(text: '陈清和');
    _phoneController = TextEditingController(text: '13800001234');
    _addressController = TextEditingController(text: '上海市徐汇区漕溪北路 88 号 18 楼');
    _recipientController.addListener(_handleFieldChanged);
    _phoneController.addListener(_handleFieldChanged);
    _addressController.addListener(_handleFieldChanged);
    unawaited(_loadRemotePreview());
  }

  @override
  void dispose() {
    _recipientController.removeListener(_handleFieldChanged);
    _phoneController.removeListener(_handleFieldChanged);
    _addressController.removeListener(_handleFieldChanged);
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _recipientController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _backendUnavailableReason == null;
  }

  bool get _hasOrder => _flowResult != null;

  String? get _backendUnavailableReason {
    final product = widget.args.product;
    if (product.retailSalable == false) {
      return '当前 SKU 暂不可售，请返回选择其他商品。';
    }
    if (int.tryParse(product.storeId?.trim() ?? '') == null) {
      return '当前商品缺少后端门店 ID，暂不能提交真实订单。';
    }
    if (_checkoutSkuId.trim().isEmpty) {
      return '当前商品缺少后端 SKU ID，暂不能提交真实订单。';
    }
    return null;
  }

  String get _checkoutSkuId {
    return _firstNonEmpty([
      widget.args.product.retailSkuId,
      widget.args.product.detailId,
      widget.args.product.id,
    ]);
  }

  void _handleFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRemotePreview() async {
    final request = _buildCheckoutRequest();
    if (request == null) {
      if (mounted) {
        setState(() => _checkoutNotice = _backendUnavailableReason);
      }
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _checkoutError = null;
    });

    try {
      final preview = await _checkoutService.preview(request);
      if (!mounted) {
        return;
      }
      setState(() {
        _remotePreview = preview;
        _checkoutNotice = '已从后端生成订单预览。';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checkoutError = '订单预览接口暂不可用，当前显示本地估算金额。';
      });
    } finally {
      if (mounted) {
        setState(() => _isPreviewLoading = false);
      }
    }
  }

  Future<void> _submitOrder({required String paymentLabel}) async {
    final request = _buildCheckoutRequest();
    if (request == null) {
      final message = _backendUnavailableReason ?? '请先补全订单信息。';
      setState(() => _checkoutError = message);
      showAppToast(context, message, kind: AppToastKind.info);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _checkoutError = null;
    });

    try {
      final preview = await _checkoutService.preview(request);
      final flowResult = await _checkoutService.submitAndPreparePayment(
        request,
        preview: preview,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _remotePreview = preview;
        _flowResult = flowResult;
        _checkoutNotice = '$paymentLabel 预支付已创建，等待支付结果确认。';
      });
      showAppToast(context, '订单已提交，预支付信息已返回。', kind: AppToastKind.success);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = '后端订单提交失败：${_compactError(error)}';
      setState(() => _checkoutError = message);
      showAppToast(context, message, kind: AppToastKind.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _refreshPayStatus() async {
    final flow = _flowResult;
    final orderId = flow?.submittedOrder.orderId.trim() ?? '';
    if (flow == null || orderId.isEmpty) {
      return;
    }

    setState(() {
      _isRefreshingStatus = true;
      _checkoutError = null;
    });

    try {
      final payStatus = await _checkoutService.refreshPayStatus(orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _flowResult = RetailCheckoutFlowResult(
          preview: flow.preview,
          submittedOrder: flow.submittedOrder,
          orderDetail: flow.orderDetail,
          cashier: flow.cashier,
          prepay: flow.prepay,
          payStatus: payStatus,
        );
        _checkoutNotice = payStatus.isPaid ? '支付已确认。' : '支付状态已刷新。';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = '刷新支付状态失败：${_compactError(error)}';
      setState(() => _checkoutError = message);
      showAppToast(context, message, kind: AppToastKind.error);
    } finally {
      if (mounted) {
        setState(() => _isRefreshingStatus = false);
      }
    }
  }

  RetailCheckoutRequest? _buildCheckoutRequest() {
    final product = widget.args.product;
    final storeId = int.tryParse(product.storeId?.trim() ?? '');
    final skuId = _checkoutSkuId.trim();
    if (storeId == null || skuId.isEmpty || product.retailSalable == false) {
      return null;
    }

    return RetailCheckoutRequest(
      storeId: storeId,
      skuId: skuId,
      skuName: product.retailSkuName?.trim().isNotEmpty == true
          ? product.retailSkuName!.trim()
          : product.name,
      quantity: widget.args.quantity,
      unitPriceMinor: product.priceCents,
      deliveryType: 'EXPRESS',
      deliveryAddress: RetailCheckoutAddress(
        name: _recipientController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = widget.args.product;
    final fallbackPreview = buildMockOrderPreview(
      unitPriceCents: product.priceCents,
      quantity: widget.args.quantity,
    );
    final preview = _remotePreview;
    final orderAmountMinor =
        preview?.orderAmountMinor ?? fallbackPreview.subtotalCents;
    final discountAmountMinor = preview?.discountAmountMinor ?? 0;
    final payAmountMinor =
        preview?.payAmountMinor ?? fallbackPreview.totalCents;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.reportProductCheckoutTitle),
        actions: [
          IconButton(
            tooltip: '刷新订单预览',
            onPressed: _isPreviewLoading ? null : _loadRemotePreview,
            icon: _isPreviewLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(product.color),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ApplePayPlaceholder(
                enabled: !_isSubmitting && _canSubmit,
                title: l10n.reportProductCheckoutApplePayTitle,
                onTap: () => _submitOrder(
                  paymentLabel: l10n.reportProductCheckoutApplePayTitle,
                ),
              ),
              const SizedBox(height: 10),
              _GooglePayPlaceholder(
                enabled: !_isSubmitting && _canSubmit,
                title: l10n.reportProductCheckoutGooglePayTitle,
                onTap: () => _submitOrder(
                  paymentLabel: l10n.reportProductCheckoutGooglePayTitle,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: (!_canSubmit || _isSubmitting || _isRefreshingStatus)
                    ? null
                    : _hasOrder
                    ? _refreshPayStatus
                    : () => _submitOrder(paymentLabel: '后端收银台'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        product.color.withValues(
                          alpha:
                              (!_canSubmit ||
                                  _isSubmitting ||
                                  _isRefreshingStatus)
                              ? 0.45
                              : 0.86,
                        ),
                        product.color.withValues(
                          alpha:
                              (!_canSubmit ||
                                  _isSubmitting ||
                                  _isRefreshingStatus)
                              ? 0.45
                              : 1,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting || _isRefreshingStatus) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        _isSubmitting
                            ? l10n.reportProductCheckoutSubmitting
                            : _isRefreshingStatus
                            ? '正在确认支付状态'
                            : _hasOrder
                            ? '刷新支付状态'
                            : '提交真实订单',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_flowResult != null) ...[
            _OrderResultCard(
              productColor: product.color,
              flowResult: _flowResult!,
            ),
            const SizedBox(height: 16),
          ],
          if (_checkoutError != null || _checkoutNotice != null) ...[
            _CheckoutNoticeCard(
              color: _checkoutError == null
                  ? product.color
                  : const Color(0xFFB05A5A),
              icon: _checkoutError == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              message: _checkoutError ?? _checkoutNotice!,
            ),
            const SizedBox(height: 16),
          ],
          _CheckoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckoutSectionTitle(
                  title: l10n.reportProductCheckoutSectionAddress,
                  color: product.color,
                ),
                const SizedBox(height: 12),
                _CheckoutField(
                  label: l10n.reportProductCheckoutRecipient,
                  controller: _recipientController,
                ),
                const SizedBox(height: 12),
                _CheckoutField(
                  label: l10n.reportProductCheckoutPhone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _CheckoutField(
                  label: l10n.reportProductCheckoutAddress,
                  controller: _addressController,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckoutSectionTitle(
                  title: l10n.reportProductCheckoutOrderSummary,
                  color: product.color,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: product.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(product.icon, color: product.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.reportProductCheckoutQuantityLabel}: ${widget.args.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.62),
                            ),
                          ),
                          if (product.retailSpecText?.trim().isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 3),
                            Text(
                              product.retailSpecText!.trim(),
                              style: TextStyle(
                                fontSize: 11,
                                color: product.color.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      product.priceLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: product.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AmountRow(
                  label: l10n.reportProductCheckoutSubtotal,
                  value: formatPriceFromCents(orderAmountMinor),
                ),
                const SizedBox(height: 8),
                if (preview == null)
                  _AmountRow(
                    label: l10n.reportProductCheckoutShippingFee,
                    value: formatPriceFromCents(
                      fallbackPreview.shippingFeeCents,
                    ),
                  )
                else
                  _AmountRow(
                    label: '优惠',
                    value: '-${formatPriceFromCents(discountAmountMinor)}',
                  ),
                const SizedBox(height: 8),
                _AmountRow(
                  label: l10n.reportProductCheckoutServiceFee,
                  value: formatPriceFromCents(
                    preview == null ? fallbackPreview.serviceFeeCents : 0,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _AmountRow(
                  label: l10n.reportProductCheckoutTotal,
                  value: formatPriceFromCents(payAmountMinor),
                  emphasize: true,
                  color: product.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckoutSectionTitle(
                  title: l10n.reportProductCheckoutPaymentTitle,
                  color: product.color,
                ),
                const SizedBox(height: 12),
                if (_flowResult?.cashier?.payChannels.isNotEmpty == true) ...[
                  _PaymentChannelWrap(
                    color: product.color,
                    channels: _flowResult!.cashier!.payChannels,
                  ),
                  const SizedBox(height: 12),
                ],
                _PaymentMethodCard(
                  title: l10n.reportProductCheckoutApplePayTitle,
                  subtitle: '确认订单后创建预支付单，等待支付结果确认。',
                  icon: CupertinoIcons.creditcard_fill,
                  dark: true,
                ),
                const SizedBox(height: 10),
                _PaymentMethodCard(
                  title: l10n.reportProductCheckoutGooglePayTitle,
                  subtitle: '提交后同步收银台状态，支付后可刷新结果。',
                  icon: Icons.account_balance_wallet_rounded,
                  dark: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
