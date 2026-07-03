// 报告模块页面：`ReportProductDetailPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_product_data.dart';

class ReportCheckoutArgs {
  final ReportProductData product;
  final int quantity;

  const ReportCheckoutArgs({required this.product, required this.quantity});
}

class ReportProductDetailPage extends StatefulWidget {
  final ReportProductData product;

  const ReportProductDetailPage({super.key, required this.product});

  @override
  State<ReportProductDetailPage> createState() =>
      _ReportProductDetailPageState();
}

class _ReportProductDetailPageState extends State<ReportProductDetailPage> {
  int _quantity = 1;
  late Future<ReportProductData> _resolvedProductFuture;

  @override
  void initState() {
    super.initState();
    _resolvedProductFuture = _loadResolvedProduct();
  }

  @override
  void didUpdateWidget(covariant ReportProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id == widget.product.id &&
        oldWidget.product.detailId == widget.product.detailId) {
      return;
    }

    setState(() {
      _quantity = 1;
      _resolvedProductFuture = _loadResolvedProduct();
    });
  }

  Future<ReportProductData> _loadResolvedProduct() async {
    final source = ReportRemoteSource(getIt<DioClient>());
    final retailSpuId = widget.product.retailSpuId?.trim() ?? '';
    final retailStoreId = int.tryParse(widget.product.storeId?.trim() ?? '');
    if (retailSpuId.isNotEmpty && retailStoreId != null) {
      try {
        final detail = await source.getRetailSpuDetail(
          id: retailSpuId,
          storeId: retailStoreId,
          selectedRetailSkuId: widget.product.retailSkuId,
        );
        if (detail.isNotEmpty) {
          return widget.product.mergeBackend(detail);
        }
      } catch (_) {
        // 商品推荐旧链路不一定带零售 SPU，上游失败时回退到体质商品详情。
      }
    }

    final detailId = widget.product.detailId?.trim() ?? '';
    if (detailId.isEmpty) {
      return widget.product;
    }

    try {
      final detail = await source.getPhysiqueProductDetail(detailId);
      if (detail == null || detail.isEmpty) {
        return widget.product;
      }
      return widget.product.mergeBackend(detail);
    } catch (_) {
      return widget.product;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<ReportProductData>(
      future: _resolvedProductFuture,
      initialData: widget.product,
      builder: (context, snapshot) {
        final product = snapshot.data ?? widget.product;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F1EB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(l10n.reportProductDetailTitle),
            actions: [
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          product.color,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: product.color.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reportProductDetailFinalPrice,
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.priceLabel,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: product.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          context.push(
                            AppRoutes.reportCheckout,
                            extra: ReportCheckoutArgs(
                              product: product,
                              quantity: _quantity,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                product.color.withValues(alpha: 0.86),
                                product.color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: product.color.withValues(alpha: 0.24),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            l10n.reportProductDetailCheckoutButton,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _DetailHero(product: product),
                  const SizedBox(height: 16),
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.reportProductDetailRecommendationTitle,
                          color: product.color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              label: product.type,
                              color: product.color,
                            ),
                            _InfoChip(label: product.tag, color: product.color),
                            _InfoChip(
                              label: l10n.reportProductDetailReportLinked,
                              color: product.color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          title: l10n.reportProductDetailPackageTitle,
                          body: product.packageNote,
                          color: product.color,
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          title: l10n.reportProductDetailShippingTitle,
                          body: product.shippingNote,
                          color: product.color,
                          icon: Icons.local_shipping_outlined,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          title: l10n.reportProductDetailServiceTitle,
                          body: l10n.reportProductDetailServiceBody,
                          color: product.color,
                          icon: Icons.support_agent_outlined,
                        ),
                      ],
                    ),
                  ),
                  if (product.hasRetailSkuInfo) ...[
                    const SizedBox(height: 16),
                    _RetailSkuInfoCard(product: product),
                  ],
                  const SizedBox(height: 16),
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.reportProductDetailQuantityTitle,
                          color: product.color,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove,
                              color: product.color,
                              onTap: _quantity > 1
                                  ? () => setState(() => _quantity -= 1)
                                  : null,
                            ),
                            Container(
                              width: 64,
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1810),
                                ),
                              ),
                            ),
                            _QuantityButton(
                              icon: Icons.add,
                              color: product.color,
                              onTap: () => setState(() => _quantity += 1),
                            ),
                            const Spacer(),
                            Text(
                              l10n.reportProductDetailQuantitySummary(
                                _quantity,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(
                                  0xFF3A3028,
                                ).withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: product.color,
                      backgroundColor: product.color.withValues(alpha: 0.12),
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

class _DetailHero extends StatelessWidget {
  final ReportProductData product;

  const _DetailHero({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            product.color.withValues(alpha: 0.06),
            product.color.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: product.color.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              l10n.reportProductDetailHeroBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: product.color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(product.icon, color: product.color, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1810),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: product.color.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.priceLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: product.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final IconData icon;

  const _InfoRow({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetailSkuInfoCard extends StatelessWidget {
  const _RetailSkuInfoCard({required this.product});

  final ReportProductData product;

  @override
  Widget build(BuildContext context) {
    final salable = product.retailSalable;
    final statusColor = salable == false
        ? const Color(0xFFB05A5A)
        : const Color(0xFF2D6A4F);

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: '后端规格', color: product.color),
          const SizedBox(height: 12),
          if (product.retailSkuName?.trim().isNotEmpty == true)
            _InfoRow(
              title: '当前 SKU',
              body: product.retailSkuName!.trim(),
              color: product.color,
              icon: Icons.qr_code_2_outlined,
            ),
          if (product.retailSpecText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _InfoRow(
              title: '规格',
              body: product.retailSpecText!.trim(),
              color: product.color,
              icon: Icons.tune_rounded,
            ),
          ],
          if (salable != null) ...[
            const SizedBox(height: 14),
            _InfoRow(
              title: '库存状态',
              body: salable ? '可下单，结算页会使用真实 SKU 生成订单' : '暂不可售，请返回选择其他商品',
              color: statusColor,
              icon: salable
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.04 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color.withValues(alpha: onTap == null ? 0.34 : 0.82),
        ),
      ),
    );
  }
}
