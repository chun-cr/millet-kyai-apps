part of '../tongue_scan_page.dart';

// 扫描状态枚举。
enum ScanState { idle, scanning, uploading, completed }

/// 只有“检测到伸舌 + 已确认伸舌 + 嘴部在框内”同时成立时，才允许开始计时。
bool isTongueHoldEligible({
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  return protrusionCandidate &&
      protrusionConfirmed &&
      isFramed &&
      !pauseAutoScanUntilReset;
}

bool shouldKeepTongueHoldAlive({
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
}) {
  return protrusionCandidate || protrusionConfirmed;
}

@visibleForTesting
/// 进入 hold 后允许短暂依赖 candidate/confirmed 保活，减少检测抖动带来的误重置。
bool shouldTrackTongueHold({
  required bool holdInProgress,
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  if (!isFramed || pauseAutoScanUntilReset) {
    return false;
  }

  if (holdInProgress) {
    return shouldKeepTongueHoldAlive(
      protrusionCandidate: protrusionCandidate,
      protrusionConfirmed: protrusionConfirmed,
    );
  }

  return isTongueHoldEligible(
    protrusionCandidate: protrusionCandidate,
    protrusionConfirmed: protrusionConfirmed,
    isFramed: isFramed,
    pauseAutoScanUntilReset: pauseAutoScanUntilReset,
  );
}

@visibleForTesting
/// 视觉检测偶尔会丢一两帧，这里给一个极短宽限期，避免进度条频繁清零。
bool isTongueHoldAliveWithinGrace({
  required bool holdAliveNow,
  required bool holdInProgress,
  required DateTime? lastHoldAliveAt,
  required Duration gracePeriod,
  DateTime? now,
}) {
  if (holdAliveNow) {
    return true;
  }

  if (!holdInProgress || lastHoldAliveAt == null) {
    return false;
  }

  final referenceTime = now ?? DateTime.now();
  return referenceTime.difference(lastHoldAliveAt) <= gracePeriod;
}

/// 返回当前阻塞自动抓拍的原因，顺序同时作为 UI 提示优先级。
List<String> describeTongueScanBlockers({
  required bool mouthPresent,
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  if (!mouthPresent) {
    return const ['mouth_missing'];
  }

  final blockers = <String>[];
  if (!protrusionConfirmed) {
    blockers.add(
      protrusionCandidate ? 'protrusion_unconfirmed' : 'protrusion_missing',
    );
  }
  if (!isFramed) {
    blockers.add('framing_failed');
  }
  if (pauseAutoScanUntilReset) {
    blockers.add('paused_after_failure');
  }

  return blockers.isEmpty ? const ['hold_ready'] : blockers;
}

const _kAccent = Color(0xFF0D7A5A); // 主强调色
const _kAccentLight = Color(0xFF3DAB78);
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色
