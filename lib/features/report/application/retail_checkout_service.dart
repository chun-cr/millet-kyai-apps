import 'package:flutter/foundation.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';

@immutable
class RetailCheckoutAddress {
  const RetailCheckoutAddress({
    required this.name,
    required this.phone,
    required this.address,
    this.province,
    this.city,
    this.county,
    this.town,
  });

  final String name;
  final String phone;
  final String address;
  final String? province;
  final String? city;
  final String? county;
  final String? town;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'province': province?.trim(),
      'city': city?.trim(),
      'county': county?.trim(),
      'town': town?.trim(),
      'address': address.trim(),
    }..removeWhere((_, value) {
      return value == null || (value is String && value.trim().isEmpty);
    });
  }
}

@immutable
class RetailCheckoutRequest {
  const RetailCheckoutRequest({
    required this.storeId,
    required this.skuId,
    required this.skuName,
    required this.quantity,
    required this.unitPriceMinor,
    required this.deliveryType,
    required this.deliveryAddress,
    this.employeeId,
    this.remark,
  });

  final int storeId;
  final String skuId;
  final String skuName;
  final int quantity;
  final int unitPriceMinor;
  final String deliveryType;
  final RetailCheckoutAddress deliveryAddress;
  final int? employeeId;
  final String? remark;

  List<Map<String, dynamic>> get itemPayload {
    return [
      {
        'skuId': skuId.trim(),
        'retailSkuId': skuId.trim(),
        'skuName': skuName.trim(),
        'quantity': quantity,
      }..removeWhere((_, value) {
        return value == null || (value is String && value.trim().isEmpty);
      }),
    ];
  }

  int get fallbackSubtotalMinor => unitPriceMinor * quantity;
}

@immutable
class RetailCheckoutPreview {
  const RetailCheckoutPreview({
    required this.orderAmountMinor,
    required this.discountAmountMinor,
    required this.payAmountMinor,
    required this.currencyCode,
    required this.items,
    required this.raw,
  });

  factory RetailCheckoutPreview.fromJson(
    Map<String, dynamic> json, {
    required RetailCheckoutRequest fallback,
  }) {
    final orderAmountMinor =
        _asInt(json['orderAmountMinor']) ?? fallback.fallbackSubtotalMinor;
    final discountAmountMinor = _asInt(json['discountAmountMinor']) ?? 0;
    final payAmountMinor =
        _asInt(json['payAmountMinor']) ??
        (orderAmountMinor - discountAmountMinor);
    final items = _asList(json['items'])
        .map((item) => RetailCheckoutItem.fromJson(_asMap(item)))
        .where((item) => item.skuName.trim().isNotEmpty)
        .toList(growable: false);

    return RetailCheckoutPreview(
      orderAmountMinor: orderAmountMinor,
      discountAmountMinor: discountAmountMinor,
      payAmountMinor: payAmountMinor,
      currencyCode: _firstText(json, const ['currencyCode']) ?? 'CNY',
      items: items,
      raw: Map<String, dynamic>.from(json),
    );
  }

  final int orderAmountMinor;
  final int discountAmountMinor;
  final int payAmountMinor;
  final String currencyCode;
  final List<RetailCheckoutItem> items;
  final Map<String, dynamic> raw;
}

@immutable
class RetailCheckoutItem {
  const RetailCheckoutItem({
    required this.skuId,
    required this.skuName,
    required this.quantity,
    required this.unitPriceMinor,
    required this.itemAmountMinor,
  });

  factory RetailCheckoutItem.fromJson(Map<String, dynamic> json) {
    return RetailCheckoutItem(
      skuId: _firstText(json, const ['skuId', 'retailSkuId']) ?? '',
      skuName: _firstText(json, const ['skuName', 'name']) ?? '',
      quantity: _asInt(json['quantity']) ?? 0,
      unitPriceMinor: _asInt(json['unitPriceMinor']) ?? 0,
      itemAmountMinor: _asInt(json['itemAmountMinor']) ?? 0,
    );
  }

  final String skuId;
  final String skuName;
  final int quantity;
  final int unitPriceMinor;
  final int itemAmountMinor;
}

@immutable
class RetailCheckoutSubmitResult {
  const RetailCheckoutSubmitResult({
    required this.orderId,
    required this.orderNo,
    required this.orderStatus,
    required this.paymentStatus,
    required this.payAmountMinor,
    required this.raw,
  });

  factory RetailCheckoutSubmitResult.fromJson(Map<String, dynamic> json) {
    return RetailCheckoutSubmitResult(
      orderId: _firstText(json, const ['orderId', 'id']) ?? '',
      orderNo: _firstText(json, const ['orderNo', 'no']) ?? '',
      orderStatus: _firstText(json, const ['orderStatus', 'status']) ?? '',
      paymentStatus: _firstText(json, const ['paymentStatus']) ?? '',
      payAmountMinor: _asInt(json['payAmountMinor']) ?? 0,
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String orderId;
  final String orderNo;
  final String orderStatus;
  final String paymentStatus;
  final int payAmountMinor;
  final Map<String, dynamic> raw;
}

@immutable
class RetailCheckoutPrepay {
  const RetailCheckoutPrepay({
    required this.paymentOrderId,
    required this.paymentNo,
    required this.paymentStatus,
    required this.prepayId,
    required this.expireTime,
    required this.raw,
  });

  factory RetailCheckoutPrepay.fromJson(Map<String, dynamic> json) {
    return RetailCheckoutPrepay(
      paymentOrderId: _firstText(json, const ['paymentOrderId']) ?? '',
      paymentNo: _firstText(json, const ['paymentNo', 'outTradeNo']) ?? '',
      paymentStatus: _firstText(json, const ['paymentStatus']) ?? '',
      prepayId: _firstText(json, const ['prepayId']) ?? '',
      expireTime: _firstText(json, const ['expireTime']) ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String paymentOrderId;
  final String paymentNo;
  final String paymentStatus;
  final String prepayId;
  final String expireTime;
  final Map<String, dynamic> raw;

  bool get hasPrepayPayload => _asMap(raw['prepayPayload']).isNotEmpty;
}

@immutable
class RetailCheckoutCashier {
  const RetailCheckoutCashier({
    required this.orderId,
    required this.status,
    required this.statusDesc,
    required this.paymentStatus,
    required this.paymentStatusDesc,
    required this.payChannels,
    required this.orderBody,
    required this.payExpireTime,
    required this.raw,
  });

  factory RetailCheckoutCashier.fromJson(Map<String, dynamic> json) {
    return RetailCheckoutCashier(
      orderId: _firstText(json, const ['id', 'orderId']) ?? '',
      status: _firstText(json, const ['status']) ?? '',
      statusDesc: _firstText(json, const ['statusDesc']) ?? '',
      paymentStatus: _firstText(json, const ['paymentStatus']) ?? '',
      paymentStatusDesc: _firstText(json, const ['paymentStatusDesc']) ?? '',
      payChannels: _asList(json['payChannels'])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      orderBody: _firstText(json, const ['orderBody']) ?? '',
      payExpireTime: _firstText(json, const ['payExpireTime']) ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String orderId;
  final String status;
  final String statusDesc;
  final String paymentStatus;
  final String paymentStatusDesc;
  final List<String> payChannels;
  final String orderBody;
  final String payExpireTime;
  final Map<String, dynamic> raw;
}

@immutable
class RetailCheckoutPayStatus {
  const RetailCheckoutPayStatus({
    required this.orderId,
    required this.payStatus,
    required this.orderStatus,
    required this.paymentOrderId,
    required this.paidTime,
    required this.raw,
  });

  factory RetailCheckoutPayStatus.fromJson(Map<String, dynamic> json) {
    return RetailCheckoutPayStatus(
      orderId: _firstText(json, const ['orderId', 'id']) ?? '',
      payStatus: _firstText(json, const ['payStatus', 'paymentStatus']) ?? '',
      orderStatus: _firstText(json, const ['orderStatus', 'status']) ?? '',
      paymentOrderId: _firstText(json, const ['paymentOrderId']) ?? '',
      paidTime: _firstText(json, const ['paidTime']) ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String orderId;
  final String payStatus;
  final String orderStatus;
  final String paymentOrderId;
  final String paidTime;
  final Map<String, dynamic> raw;

  bool get isPaid {
    final normalized = payStatus.trim().toUpperCase();
    return normalized == 'PAID' ||
        normalized == 'SUCCESS' ||
        normalized == 'CONFIRMED' ||
        normalized == 'PAY_SUCCESS';
  }
}

@immutable
class RetailCheckoutFlowResult {
  const RetailCheckoutFlowResult({
    required this.preview,
    required this.submittedOrder,
    required this.orderDetail,
    required this.cashier,
    required this.prepay,
    required this.payStatus,
  });

  final RetailCheckoutPreview preview;
  final RetailCheckoutSubmitResult submittedOrder;
  final Map<String, dynamic> orderDetail;
  final RetailCheckoutCashier? cashier;
  final RetailCheckoutPrepay? prepay;
  final RetailCheckoutPayStatus? payStatus;
}

class RetailCheckoutService {
  const RetailCheckoutService(this._source);

  final ReportRemoteSource _source;

  Future<RetailCheckoutPreview> preview(RetailCheckoutRequest request) async {
    final raw = await _source.previewRetailOrder(
      storeId: request.storeId,
      employeeId: request.employeeId,
      deliveryType: request.deliveryType,
      deliveryAddress: request.deliveryAddress.toJson(),
      items: request.itemPayload,
    );
    return RetailCheckoutPreview.fromJson(raw, fallback: request);
  }

  Future<RetailCheckoutFlowResult> submitAndPreparePayment(
    RetailCheckoutRequest request, {
    RetailCheckoutPreview? preview,
  }) async {
    final resolvedPreview = preview ?? await this.preview(request);
    final submittedRaw = await _source.submitRetailOrder(
      storeId: request.storeId,
      employeeId: request.employeeId,
      deliveryType: request.deliveryType,
      deliveryAddress: request.deliveryAddress.toJson(),
      expectedPayAmountMinor: resolvedPreview.payAmountMinor,
      remark: request.remark,
      items: request.itemPayload,
    );
    final submittedOrder = RetailCheckoutSubmitResult.fromJson(submittedRaw);
    final orderId = submittedOrder.orderId.trim();
    if (orderId.isEmpty) {
      throw StateError('Order submit response did not include orderId.');
    }

    final orderDetail = await _source.getRetailOrderDetail(orderId);
    RetailCheckoutCashier? cashier;
    RetailCheckoutPrepay? prepay;
    RetailCheckoutPayStatus? payStatus;

    try {
      cashier = RetailCheckoutCashier.fromJson(
        await _source.getOrderCashier(orderId),
      );
    } catch (_) {
      cashier = null;
    }

    prepay = RetailCheckoutPrepay.fromJson(
      await _source.prepayRetailOrder(orderId),
    );

    try {
      payStatus = RetailCheckoutPayStatus.fromJson(
        await _source.getOrderPayStatus(
          orderId: orderId,
          t: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {
      payStatus = null;
    }

    return RetailCheckoutFlowResult(
      preview: resolvedPreview,
      submittedOrder: submittedOrder,
      orderDetail: orderDetail,
      cashier: cashier,
      prepay: prepay,
      payStatus: payStatus,
    );
  }

  Future<RetailCheckoutPayStatus> refreshPayStatus(String orderId) async {
    final raw = await _source.getOrderPayStatus(
      orderId: orderId,
      t: DateTime.now().millisecondsSinceEpoch,
    );
    return RetailCheckoutPayStatus.fromJson(raw);
  }
}

String? _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return num.tryParse(normalized)?.round();
  }
  return null;
}
