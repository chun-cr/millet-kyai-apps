part of '../report_page.dart';

Future<void> _showReportShareDialog(
  BuildContext context,
  DiagnosisReportShareQrCode shareQrCode,
) async {
  final qrBytes = _decodeReportShareQrCodeBytes(shareQrCode.imageBase64);
  final copyValue = shareQrCode.copyValue.trim();
  final hasCopyValue = copyValue.isNotEmpty;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        key: const ValueKey('report_share_dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF8F5EF),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _reportShareDialogTitle(dialogContext),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
              const SizedBox(height: 16),
              if (shareQrCode.hasDisplayableImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: qrBytes != null
                        ? Image.memory(qrBytes, fit: BoxFit.contain)
                        : Image.network(
                            shareQrCode.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _ReportShareFallbackCard(
                              shareQrCode: shareQrCode,
                            ),
                          ),
                  ),
                )
              else
                _ReportShareFallbackCard(shareQrCode: shareQrCode),
              if (shareQrCode.hasDisplayableImage) ...[
                const SizedBox(height: 10),
                Text(
                  _reportShareHint(dialogContext),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B7A69),
                  ),
                ),
              ],
              if (hasCopyValue) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7DBCC)),
                  ),
                  child: SelectableText(
                    copyValue,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5E4B3A),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasCopyValue)
                    TextButton(
                      key: const ValueKey('report_share_copy_button'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: copyValue));
                        if (!dialogContext.mounted) {
                          return;
                        }
                        showAppToast(
                          dialogContext,
                          _reportShareCopiedMessage(dialogContext),
                          kind: AppToastKind.success,
                        );
                      },
                      child: Text(_reportShareCopyAction(dialogContext)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(_reportShareCloseAction(dialogContext)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ReportShareFallbackCard extends StatelessWidget {
  const _ReportShareFallbackCard({required this.shareQrCode});

  final DiagnosisReportShareQrCode shareQrCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9DDCF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 42,
            color: Color(0xFFC57B08),
          ),
          const SizedBox(height: 10),
          Text(
            shareQrCode.copyValue.trim().isNotEmpty
                ? _reportShareFallbackMessage(context)
                : _reportShareEmptyMessage(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B5B4B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List? _decodeReportShareQrCodeBytes(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final base64Payload = normalized.startsWith('data:image/')
      ? normalized.substring(normalized.indexOf(',') + 1)
      : normalized;
  try {
    return base64Decode(base64Payload);
  } on FormatException {
    return null;
  }
}

bool _isChineseLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'zh';
}

String _reportShareDialogTitle(BuildContext context) {
  return _isChineseLocale(context) ? '报告分享二维码' : 'Report share QR code';
}

String _reportShareHint(BuildContext context) {
  return _isChineseLocale(context)
      ? '长按图片识别二维码'
      : 'Long press the image to scan the QR code.';
}

String _reportShareFallbackMessage(BuildContext context) {
  return _isChineseLocale(context)
      ? '二维码图片不可用，可复制下方分享内容继续转发。'
      : 'The QR image is unavailable. Copy the share content below instead.';
}

String _reportShareMissingIdMessage(BuildContext context) {
  return _isChineseLocale(context)
      ? '当前报告缺少 reportId，无法分享。'
      : 'This report cannot be shared because the reportId is missing.';
}

String _reportShareEmptyMessage(BuildContext context) {
  return _isChineseLocale(context)
      ? '未获取到可用的分享二维码。'
      : 'No usable share QR code was returned.';
}

String _reportShareFailedMessage(BuildContext context) {
  return _isChineseLocale(context)
      ? '获取分享二维码失败，请稍后重试。'
      : 'Unable to load the report share QR code right now.';
}

String _reportShareCopiedMessage(BuildContext context) {
  return _isChineseLocale(context) ? '分享内容已复制。' : 'Share content copied.';
}

String _reportShareCopyAction(BuildContext context) {
  return _isChineseLocale(context) ? '复制' : 'Copy';
}

String _reportShareCloseAction(BuildContext context) {
  return _isChineseLocale(context) ? '关闭' : 'Close';
}
