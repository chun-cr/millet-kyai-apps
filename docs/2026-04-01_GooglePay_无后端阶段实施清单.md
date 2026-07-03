# Google Pay 无后端阶段实施清单（stitch_diag_demo）

## 1. 文档目标

本文档用于说明：在当前 **`stitch_diag_demo` 项目尚未具备后端支付能力** 的情况下，Google Pay 可以先推进到哪一步、项目内应该先准备哪些结构、需要改哪些文件，以及未来后端接入时建议遵循的接口契约。

目标不是“先伪造支付成功”，而是：

1. 先完成 **Google Pay / Android 工程 / Flutter 客户端结构准备**
2. 保持当前 mock checkout 语义清晰
3. 让未来接真实 Google Pay 时尽量少改页面层

---

## 2. 当前项目现状

基于当前仓库代码，Google Pay 目前处于 **UI 占位阶段**。

### 2.1 当前已存在的相关文件

- `lib/features/report/presentation/pages/report_checkout_page.dart`
  - 已有 Google Pay 占位按钮入口
  - 已有支付方式区域内的 Google Pay 卡片
  - 当前点击只弹说明，不是真实支付
- `lib/features/report/application/mock_product_checkout.dart`
  - 当前只负责 mock 金额预览 / mock checkout 计算
- `lib/core/router/app_router.dart`
  - checkout 页面已有独立路由，适合后续局部升级
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_ko.arb`
  - 已补齐 Google Pay 占位文案
- `pubspec.yaml`
  - 当前没有 Google Pay 专用 Flutter 依赖

### 2.2 当前缺失的关键项

- 当前没有 Android Google Pay SDK / Flutter `pay` 插件接线
- 当前没有 Google Pay `PaymentsClient` / `isReadyToPay()` / `PaymentDataRequest` 实现
- 当前没有 Google Pay 商户 / PSP / gateway 实际配置
- 当前没有后端 checkout session / payment confirm 接口
- 当前没有真实 token 提交与确认链路

### 2.3 重要结论

当前项目不是“差最后一小步就能真实收款”，而是处于：

> **前端 mock checkout + Google Pay 占位入口**

因此当前阶段最合理的目标应是：

> **先把 Google Pay 做到“结构就绪、工程就绪、配置就绪”，而不是“先假装真实可支付”。**

---

## 3. 没有后端时，Google Pay 可以做到哪一步

## 3.1 现在就能做的

1. Android / Google Pay 工程条件确认
2. Flutter checkout / payment 抽象层设计
3. Google Pay 客户端服务接口设计
4. mock checkout session 模型设计
5. 页面状态机从“mock 按钮”升级为“待接真实支付方式”
6. 如果后续引入客户端 SDK，可做到 TEST 环境原型接线准备

## 3.2 现在做不了的

1. 真实扣款
2. 后端验 Google Pay payment data / token
3. 服务端创建可信支付订单
4. 对账、补单、退款、支付状态闭环
5. 可信“支付成功”结果

## 3.3 最好情况下能做到哪里

如果后续补上客户端 SDK/插件，但仍没有后端，那么最多可以做到：

- 检测设备是否支持 Google Pay（`isReadyToPay()`）
- 展示正式样式的 Google Pay 按钮
- 在 `ENVIRONMENT_TEST` 下拉起 Google Pay 支付面板原型
- 拿到测试环境返回的 `PaymentData`

但即使做到这里，也仍然不能把结果定义为：

> “真实支付成功”

因为 Google 官方也明确：**测试环境不会返回可用于真实扣款的 live chargeable token**，订单是否成功仍必须以后端处理结果为准。

---

## 4. Google 官方前置条件（当前就应明确）

Google Pay for Android 官方文档指出，接入前至少要明确以下几类条件。

## 4.1 App 基础条件

Google 官方 setup 文档给出的前提包括：

- App 通过 **Google Play Store** 分发
- Android app 满足最低构建条件：
  - `minSdkVersion` 足够高
  - `compileSdkVersion` 足够高
- 设备上安装 Google Wallet，并已添加支付方式（用于测试）

### 对当前项目的直接含义

当前项目仍是 Flutter 多平台工程，Google Pay 真正接入时应补查：

- `android/app/build.gradle` 或 `build.gradle.kts`
- 当前 `minSdkVersion`
- 当前 `compileSdkVersion`

如果不满足官方要求，需要先升级 Android 构建配置。

## 4.2 商户 / 支付处理路径要先选定

Google Pay Android 教程明确要求你在请求里定义 tokenization 配置，常见做法有：

- `PAYMENT_GATEWAY`
- `DIRECT`

对你这个项目来说，**无后端阶段最不该现在拍脑袋决定的，是“真实 token 后面交给谁处理”**。

所以你需要先确定：

1. 未来使用哪家 PSP / gateway（例如 Adyen、Checkout.com、Braintree、Stripe 等）
2. 是走 gateway tokenization，还是更底层 direct tokenization
3. 未来后端谁负责 payment data 解密 / 转发 / 确认

### 当前阶段建议

> 先把客户端结构准备好，但先不在代码里固化真实 gateway 参数。

## 4.3 TEST 环境是官方允许的前置准备阶段

Google 官方 integration checklist 明确提到：

- 集成前要在 `WalletConstants.ENVIRONMENT_TEST` 下完成测试
- TEST 环境可以验证购买流程、地址、联系信息、确认页等
- TEST 环境不会返回真实可扣款 token

这意味着：

> 没有后端时，你最多做到 **TEST 环境前端原型 / 客户端结构准备**，不能把它当成真实支付完成。

---

## 5. Android 工程层实施清单

Google Pay 的重点不在 iOS entitlement，而在 **Android 依赖、能力检测、PaymentsClient 配置**。

## 5.1 当前需要重点检查的文件

- `android/app/build.gradle` 或 `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`

## 5.2 真正接入前需要补的 Android 项

### A. Google Pay 依赖

Google 官方 setup 文档给出的 Android 依赖是：

```gradle
implementation 'com.google.android.gms:play-services-wallet:19.5.0'
```

如果你后续走 Flutter 封装（例如 `pay` 插件），则该依赖可能由插件带入，但本质上底层仍依赖 Google Pay Android 能力。

### B. Android 构建版本检查

需要确认：

- `minSdkVersion`
- `compileSdkVersion`

是否达到 Google 官方要求。

### C. Google Wallet / Google Pay 运行环境验证

正式进入原型阶段前，测试设备需要：

- 安装 Google Wallet
- 登录可用 Google 账号
- 添加测试支付卡

---

## 6. Flutter 客户端结构改造清单

和 Apple Pay 一样，当前建议先做“抽象层”，不要直接把 Google Pay SDK/插件调用写死在页面里。

---

## 6.1 建议新增的应用层模型

### 建议新增文件

- `lib/features/report/application/checkout_session.dart`
- `lib/features/report/application/payment_method.dart`
- `lib/features/report/application/payment_result.dart`

### 目标

让 `report_checkout_page.dart` 不再直接依赖 mock 计算和硬编码状态，而是依赖稳定的 checkout / payment 抽象。

---

## 6.2 CheckoutSession 建议字段

```dart
class CheckoutSession {
  final String sessionId;
  final List<CheckoutItem> items;
  final int subtotalCents;
  final int shippingFeeCents;
  final int serviceFeeCents;
  final int totalCents;
  final String currencyCode;
  final String countryCode;
  final List<PaymentMethod> supportedPaymentMethods;
  final String status;
}
```

### 说明

即使现在没有后端，这个对象也可以先由 mock builder 返回。

后面切到真实后端时，只替换数据来源，不需要重写页面结构。

---

## 6.3 PaymentMethod 建议定义

```dart
enum PaymentMethod {
  mock,
  applePay,
  googlePay,
}
```

### 当前项目提示

你现在已经在 checkout UI 里同时展示 Apple Pay 和 Google Pay，所以这里建议尽快把枚举补成三态，而不是继续靠按钮分支散落在页面里。

---

## 6.4 PaymentResult 建议字段

```dart
class PaymentResult {
  final String status;
  final String? sessionId;
  final String? paymentId;
  final String? orderId;
  final String? message;
  final bool isMock;
}
```

状态建议可包含：

- `mock_success`
- `authorized_pending_server`
- `confirmed`
- `failed`
- `cancelled`

---

## 6.5 mock_product_checkout.dart 的建议演进

### 当前文件

- `lib/features/report/application/mock_product_checkout.dart`

### 当前职责

- 只负责金额预览计算

### 建议升级

保留 `buildMockOrderPreview(...)`，同时新增：

```dart
CheckoutSession buildMockCheckoutSession(...)
```

让 mock 层从“只算金额”变成“完整模拟 checkout session”。

### 好处

- 页面逻辑先对齐未来后端返回结构
- 后续后端接入时只替换实现
- 当前仍然不伪造真实支付成功

---

## 6.6 建议新增 GooglePayService 抽象

### 建议新增文件

- `lib/features/report/application/google_pay_service.dart`

### 建议接口

```dart
abstract class GooglePayService {
  Future<bool> isGooglePayAvailable();
  Future<PaymentResult> presentGooglePaySheet(CheckoutSession session);
  Future<void> prepareGooglePay();
}
```

### 当前无后端阶段建议实现

#### `GooglePayServiceStub`

用途：

- 保留接口形状
- 明确告诉页面：能力已预留，但当前没有真实支付完成链路

不要让它返回“已支付成功”。

#### 后续原型阶段可新增

`GooglePayServicePrototype`

职责：

- 在 `ENVIRONMENT_TEST` 下完成客户端原型
- 最多推进到 `authorized_pending_server`
- 不直接宣称支付成功

---

## 7. report_checkout_page.dart 逐点改造建议

### 当前文件

- `lib/features/report/presentation/pages/report_checkout_page.dart`

### 当前问题

1. Apple Pay / Google Pay 当前都是说明弹窗
2. mock 下单逻辑直接写在页面里
3. 页面直接使用 `_isSubmittedMock`
4. 支付方式分支仍未抽象成统一 checkout 状态机

---

## 7.1 页面层应该保留的职责

页面只负责：

- 收集地址信息
- 触发创建 checkout session
- 选择支付方式
- 展示当前状态

页面不应该长期负责：

- 模拟支付成功业务
- Google Pay 实现细节
- 真实支付状态确认

---

## 7.2 页面建议新增状态机

建议在页面或 ViewModel 层引入：

```dart
enum CheckoutUiState {
  idle,
  creatingSession,
  presentingGooglePay,
  mockSuccess,
  paymentAuthorizedPendingServer,
  paymentFailed,
}
```

### 说明

这样即使现在没有后端，也可以先把页面状态机做对。

未来只替换状态来源，不需要推翻 UI。

---

## 7.3 Google Pay 按钮的目标语义

### 当前

- 占位按钮
- 只弹说明

### 建议演进

#### 阶段 A（当前推荐）
- 按钮仍可点击
- 但调用 `GooglePayServiceStub`
- 返回“客户端结构已准备，等待真实支付能力/后端接入”

#### 阶段 B（后续可做）
- 按钮按 `isReadyToPay()` 结果显示/置灰
- 可拉起 Google Pay TEST 环境原型
- 不直接宣称支付完成

---

## 7.4 文案层

当前已存在以下相关 key：

- `reportProductCheckoutGooglePayTitle`
- `reportProductCheckoutGooglePaySubtitle`
- `reportProductCheckoutGooglePayDialogBody`

当前阶段可以继续复用。

如果后续要从“纯占位”升级成“客户端已准备、后端未接入”，再补更准确文案即可。

---

## 8. 依赖与接入策略建议

## 8.1 当前依赖状态

### `pubspec.yaml`

当前没有：

- Google Pay 专用 Flutter 依赖
- Android wallet 支付层封装

## 8.2 建议策略

### 当前阶段

> 先做抽象层，不急着加 Google Pay Flutter 插件。

原因：

1. 没有后端时，过早接插件会造成“前端能拉起，但支付闭不了环”
2. 如果后续 PSP 方案变更，前端很容易返工
3. Google Pay 的 tokenization 路径和 PSP 强绑定，不宜过早写死

### 建议顺序

1. 先抽象 checkout / payment service / session model
2. 再决定 Google Pay 的客户端接法：
   - Flutter `pay` 插件
   - 原生 Android bridge 到 `PaymentsClient`
   - PSP 官方 Android 方案

---

## 9. 后续后端接口草案

这一部分建议你现在就定下来，即使后端代码还没开始写。

---

## 9.1 创建 Checkout Session

### 接口

```http
POST /api/checkout/sessions
```

### 请求示例

```json
{
  "productId": "herbal-moxa-kit",
  "quantity": 1,
  "shippingAddress": {
    "recipient": "陈清和",
    "phone": "13800001234",
    "line1": "上海市徐汇区漕溪北路 88 号 18 楼"
  },
  "paymentMethod": "google_pay"
}
```

### 返回示例

```json
{
  "sessionId": "chk_20260401_xxx",
  "items": [
    {
      "productId": "herbal-moxa-kit",
      "name": "艾灸调理礼盒",
      "quantity": 1,
      "unitPriceCents": 39900
    }
  ],
  "subtotalCents": 39900,
  "shippingFeeCents": 1200,
  "serviceFeeCents": 0,
  "totalCents": 41100,
  "currencyCode": "CNY",
  "countryCode": "CN",
  "supportedPaymentMethods": ["google_pay"],
  "status": "pending"
}
```

### 作用

- 由后端返回权威金额
- 不再相信前端自己算的最终金额
- 作为后续支付确认的基准对象

---

## 9.2 确认 Google Pay 支付

### 接口

```http
POST /api/payments/google-pay/confirm
```

### 请求示例

```json
{
  "sessionId": "chk_20260401_xxx",
  "googlePayPaymentData": {
    "paymentMethodData": {
      "description": "Visa •••• 8888",
      "tokenizationData": {
        "type": "PAYMENT_GATEWAY",
        "token": "..."
      }
    }
  },
  "idempotencyKey": "8c1e0c5d-xxxx-xxxx-xxxx",
  "billingAddress": {
    "countryCode": "CN"
  },
  "shippingAddress": {
    "recipient": "陈清和",
    "phone": "13800001234"
  }
}
```

### 返回示例

```json
{
  "paymentId": "pay_xxx",
  "orderId": "ord_xxx",
  "status": "authorized",
  "failureCode": null,
  "failureMessage": null
}
```

### 关键原则

Google Pay 客户端授权成功 ≠ 订单支付成功。

必须以服务端确认结果为准。

---

## 9.3 查询最终状态

### 接口候选

```http
GET /api/checkout/sessions/{sessionId}
```

或：

```http
GET /api/orders/{orderId}
```

### 用途

- 轮询支付结果
- 页面恢复支付状态
- 失败重试与结果回显

---

## 10. Google Pay 商户 / PSP 规划建议

Google Pay 官方教程和集成清单反复强调：

- 你必须明确 tokenization 方式
- 必须确认处理器/网关支持的卡网络与认证方式
- 必须在测试环境完成功能和品牌检查

### 对这个项目的建议

在没有后端前，建议先输出一份内部决策表，至少确定：

1. 未来是走哪家 PSP / gateway
2. 是否使用 `PAYMENT_GATEWAY` 模式
3. 你们后端谁负责支付确认
4. `allowedCardNetworks` / `allowedAuthMethods` 准备支持哪些
5. 目标国家/地区是否支持 Google Pay 卡处理链路

---

## 11. 建议的分阶段推进顺序

## 阶段 1：Android 与 Google Pay 基础准备

1. 确认目标发布渠道与 Android 构建配置满足官方条件
2. 确认测试设备具备 Google Wallet 环境
3. 确定 PSP / gateway 路径
4. 评估是否引入 Flutter 插件或原生 bridge

## 阶段 2：Flutter 结构准备

1. 新增 `CheckoutSession`
2. 新增 `PaymentMethod`（含 `googlePay`）
3. 新增 `PaymentResult`
4. 新增 `GooglePayService` 抽象
5. 将 `mock_product_checkout.dart` 升级为 mock session builder
6. 改造 `report_checkout_page.dart` 的页面状态机

## 阶段 3：客户端原型阶段（仍无后端）

1. `isReadyToPay()` 能力检测
2. Google Pay 按钮按可用性显示
3. `ENVIRONMENT_TEST` 下拉起客户端原型
4. 状态最多推进到 `authorized_pending_server`

## 阶段 4：后端接入阶段

1. 创建 checkout session 接口
2. Google Pay confirm 接口
3. 查询最终订单/支付状态接口
4. 幂等、对账、补单、退款流程

---

## 12. 对当前项目最实用的建议

对于 `stitch_diag_demo` 当前状态，最合理的策略不是“现在把 Google Pay 直接接通”，而是：

> **先把 Google Pay 从“占位按钮”升级成“结构完整、工程就绪、等待后端接入的正式支付方式”。**

这样做的收益是：

1. 当前 checkout 页面不会返工重写
2. 后续只需要替换 service / session 数据来源
3. Android / 客户端准备可以先完成
4. 产品、后端、客户端可以先围绕同一份接口契约工作

---

## 13. 一句话总结

### 现在可以完成的目标

**Google Pay UI / Android 接线准备 + Flutter 结构准备 + TEST 原型准备 + 后端 contract 设计**

### 现在不能承诺的目标

**真实支付完成与可信支付成功**

因为这一步必须依赖后端确认。
