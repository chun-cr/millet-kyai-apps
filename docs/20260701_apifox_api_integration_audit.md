# Apifox 接口对接记录

日期：2026-07-01

来源：`api/默认模块.openapi.json`

## 扫描口径

- OpenAPI operation 总数：462。
- 本次按移动端 Flutter App 相关口径筛选：`/api/v1/saas/mobile/**`、`/api/v1/saas/physiques/reports**`、`Mobile*`、`Mb*`、`RetailOrder`、`RetailTrade`，共 90 个 operation。
- 生产源码扫描范围：`lib/**/*.dart` 中实际发起后端请求的路径。
- 生产源码已接入：89 / 90 个移动端/报告相关 operation。
- 生产源码未接入：1 / 90 个移动端/报告相关 operation。
- 其余 372 个 operation 主要是后台、平台管理、配置、库存、支付通知、组织员工、设备注册等服务端/运营端接口，当前 Flutter App 不直接对接。

## 本次复核结论

移动端/报告筛选口径下仍有 1 个 Apifox operation 未在生产源码中接入：

| Method | Path | Apifox operationId | 当前状态 | 建议 |
| --- | --- | --- | --- | --- |
| `POST` | `/api/v1/saas/mobile/auth/login-or-register/verification-code` | `MobileAuth_loginOrRegisterByVerificationCode` | 仅在测试 mock 中出现，`lib/` 生产代码没有实际请求；当前生产链路按场景分流到 `login/verification-code` 或 `register/verification-code` | 如果后端期望统一“验证码登录或注册”入口，需要在 `AuthRemoteSource` / `AuthRepository` 补方法并替换页面调用；如果产品明确采用登录、注册拆分入口，则保持不接入，并把测试 mock 改为拆分后的真实路径 |

相关生产代码现状：

- `lib/features/auth/data/sources/auth_remote_source.dart` 的 `authenticateVerificationCode` 根据 `VerificationCodeScene` 选择：
  - `POST /api/v1/saas/mobile/auth/login/verification-code`
  - `POST /api/v1/saas/mobile/auth/register/verification-code`
- `POST /api/v1/saas/mobile/auth/login-or-register/verification-code` 未在 `lib/` 中找到实际调用。
- 该路径目前出现在若干页面测试 mock 中，例如登录页、注册页、邀请码/验证码流程测试；这不等同于生产接入。

## 本次新增或补齐

认证：

- `POST /api/v1/saas/mobile/auth/login/password`
- `POST /api/v1/saas/mobile/auth/register/password`
- `POST /api/v1/saas/mobile/auth/login/wechat-mini-program`
- `POST /api/v1/saas/mobile/auth/register/wechat-mini-program`
- `POST /api/v1/saas/mobile/auth/tokens/refresh`
- `POST /api/v1/saas/mobile/auth/logout`
- `POST /api/v1/saas/mobile/auth/verification-code/challenge`
- `POST /api/v1/saas/mobile/auth/verification-code/captcha/verify`
- `POST /api/v1/saas/mobile/auth/verification-code/send`
- `POST /api/v1/saas/mobile/auth/login/verification-code`
- `POST /api/v1/saas/mobile/auth/register/verification-code`
- 落点：`lib/features/auth/data/sources/auth_remote_source.dart`、`lib/core/network/interceptors/auth_interceptor.dart`
- 说明：验证码登录/注册当前采用拆分接口；微信小程序注册已补数据层和仓库层方法，但当前 Flutter App 还缺 `phoneCode` 获取链路，暂不挂 UI。

个人中心、积分、收货地址：

- `GET /api/v1/saas/mobile/user/me`
- `POST /api/v1/saas/mobile/point/signin`
- `GET /api/v1/saas/mobile/point/account/info/simple`
- `GET /api/v1/saas/mobile/point/account/stat`
- `GET /api/v1/saas/mobile/point/tasks`
- `GET /api/v1/saas/mobile/point/account/log`
- `GET /api/v1/saas/mobile/receiving-addresses`
- `POST /api/v1/saas/mobile/receiving-addresses`
- `GET /api/v1/saas/mobile/receiving-addresses/default`
- `GET /api/v1/saas/mobile/receiving-addresses/{id}`
- `PUT /api/v1/saas/mobile/receiving-addresses/{id}`
- `DELETE /api/v1/saas/mobile/receiving-addresses/{id}`
- `PUT /api/v1/saas/mobile/receiving-addresses/{id}/default`
- 落点：`lib/features/profile/data/sources/profile_remote_source.dart`

扫描上传、问卷与分享：

- `POST /api/v1/saas/mobile/ai/diagnosis/upload`
- `POST /api/v1/saas/mobile/ai/diagnosis/upload/face`
- `POST /api/v1/saas/mobile/ai/diagnosis/upload/hand`
- `POST /api/v1/saas/mobile/physique/question/next`
- `GET /api/v1/saas/mobile/shares/me`
- `POST /api/v1/saas/mobile/shares/touches`
- `GET /api/v1/saas/mobile/appId/mapping`
- 落点：`lib/features/scan/data/sources/scan_remote_source.dart`、`lib/features/scan/data/sources/physique_question_remote_source.dart`、`lib/features/share/data/sources/share_remote_source.dart`

订单、支付、零售商品：

- `POST /api/v1/saas/mobile/retail-orders/preview`
- `POST /api/v1/saas/mobile/retail-orders`
- `POST /api/v1/saas/mobile/retail-orders/{id}/prepay`
- `GET /api/v1/saas/mobile/retail-orders/{id}`
- `GET /api/v1/saas/mobile/retail-spus/{id}`
- `GET /api/v1/saas/mobile/orders/{id}/cashier`
- `POST /api/v1/saas/mobile/orders/{id}/prepay`
- `GET /api/v1/saas/mobile/orders/pay/status`
- 落点：`lib/features/report/data/sources/report_remote_source.dart`
- 说明：现有结算页仍是 mock 提交流程；本次先接通数据源，后续需要结合真实 SKU、门店、地址和支付渠道再替换 UI 流程。

AI 问诊、体质报告、报告编辑：

- `GET /api/v1/saas/mobile/ai/diagnosis/report/{id}`
- `GET /api/v1/saas/mobile/ai/diagnosis/report/detail`
- `GET /api/v1/saas/mobile/physique/ai/diagnosis/report/{id}/share/qrcode`
- `GET /api/v1/saas/mobile/physique/product/{productId}`
- `GET /api/v1/saas/mobile/physique/products`
- `GET /api/v1/saas/mobile/physique/products/by/token`
- `GET /api/v1/saas/mobile/physique/project`
- `GET /api/v1/saas/mobile/physique/project/by/token`
- `GET /api/v1/saas/mobile/physique/therapy`
- `POST /api/v1/saas/mobile/physique/report/tongue`
- `POST /api/v1/saas/mobile/physique/report/sex/modify`
- `GET /api/v1/saas/mobile/physique/report/pre/diagnosis`
- `GET /api/v1/saas/mobile/physique/ai/diagnosis/report/detail`
- `GET /api/v1/saas/mobile/physique/report`
- `POST /api/v1/saas/mobile/physique/report/owner/rebind`
- `POST /api/v1/saas/mobile/physique/report/sync`
- `POST /api/v1/saas/mobile/physique/ai/diagnosis/report/symptom`
- `DELETE /api/v1/saas/mobile/physique/ai/diagnosis/report/symptom`
- `POST /api/v1/saas/mobile/physique/ai/diagnosis/report/self/description`
- `POST /api/v1/saas/mobile/physique/ai/diagnosis/report/extra/image/upload`
- `DELETE /api/v1/saas/mobile/physique/ai/diagnosis/report/extra/image`
- `POST /api/v1/saas/mobile/physique/report/unlock`
- `POST /api/v1/saas/mobile/physique/report/unlock/auto`
- `GET /api/v1/saas/mobile/physique/ai/detect/device/config`
- `POST /api/v1/saas/mobile/physique/ai/detect/token/active`
- `POST /api/v1/saas/mobile/physique/ai/detect/token/activate`
- 落点：`lib/features/report/data/sources/report_remote_source.dart`
- 说明：接口已具备可调用方法。症状、自述、附图、设备 token、报告归属重绑等能力当前缺少明确页面入口。

通用报告查询与解锁：

- `GET /api/v1/saas/physiques/reports`
- `GET /api/v1/saas/physiques/reports/{id}/locked-status`
- `GET /api/v1/saas/physiques/reports/times-card-reports`
- `POST /api/v1/saas/physiques/reports/unlock`
- `POST /api/v1/saas/physiques/reports/auto-unlock`
- `GET /api/v1/saas/physiques/reports/{id}`
- `GET /api/v1/saas/physiques/reports/{id}/history`
- `GET /api/v1/saas/physiques/reports/compare`
- `GET /api/v1/saas/physiques/reports/{id}/chat-result`
- `PUT /api/v1/saas/physiques/reports/{id}/treatment-suggestion`
- `PUT /api/v1/saas/physiques/reports/{id}/customer`
- `POST /api/v1/saas/physiques/reports/{id}/download-token`
- `GET /api/v1/saas/physiques/reports/token-detail`
- 落点：`lib/features/report/data/sources/report_remote_source.dart`
- 说明：当前历史列表仍使用已有分页接口；新增接口先作为数据源能力，后续可用于详情增强、对比、下载令牌、次数卡解锁等流程。

首页、场景码、扫码授权、订阅消息：

- `GET /api/v1/saas/mobile/index/popup`
- `GET /api/v1/saas/mobile/index/content`
- `GET /api/v1/saas/mobile/auditing/check`
- `GET /api/v1/saas/mobile/i18n/locales/supported`
- `GET /api/v1/saas/mobile/angelica/login/qrcode`
- `GET /api/v1/saas/mobile/angelica/tool/mini/apps`
- `POST /api/v1/saas/mobile/login/authorize/ang`
- `POST /api/v1/saas/mobile/scene/parse`
- `GET /api/v1/saas/mobile/scene/image/url`
- `POST /api/v1/saas/mobile/user/sub/msg/subscribe`
- `GET /api/v1/saas/mobile/user/sub/msg/template/keeping/flag`
- 落点：`lib/features/home/data/sources/mobile_utility_remote_source.dart`
- 说明：这些接口参数明确，已接通数据源；当前 Flutter App 尚未接入首页运营内容、Angelica 扫码授权和订阅消息 UI。

## 仍未接入 Flutter App 的接口

按本次移动端/报告筛选口径：仍有 1 个 operation 未在生产源码中接入。

- `POST /api/v1/saas/mobile/auth/login-or-register/verification-code`

按 Apifox 全量导出口径：仍有 373 个 operation 未接入 Flutter App。其中 1 个属于移动端/报告筛选口径，372 个属于非移动端/非 App 直连接口。主要原因：

- 后台/管理端接口：`AdminBff`、`AdminSession`、`Access`、`Tenant`、`OrgEmployee`、`OrgStore`、`OrgNode` 等。
- 平台配置接口：`ConfigDictionary`、`ConfigTemplate`、`ConfigI18nResource`、`ConfigTenantParam`、`Catalog` 等。
- 运营内容/商品平台接口：`ContentAdvertisement`、`ContentMedia`、`PhysiqueProduct`、`PhysiqueProject`、`PhysiquePlatformProduct`、`PhysiquePlatformProject` 等。
- 库存/支付服务端接口：`Inventory`、`Payment`、`PaymentNotify`、`Order` 等。
- 设备管理和平台查询接口：`AiDeviceRegistry`、`AiDetectQuery`、`AiDeviceToken`、`AiDetectOrder`、`SurveyReportPlatform` 等。

这些接口当前更像管理后台、服务端回调、平台运营或设备管理能力，不建议直接放进移动 App，除非产品明确需要对应前端场景和权限模型。

## 后续建议

1. 先确认验证码流程是否要统一走 `login-or-register/verification-code`。若要统一，补生产数据源、仓库方法和页面调用；若继续拆分登录/注册接口，清理测试中的旧统一路径 mock。
2. 用真实门店、SKU、收货地址和支付渠道把结算页从 mock 流程切到 `retail-orders` / `orders` 接口。
3. 为报告详情页补“症状、自述、附图、下载令牌、报告对比”的产品入口后，再把新增数据源方法收敛成领域模型。
4. 若 Flutter App 需要承接微信小程序注册，先补齐 `phoneCode` 获取方式，再启用 `registerWithWechatMiniProgram`。
5. 后续 Apifox 重新导出后，可用同一筛选口径复查：移动端相关 operation 应全部能在 `lib/` 中找到对应生产请求路径。
