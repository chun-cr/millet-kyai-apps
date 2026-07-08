part of '../report_page.dart';

String _heroTimestampPrefix() => '报告时间';

String _heroViewImagesLabel() => '查看图片';

String _heroAgeLabel() => '肤龄';

String _heroTongueLabel() => '舌相';

String _heroTherapyLabel() => '调理';

String _heroDisclaimer() => '注：拍摄角度、光线均有可能影响分析结果。';

String _heroImagesTitle() => '采集图片';

String _heroImageEmptyState() => '暂无可查看图片';

String _formatHeroDate(String? rawValue) {
  final trimmed = rawValue?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '今日';
  }

  final normalized = trimmed.replaceAll('/', '-');
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return '${parsed.year}.${_twoDigits(parsed.month)}.${_twoDigits(parsed.day)}';
  }

  if (RegExp(r'^\d{10,16}$').hasMatch(trimmed)) {
    final epochValue = int.tryParse(trimmed);
    if (epochValue != null) {
      final milliseconds = trimmed.length <= 10
          ? epochValue * 1000
          : epochValue;
      final epochDate = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return '${epochDate.year}.${_twoDigits(epochDate.month)}.${_twoDigits(epochDate.day)}';
    }
  }

  final match = RegExp(
    r'(\d{4})[-.](\\d{1,2})[-.](\\d{1,2})',
  ).firstMatch(normalized);
  if (match != null) {
    final year = match.group(1)!;
    final month = _twoDigits(int.parse(match.group(2)!));
    final day = _twoDigits(int.parse(match.group(3)!));
    return '$year.$month.$day';
  }

  return trimmed;
}

String _formatHeroAge(double age) {
  if (age == age.roundToDouble()) {
    return age.round().toString();
  }
  return age.toStringAsFixed(1);
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

Future<void> _showHeroImagesDialog(
  BuildContext context,
  List<String> imageUrls,
) async {
  final urls = imageUrls
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: const Color(0xFFF8F5EF),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _heroImagesTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1810),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: urls.isEmpty
                    ? Center(
                        child: Text(
                          _heroImageEmptyState(),
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(
                              0xFF3C342B,
                            ).withValues(alpha: 0.76),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: urls.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final imageUrl = urls[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE8DDCF),
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ColoredBox(
                                color: const Color(0xFFF8F5EF),
                                child: InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 4,
                                  child: SizedBox.expand(
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(
                                          _heroImageEmptyState(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(
                                              0xFF3C342B,
                                            ).withValues(alpha: 0.76),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
