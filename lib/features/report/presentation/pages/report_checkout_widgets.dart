part of 'report_checkout_page.dart';

class _CheckoutCard extends StatelessWidget {
  final Widget child;

  const _CheckoutCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _CheckoutSectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _CheckoutSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

class _CheckoutField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _CheckoutField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 13 : 12,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF3A3028).withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 18 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

class _ApplePayPlaceholder extends StatelessWidget {
  final bool enabled;
  final String title;
  final VoidCallback onTap;

  const _ApplePayPlaceholder({
    required this.enabled,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.creditcard_fill, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GooglePayPlaceholder extends StatelessWidget {
  final bool enabled;
  final String title;
  final VoidCallback onTap;

  const _GooglePayPlaceholder({
    required this.enabled,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E1810).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF1E1810),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool dark;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = dark ? Colors.black : Colors.white;
    final titleColor = dark ? Colors.white : const Color(0xFF1E1810);
    final subtitleColor = dark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF3A3028).withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: dark
            ? null
            : Border.all(
                color: const Color(0xFF1E1810).withValues(alpha: 0.08),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, color: titleColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutNoticeCard extends StatelessWidget {
  const _CheckoutNoticeCard({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: const Color(0xFF3A3028).withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChannelWrap extends StatelessWidget {
  const _PaymentChannelWrap({required this.color, required this.channels});

  final Color color;
  final List<String> channels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: channels
          .map((channel) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                channel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.82),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _OrderResultCard extends StatelessWidget {
  final Color productColor;
  final RetailCheckoutFlowResult flowResult;

  const _OrderResultCard({
    required this.productColor,
    required this.flowResult,
  });

  @override
  Widget build(BuildContext context) {
    final order = flowResult.submittedOrder;
    final cashier = flowResult.cashier;
    final prepay = flowResult.prepay;
    final payStatus = flowResult.payStatus;
    final successColor = payStatus?.isPaid == true
        ? const Color(0xFF2D6A4F)
        : productColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, successColor.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: successColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded, color: successColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '真实订单已创建',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1810),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderNo.trim().isNotEmpty
                          ? '订单号：${order.orderNo}'
                          : '订单 ID：${order.orderId}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResultLine(label: '订单状态', value: _displayValue(order.orderStatus)),
          _ResultLine(label: '提交支付', value: _displayValue(order.paymentStatus)),
          if (cashier != null) ...[
            _ResultLine(
              label: '收银台',
              value: _displayValue(
                cashier.paymentStatusDesc,
                cashier.statusDesc,
              ),
            ),
            if (cashier.payExpireTime.trim().isNotEmpty)
              _ResultLine(label: '支付截止', value: cashier.payExpireTime),
          ],
          if (prepay != null) ...[
            _ResultLine(label: '预支付单', value: _displayValue(prepay.paymentNo)),
            _ResultLine(
              label: '预支付状态',
              value: _displayValue(prepay.paymentStatus),
            ),
            if (prepay.hasPrepayPayload)
              _ResultLine(label: '调起参数', value: '已返回 prepayPayload'),
          ],
          if (payStatus != null)
            _ResultLine(
              label: '支付确认',
              value: _displayValue(payStatus.payStatus, payStatus.orderStatus),
            ),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFFA09080).withValues(alpha: 0.86),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF3A3028),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

String _compactError(Object error) {
  final text = error.toString().trim();
  if (text.length <= 88) {
    return text;
  }
  return '${text.substring(0, 88)}...';
}

String _displayValue(String? primary, [String? fallback]) {
  final resolved = _firstNonEmpty([primary, fallback]);
  return resolved.isEmpty ? '待返回' : resolved;
}
