part of '../report_page.dart';

// ignore_for_file: unused_element

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFFA09080).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

class _ConstitutionScoreRow extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  final bool isMain;

  const _ConstitutionScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.isMain,
  });

  @override
  State<_ConstitutionScoreRow> createState() => _ConstitutionScoreRowState();
}

class _ConstitutionScoreRowState extends State<_ConstitutionScoreRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
      const Duration(milliseconds: 300),
      () => mounted ? _ctrl.forward() : null,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSecondaryLow = !widget.isMain && widget.score < 0.28;

    return Row(
      children: [
        if (widget.isMain)
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
              color: widget.isMain
                  ? const Color(0xFF1E1810)
                  : (isSecondaryLow
                        ? const Color(0xFFA09080).withValues(alpha: 0.72)
                        : const Color(0xFFA09080)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: widget.score * _anim.value,
              height: widget.isMain ? 4 : 3,
              emphasize: widget.isMain,
              trackColor: isSecondaryLow ? Colors.transparent : null,
              fillColors: widget.isMain
                  ? const [
                      Color(0xFFD7EFD9),
                      Color(0xFFA9D6B5),
                      Color(0xFF74B58A),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Text(
              '${(widget.score * _anim.value * 100).round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
                color: widget.isMain
                    ? const Color(0xFF2D6A4F)
                    : (isSecondaryLow
                          ? const Color(0xFFA09080).withValues(alpha: 0.7)
                          : const Color(0xFF6E8E7A)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 穴位卡片。
class _AcuPointCard extends StatelessWidget {
  final _AcuPoint point;
  const _AcuPointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: point.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: point.color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          point.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: point.color,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          point.meridian,
                          style: TextStyle(
                            fontSize: 11,
                            color: point.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFFA09080),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            point.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA09080),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.effect,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 食材标签。
class _FoodChip extends StatelessWidget {
  final String name;
  final String desc;
  final Color color;

  const _FoodChip({
    required this.name,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 项目推荐卡片。
class _ProjectCard extends StatelessWidget {
  final ReportProjectData project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(
          Uri(
            path: AppRoutes.reportProjectDetail,
            queryParameters: project.toRouteQueryParameters(),
          ).toString(),
          extra: project,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: project.color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: project.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: project.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(project.icon, size: 24, color: project.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        Text(
                          project.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: project.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      project.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: project.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      project.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.durationNote,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: project.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: project.color.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.reportAdviceProjectDetailButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: project.color.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
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

class _ProductCard extends StatelessWidget {
  final ReportProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.reportProductDetail, extra: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: product.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(product.icon, size: 24, color: product.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        Text(
                          product.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: product.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.priceLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: product.color,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: product.color.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.reportAdviceProductDetailButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.color.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
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

// 数据模型

class _AcuPoint {
  final String name;
  final String location;
  final String effect;
  final String meridian;
  final Color color;

  const _AcuPoint({
    required this.name,
    required this.location,
    required this.effect,
    required this.meridian,
    required this.color,
  });
}

class _SeasonData {
  final String name;
  final Color color;
  final Color lightColor;
  final String advice;
  final String avoid;

  const _SeasonData({
    required this.name,
    required this.color,
    required this.lightColor,
    required this.advice,
    required this.avoid,
  });
}

// 自定义绘制器
