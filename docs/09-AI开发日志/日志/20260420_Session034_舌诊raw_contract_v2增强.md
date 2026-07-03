# Session 034 - 舌诊 raw contract v2 增强

## 做了什么
- 启动舌诊 raw contract v2 第一阶段实施，目标是在不推翻现有几何代理与页面状态机的前提下，把双端已有的 `blendshapes` 透传到舌诊流，并作为增强信号参与 Flutter 侧判定。
- 先完成代码链路摸底，确认 Android `FaceLandmarkerHelper.kt` 与 iOS `FaceLandmarkerService.swift` 都已经能拿到 `blendshapes`，但当前 tongue payload 尚未透传该字段。
- 收敛最小实现策略：保持 additive contract、保持旧字段兼容、保持 hold/framing/upload 逻辑不变，只新增 `blendshapes` 字段与保守融合判定。
- 新增本次实施计划文件：`.sisyphus/plans/2026-04-20-tongue-raw-contract-v2-phase1.md`。

## 变更前快照
- Android 舌诊流在 `FaceScanChannel.sendTongueEvent()` 中仅发送 `mouthLandmarks / faceLandmarks / landmarks / imageWidth / imageHeight / mouthCenter`。
- iOS `TongueDetectionEvaluator.Result.payload` 同样仅发送几何字段。
- Flutter `TongueScanStatus` 不解析 `blendshapes`，`TongueProtrusionProxy` 完全依赖几何代理。

## 涉及文件
- `.sisyphus/plans/2026-04-20-tongue-raw-contract-v2-phase1.md`
- `docs/09-AI开发日志/日志/20260420_Session034_舌诊raw_contract_v2增强.md`

## 问题与决策
- 决策：第一阶段不直接上 tongue-specific 模型，而是先复用双端已有 Face Landmarker `blendshapes` 做 contract v2 additive 扩展。
- 决策：`blendshapes` 只作为增强信号，不允许单独放行，避免重新引入“张嘴就通过”的历史问题。
- 决策：若增强效果不理想，优先通过 Flutter 停止消费 `blendshapes` 回退，而不是立即回退整个原生契约扩展。

## 下次计划
- 实现 Android / iOS 舌诊 payload 的 `blendshapes` 透传。
- 实现 Flutter 侧 `blendshapes` 解析与保守融合判定。
- 补 focused tests，并执行 analyze / compile 验证。

## 验证结果
- `flutter test test/features/scan/tongue_scan_status_bridge_test.dart test/features/scan/tongue_scan_confirmation_policy_test.dart test/features/scan/tongue_scan_page_state_test.dart -r compact`：通过。
- `flutter analyze lib/features/scan/presentation/services/tongue_scan_status_bridge.dart lib/features/scan/presentation/services/tongue_scan_confirmation_policy.dart test/features/scan/tongue_scan_status_bridge_test.dart test/features/scan/tongue_scan_confirmation_policy_test.dart test/features/scan/tongue_scan_page_state_test.dart`：通过。
- `./gradlew.bat :app:compileDebugKotlin --console=plain`（workdir=`android/`）：通过。
- `lsp_diagnostics`：Flutter changed scope 无诊断问题；Swift / Kotlin LSP 在当前环境未安装，因此未获得原生侧诊断结果。
- iOS 本地编译未验证：当前 Win32 环境缺少 Xcode / sourcekit-lsp。
