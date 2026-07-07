part of '../shipping_address_page.dart';

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
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: _kAddressPrimary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _ShippingAddressIllustration(),
                      const SizedBox(height: 34),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: _kAddressTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: _kAddressTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShippingAddressIllustration extends StatelessWidget {
  const _ShippingAddressIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 226,
      height: 190,
      child: CustomPaint(painter: _ShippingAddressIllustrationPainter()),
    );
  }
}

class _ShippingAddressIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = _kAddressPrimary.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 20),
        width: size.width * 0.72,
        height: 28,
      ),
      shadowPaint,
    );

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(26, 26, size.width - 52, size.height - 58),
      const Radius.circular(28),
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _kAddressCardBg,
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _kAddressNavBorder,
    );

    final pinCenter = Offset(size.width / 2, 68);
    canvas.drawCircle(
      pinCenter,
      38,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _kAddressPrimarySoft,
    );
    canvas.drawCircle(
      pinCenter,
      38,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _kAddressPrimary.withValues(alpha: 0.22),
    );

    final pinPath = Path()
      ..moveTo(pinCenter.dx, pinCenter.dy + 28)
      ..cubicTo(
        pinCenter.dx - 24,
        pinCenter.dy + 2,
        pinCenter.dx - 20,
        pinCenter.dy - 24,
        pinCenter.dx,
        pinCenter.dy - 24,
      )
      ..cubicTo(
        pinCenter.dx + 20,
        pinCenter.dy - 24,
        pinCenter.dx + 24,
        pinCenter.dy + 2,
        pinCenter.dx,
        pinCenter.dy + 28,
      )
      ..close();
    canvas.drawPath(
      pinPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _kAddressPrimary,
    );
    canvas.drawCircle(
      Offset(pinCenter.dx, pinCenter.dy - 4),
      8,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _kAddressCardBg,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = _kAddressDivider;
    canvas.drawLine(
      const Offset(58, 124),
      Offset(size.width - 58, 124),
      linePaint,
    );
    linePaint.strokeWidth = 7;
    canvas.drawLine(
      const Offset(76, 148),
      Offset(size.width - 76, 148),
      linePaint,
    );

    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kAddressGold.withValues(alpha: 0.20);
    canvas.drawOval(Rect.fromLTWH(150, 18, 36, 18), leafPaint);
    canvas.drawOval(Rect.fromLTWH(38, 92, 30, 16), leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddressEmptyBottomBar extends StatelessWidget {
  const _AddressEmptyBottomBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _kAddressPageBg,
        border: Border(top: BorderSide(color: _kAddressNavBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
          child: TDButton(
            text: label,
            icon: Icons.add_location_alt_outlined,
            iconTextSpacing: 8,
            size: TDButtonSize.large,
            shape: TDButtonShape.rectangle,
            width: double.infinity,
            height: 56,
            style: TDButtonStyle(
              backgroundColor: _kAddressPrimary,
              frameColor: _kAddressPrimary,
              textColor: Colors.white,
              radius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
