# Session 020 - Google Pay 抽象层实现

## 做了什么
- 启动 Google Pay Flutter 抽象层实现，目标是在无后端阶段先补齐应用层模型、service 接口和 stub 实现，不接真实支付。
- 结合 `Google Pay 无后端阶段实施清单` 与当前 checkout 页现状，收敛本次实现范围：模型、mock session builder、GooglePayServiceStub、focused 单测。
- 编写 `.sisyphus/plans/google-pay-abstraction-layer.md` 作为当前实现计划，准备按 TDD 落地。
- 完成 TDD：先让 focused tests 编译失败 / 行为失败，再补最小实现，新增 `PaymentMethod`、`PaymentResult`、`CheckoutSession`、`GooglePayServiceStub`，并扩展 `buildMockCheckoutSession(...)`。
- 根据 Oracle 复核继续收紧 stub 语义：即便 `available=true`，也只返回 placeholder/unavailable 结果，不再表达 `authorizedPendingServer` 这类比当前阶段更强的状态。

## 变更前快照
- `report_checkout_page.dart` 已有 Google Pay 占位 UI，但应用层没有 `CheckoutSession`、`PaymentMethod`、`PaymentResult`、`GooglePayService`。
- `mock_product_checkout.dart` 仅返回金额预览，无法承载后续 checkout session 抽象。
- 项目尚未接入任何 Google Pay SDK 或真实支付链路。

## 涉及文件
- `lib/features/report/application/mock_product_checkout.dart`
- `lib/features/report/application/checkout_session.dart`
- `lib/features/report/application/payment_method.dart`
- `lib/features/report/application/payment_result.dart`
- `lib/features/report/application/google_pay_service.dart`
- `test/features/report/mock_product_checkout_test.dart`
- `test/features/report/google_pay_service_test.dart`
- `.sisyphus/plans/google-pay-abstraction-layer.md`

## 问题与决策
- 决策：先实现应用层抽象，不直接改 checkout 页调用链，避免把“占位 UI”误升级成“已接入真实支付”。
- 决策：按 TDD 先补 focused 测试，再写最小实现。
- 决策：保持 mock 语义清晰，stub 结果不得返回“已支付成功”。

## 验证结果
- `flutter test test/features/report/mock_product_checkout_test.dart test/features/report/google_pay_service_test.dart`：通过。
- `flutter analyze lib/features/report/application/mock_product_checkout.dart lib/features/report/application/payment_method.dart lib/features/report/application/payment_result.dart lib/features/report/application/checkout_session.dart lib/features/report/application/google_pay_service.dart test/features/report/mock_product_checkout_test.dart test/features/report/google_pay_service_test.dart`：通过。
- `lsp_diagnostics`：相关新增/修改 Dart 文件无错误。
- Oracle 只读复核：确认模型与 mock session builder 的方向正确；补充指出 `GooglePayServiceStub` 的 `available=true` 分支语义过强，该问题已继续修正并回归通过。

## 下次计划
- 如需继续推进，可让 checkout 页改为依赖这些抽象，而不是直接靠占位按钮与页面内 mock 状态。
- 如果后续进入 TEST 环境原型阶段，再单独新增 `GooglePayServicePrototype`，不要污染当前 stub 语义。

## 遗留风险
- 本次默认不接入 Google Pay SDK/插件，因此抽象层短期内仍可能是“未被页面消费”的准备代码。
