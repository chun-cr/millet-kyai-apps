# Session 033 - 舌诊 Flutter 确认重构

## 做了什么
- 启动舌诊扫描链路重构，目标是把“是否伸舌”的最终业务判断从原生 mouth-open fallback 下沉到 Flutter 层的坐标代理确认逻辑。
- 已完成方案收敛与专家复核：保留现有 2 秒 hold 与固定 guide crop，只重写 tongue readiness 的来源与多帧确认策略。
- 已明确实现边界：当前 Android/iOS 事件流不包含真实舌体 contour，本次只能实现基于现有 face/mouth 坐标的代理启发式，而不是舌体分割模型。
- 新增 `tongue_scan_confirmation_policy.dart`，在 Flutter 层实现 `TongueProtrusionProxy + TongueConfirmationWindow`，把“单帧候选”与“滚动窗口确认”拆开。
- 重写 `tongue_scan_status_bridge.dart`：显式解析 `faceLandmarks`（兼容 legacy `landmarks`），并让 `readyToScan` 仅反映 Flutter 的 `protrusionConfirmed`。
- 调整 `tongue_scan_page.dart`：页面 hold 不再依赖 native `tongueDetected`，改为依赖 Flutter `protrusionConfirmed` 与嘴部取景框命中；同时 framing 只基于 `mouthLandmarks`，不再误用整脸 landmarks。
- 补充/重写舌诊确认测试：覆盖原始 payload 解析、坐标代理规则、滚动窗口确认、page hold eligibility，以及几何工具回归。
- 在第二轮清理中，删除 Android / iOS 侧舌诊 `mouthOpenRatio` fallback 与 `tongueDetected` / `tongueOutScore` 旧字段输出；Flutter `TongueScanStatus` 同步移除这些旧字段和 `readyToScan` 别名。
- 删除已无调用的旧 `tongue/capture` 跨端 handler，以及未被页面引用的 `lib/features/scan/presentation/widgets/tongue_landmark_overlay.dart`。
- 将 tongue 事件契约收敛为 `faceLandmarks + mouthLandmarks + mouthCenter + imageWidth/imageHeight`；其中 `faceLandmarks` 与 legacy `landmarks` 仍双写，保持一轮迁移兼容。
- 将 `tongue_scan_page.dart` 中误导性的 `_tongueDetected` 重命名为 `_holdEligible`，避免把“可进入 hold”误解为“native 已检测到舌头”。

## 变更前快照
- Android `TongueDetectionUtils.kt` 与 iOS `TongueDetectionEvaluator.swift` 仍使用 `tongueOutScore >= 0.35 || mouthOpenRatio >= 0.06` 产出 `tongueDetected`。
- Flutter `tongue_scan_status_bridge.dart` 仍把 native 布尔值/阈值合成为 `readyToScan`，页面最终以该语义驱动 hold。
- tongue 事件中的 `landmarks` 语义混乱，当前实际承载的是全脸 landmarks，而不是 tongue-only landmarks。
- `tongue_scan_page.dart` 已具备 guide 几何校验、2 秒 hold、抓拍上传与跳转 palm 的完整状态机，可复用。

## 涉及文件
- `lib/features/scan/presentation/services/tongue_scan_confirmation_policy.dart`
- `lib/features/scan/presentation/services/tongue_scan_status_bridge.dart`
- `lib/features/scan/presentation/pages/tongue_scan_page.dart`
- `android/app/src/main/kotlin/com/example/stitch_diag_demo/TongueDetectionUtils.kt`
- `android/app/src/main/kotlin/com/example/stitch_diag_demo/FaceLandmarkerHelper.kt`
- `android/app/src/main/kotlin/com/example/stitch_diag_demo/FaceScanChannel.kt`
- `ios/Runner/TongueDetectionEvaluator.swift`
- `ios/Runner/FaceLandmarkerService.swift`
- `ios/Runner/AppDelegate.swift`
- `test/features/scan/tongue_scan_status_bridge_test.dart`
- `test/features/scan/tongue_scan_confirmation_policy_test.dart`
- `test/features/scan/tongue_scan_page_state_test.dart`
- `docs/09-AI开发日志/日志/20260417_Session033_舌诊Flutter确认重构.md`

## 问题与决策
- 决策：保留 fixed guide crop，不把本次改造扩散到裁剪策略。
- 决策：保留现有 2 秒 hold，短窗口多帧确认只负责去抖，不替代 hold。
- 决策：Flutter 拥有最终 tongue confirmation truth；native 退回到原始观测数据提供者。
- 决策：显式承认本次是“坐标代理启发式”，不伪装成真舌体几何检测。
- 决策：本次先不改 Android/iOS evaluator 与 payload 生产逻辑，直接在 Flutter 侧兼容当前 raw contract，优先实现“最终业务真相下沉到 Dart”。
- 决策：保留现有 native `tongueDetected` / `tongueOutScore` 字段作为兼容输入，但它们不再控制页面 hold 启动。
- 第二轮决策：在确认 Flutter 已不再消费旧字段后，正式删除 native `tongueDetected` / `tongueOutScore` 与 `mouthOpenRatio` fallback；但 `landmarks -> faceLandmarks` 采用双写迁移，不在这一轮硬切 legacy key。

## 验证结果
- `flutter test test/features/scan/tongue_scan_status_bridge_test.dart test/features/scan/tongue_scan_confirmation_policy_test.dart test/features/scan/tongue_scan_page_state_test.dart -r compact`：通过。
- `flutter analyze lib/features/scan/presentation/pages/tongue_scan_page.dart lib/features/scan/presentation/services/tongue_scan_status_bridge.dart lib/features/scan/presentation/services/tongue_scan_confirmation_policy.dart test/features/scan/tongue_scan_status_bridge_test.dart test/features/scan/tongue_scan_confirmation_policy_test.dart test/features/scan/tongue_scan_page_state_test.dart`：通过。
- `lsp_diagnostics`：`tongue_scan_page.dart`、`tongue_scan_status_bridge.dart`、`tongue_scan_confirmation_policy.dart` 以及三个相关测试文件均无诊断问题。
- `flutter test test/features/scan/tongue_scan_status_bridge_test.dart test/features/scan/tongue_scan_confirmation_policy_test.dart test/features/scan/tongue_scan_page_state_test.dart test/features/scan/scan_capture_geometry_test.dart -r compact`：通过。
- `flutter build apk --debug`：通过，成功产出 `build\\app\\outputs\\flutter-apk\\app-debug.apk`。
- Android 调试构建过程中仍提示仓库内既有 `en/ja/ko` 未翻译文案警告，不是本次改动新增。
- `grep` 核对：`tongueDetected`、`tongueOutScore`、`mouthOpenRatio`、`tongue/capture` 在 `lib/**/*.dart`、`test/**/*.dart`、`android/**/*.kt`、`ios/**/*.swift` 中已无活代码命中。
- `powershell.exe -Command ".\\gradlew.bat :app:compileDebugKotlin --console=plain; exit $LASTEXITCODE"`（workdir=`android/`）：通过，`BUILD SUCCESSFUL`。
- `lsp_diagnostics`：`tongue_scan_page.dart`、`tongue_scan_status_bridge.dart`、`tongue_scan_status_bridge_test.dart` 无诊断问题。
- iOS 本轮涉及 Swift 文件变更，但当前环境无 Xcode / `sourcekit-lsp`，未做本地 iOS 编译验证。

## 下次计划
- 真机回归一轮舌诊扫描，观察“仅张嘴但未伸舌”与“真实伸舌”两类场景下的通过率，确认代理规则是否仍需收紧/放宽。
- 如果真机上仍出现“代理启发式区分度不足”，下一步再评估是否需要升级 raw contract 或引入更强的 tongue-specific 视觉信号。
- 如后续继续清理跨端契约，再考虑删除 tongue 流里为迁移保留的 legacy `landmarks` 别名，只保留 `faceLandmarks`。

## 遗留风险
- 若当前 face/mouth 坐标对“真实伸舌”区分度不足，真机上仍可能出现误判或漏判，后续需要升级为更强的视觉信号或模型。
- iOS 编译验证依赖 macOS / Xcode，当前工作环境可能无法直接完成本地验证。
- tongue 流当前仍双写 `faceLandmarks` 与 legacy `landmarks`；这能降低迁移风险，但也意味着完全的字段收口还需要下一轮删除 legacy key。 
