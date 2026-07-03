# 已接接口但 UI 未落地功能扫描

日期：2026-07-02

## 扫描口径

- 扫描范围：`lib/features/**/data/sources/*remote_source.dart` 中已经写入真实 `/api/...` 路径的远端方法。
- 对照范围：`lib/**` 中的 `presentation/`、`application/`、`providers/`、repository 调用。
- 本次只做静态扫描与源码核对，未运行 `flutter test`、`flutter analyze` 或 `dart format`，避免复现前几次 Dart/Flutter 命令卡住的问题。
- 静态脚本共识别 84 个已落地 HTTP 方法；其中 50 个方法没有 UI/应用层入口，另有 2 个“UI 有控件但默认未写后端”的边界项。

## 总结

已接上且 UI/应用层已经在用的能力包括：

- 认证主链路：密码登录/注册、验证码 challenge/send/captcha、验证码登录/注册聚合方法、微信小程序登录、退出登录。
- 个人中心：用户资料、积分、收货地址增删改查与默认地址。
- 扫描与问卷：舌/面/手上传、体质问卷下一题。
- 分享：分享人、分享触达、AppId 映射。
- 报告基础链路：报告详情、报告分享二维码、历史报告列表、商品/项目推荐、商品详情。

目前主要缺口集中在：

- 结算页仍是 mock 流程，订单、收银台、预支付、支付状态接口未进入 UI。
- 报告页有症状勾选 UI，但默认回调是 no-op，未写回 `addReportSymptom` / `deleteReportSymptom`。
- 报告编辑、附图、自述、归属重绑、同步、设备 token 等增强接口只有数据源方法。
- Survey report 的解锁、历史、对比、聊天结果、治疗建议、关联客户、下载令牌等功能没有 UI 入口。
- 首页运营内容、弹窗、审核开关、i18n locales、场景码、Angelica 扫码授权、订阅消息等通用移动端接口还没有 provider/page。
- 微信小程序注册接口已到 repository，但 Flutter UI 缺少 `phoneCode` 获取与绑定流程。

## 需要 UI/应用层补齐的接口

### 1. 结算、订单、支付

现状：`ReportCheckoutPage` 仍引用 `mock_product_checkout.dart`，订单预览由本地 `buildMockOrderPreview` 生成；提交按钮只是延迟后置为 mock 成功；Apple Pay / Google Pay 入口是占位弹窗。

| 数据源方法 | API | 缺少的 UI/应用层功能 |
| --- | --- | --- |
| `previewRetailOrder` | `POST /api/v1/saas/mobile/retail-orders/preview` | 用真实门店、SKU、配送地址生成订单预览。 |
| `submitRetailOrder` | `POST /api/v1/saas/mobile/retail-orders` | 提交真实零售订单并拿到订单号。 |
| `prepayRetailOrder` | `POST /api/v1/saas/mobile/retail-orders/{id}/prepay` | 零售订单预支付。 |
| `getRetailOrderDetail` | `GET /api/v1/saas/mobile/retail-orders/{id}` | 订单详情/提交后结果页。 |
| `getRetailSpuDetail` | `GET /api/v1/saas/mobile/retail-spus/{id}` | 商品详情页从真实 SPU/SKU 接口加载规格与库存。 |
| `getOrderCashier` | `GET /api/v1/saas/mobile/orders/{id}/cashier` | 收银台信息、支付方式与金额确认。 |
| `prepayOrder` | `POST /api/v1/saas/mobile/orders/{id}/prepay` | 通用订单预支付。 |
| `getOrderPayStatus` | `GET /api/v1/saas/mobile/orders/pay/status` | 支付后轮询/确认支付结果。 |

建议优先级：高。现有 UI 已有结算页骨架，最适合从 mock 切到真实接口链路。

### 2. 报告症状勾选持久化

现状：报告页已经有症状勾选交互，`report_widgets.dart` 会调用 `widget.addReportSymptom` / `widget.deleteReportSymptom`；但 `ReportPage` 默认注入的是 `_noopAddReportSymptom` / `_noopDeleteReportSymptom`，所以当前只改本地状态，不写后端。

| 数据源方法 | API | 缺少的 UI/应用层功能 |
| --- | --- | --- |
| `addReportSymptom` | `POST /api/v1/saas/mobile/physique/ai/diagnosis/report/symptom` | 把报告页症状选中动作接到真实新增接口。 |
| `deleteReportSymptom` | `DELETE /api/v1/saas/mobile/physique/ai/diagnosis/report/symptom` | 把报告页症状取消动作接到真实删除接口。 |

建议优先级：高。UI 已存在，只需要补 provider/application 层，把 `String reportId/symptomId` 转成接口需要的 `int`，并决定失败回滚还是保持当前乐观更新。

### 3. 报告详情、编辑与增强能力

| 数据源方法 | API | 可能对应的 UI 功能 |
| --- | --- | --- |
| `getReportDetailByToken` | `GET /api/v1/saas/mobile/ai/diagnosis/report/detail` | token 分享落地页或外部打开报告。 |
| `getPhysiqueReportDetailByToken` | `GET /api/v1/saas/mobile/physique/ai/diagnosis/report/detail` | 体质报告 token 详情页。 |
| `getMobilePhysiqueReports` | `GET /api/v1/saas/mobile/physique/report` | 移动端体质报告分页列表。当前历史页使用的是 `/api/v1/saas/physiques/reports`。 |
| `getPhysiqueTherapies` | `GET /api/v1/saas/mobile/physique/therapy` | 报告治疗/调理方案动态加载。 |
| `createTongueReport` | `POST /api/v1/saas/mobile/physique/report/tongue` | 舌诊报告创建链路。 |
| `modifyReportSex` | `POST /api/v1/saas/mobile/physique/report/sex/modify` | 报告性别修正入口。 |
| `getPreDiagnosisReport` | `GET /api/v1/saas/mobile/physique/report/pre/diagnosis` | 预诊断报告查看。 |
| `rebindReportOwner` | `POST /api/v1/saas/mobile/physique/report/owner/rebind` | 报告归属重绑。 |
| `syncReport` | `POST /api/v1/saas/mobile/physique/report/sync` | 报告同步到指定机构/门店/用户。 |
| `saveReportSelfDescription` | `POST /api/v1/saas/mobile/physique/ai/diagnosis/report/self/description` | 用户自述编辑保存。 |
| `uploadReportExtraImage` | `POST /api/v1/saas/mobile/physique/ai/diagnosis/report/extra/image/upload` | 报告附图上传。 |
| `removeReportExtraImage` | `DELETE /api/v1/saas/mobile/physique/ai/diagnosis/report/extra/image` | 报告附图删除。 |
| `getAiDetectDeviceConfig` | `GET /api/v1/saas/mobile/physique/ai/detect/device/config` | AI 检测设备配置读取。 |
| `activateAiDetectToken` | `POST /api/v1/saas/mobile/physique/ai/detect/token/active` / `POST /api/v1/saas/mobile/physique/ai/detect/token/activate` | 设备 token 激活。 |

建议优先级：中。这里多数需要产品先确定入口位置，例如报告详情页编辑面板、扫描前设备初始化、报告归属处理弹窗等。

### 4. 报告解锁、次数卡与权益

现状：报告详情页当前使用 `ReportUnlockService`，走本地 IAP/SharedPreferences 状态；还没有调用后端解锁、次数卡、锁定状态接口。

| 数据源方法 | API | 缺少的 UI/应用层功能 |
| --- | --- | --- |
| `unlockMobilePhysiqueReport` | `POST /api/v1/saas/mobile/physique/report/unlock` | 移动端体质报告后端解锁。 |
| `autoUnlockMobilePhysiqueReport` | `POST /api/v1/saas/mobile/physique/report/unlock/auto` | 次数卡/权益自动解锁。 |
| `getSurveyReportLockedStatus` | `GET /api/v1/saas/physiques/reports/{id}/locked-status` | 进入报告前刷新锁定状态。 |
| `getTimesCardReports` | `GET /api/v1/saas/physiques/reports/times-card-reports` | 次数卡可解锁报告列表。 |
| `unlockSurveyReport` | `POST /api/v1/saas/physiques/reports/unlock` | Survey report 手动解锁。 |
| `autoUnlockSurveyReport` | `POST /api/v1/saas/physiques/reports/auto-unlock` | Survey report 自动解锁。 |

建议优先级：中高。这里会影响付费/权益语义，需要先明确 App Store/Google Play 支付与服务端权益确认的边界。

### 5. Survey report 高级能力

| 数据源方法 | API | 可能对应的 UI 功能 |
| --- | --- | --- |
| `getSurveyReportDetail` | `GET /api/v1/saas/physiques/reports/{id}` | Survey report 详情页。 |
| `getSurveyReportHistory` | `GET /api/v1/saas/physiques/reports/{id}/history` | 单份报告历史版本。 |
| `compareSurveyReports` | `GET /api/v1/saas/physiques/reports/compare` | 多份报告对比视图。 |
| `getSurveyReportChatResult` | `GET /api/v1/saas/physiques/reports/{id}/chat-result` | AI 问答/聊天结论展示。 |
| `saveSurveyReportTreatmentSuggestion` | `PUT /api/v1/saas/physiques/reports/{id}/treatment-suggestion` | 治疗建议编辑保存。 |
| `relateSurveyReportCustomer` | `PUT /api/v1/saas/physiques/reports/{id}/customer` | 报告关联客户。 |
| `createSurveyReportDownloadToken` | `POST /api/v1/saas/physiques/reports/{id}/download-token` | 生成报告下载/分享 token。 |
| `getSurveyReportByToken` | `GET /api/v1/saas/physiques/reports/token-detail` | 通过 token 打开 Survey report。 |

建议优先级：中。建议先从“报告历史”和“报告对比”拆成独立页面，再决定治疗建议/客户关联是否属于移动端权限。

### 6. 首页运营、审核、场景码、订阅消息

现状：`MobileUtilityRemoteSource` 已有 11 个方法，但没有 repository/provider/page 调用；首页仍是本地静态入口。

| 数据源方法 | API | 可能对应的 UI 功能 |
| --- | --- | --- |
| `getCurrentIndexPopup` | `GET /api/v1/saas/mobile/index/popup` | 首页弹窗/运营活动。 |
| `getIndexContent` | `GET /api/v1/saas/mobile/index/content` | 首页内容位、视频/图文模块。 |
| `getAuditingCheck` | `GET /api/v1/saas/mobile/auditing/check` | 审核模式/上架审核开关。 |
| `getSupportedLocales` | `GET /api/v1/saas/mobile/i18n/locales/supported` | 服务端支持语言列表。 |
| `getAngelicaLoginQrCode` | `GET /api/v1/saas/mobile/angelica/login/qrcode` | Angelica 登录二维码。 |
| `getToolMiniApps` | `GET /api/v1/saas/mobile/angelica/tool/mini/apps` | 工具小程序列表。 |
| `authorizeAngelicaScanLogin` | `POST /api/v1/saas/mobile/login/authorize/ang` | Angelica 扫码登录授权确认。 |
| `parseSceneCode` | `POST /api/v1/saas/mobile/scene/parse` | 扫码/深链 scene code 解析。 |
| `getSceneImageUrl` | `GET /api/v1/saas/mobile/scene/image/url` | 场景码图片生成/展示。 |
| `subscribeUserMessage` | `POST /api/v1/saas/mobile/user/sub/msg/subscribe` | 订阅消息确认。 |
| `getUserMessageKeepingFlag` | `GET /api/v1/saas/mobile/user/sub/msg/template/keeping/flag` | 查询订阅保持状态。 |

建议优先级：取决于产品是否需要动态首页和扫码授权。若需要，先补 `MobileUtilityRepository` 与首页 provider，再分批替换静态首页模块。

### 7. 认证边界项

| 方法 | API | 当前状态 |
| --- | --- | --- |
| `registerWithWechatMiniProgram` | `POST /api/v1/saas/mobile/auth/register/wechat-mini-program` | 数据源、repository 已有；UI 目前只接了微信小程序登录，缺少获取 `phoneCode` 后完成注册的流程。 |
| `loginByVerificationCode` | `POST /api/v1/saas/mobile/auth/login/verification-code` | repository 已暴露拆分方法，但 UI 当前通过 `authenticateVerificationCode(scene: login)` 调同一路径。不是接口缺失，只是拆分方法未直接使用。 |
| `registerByVerificationCode` | `POST /api/v1/saas/mobile/auth/register/verification-code` | repository 已暴露拆分方法，但 UI 当前通过 `authenticateVerificationCode(scene: register)` 调同一路径。不是接口缺失，只是拆分方法未直接使用。 |

建议优先级：微信小程序注册为中；验证码拆分方法为低，除非要把 UI 从聚合方法改成显式登录/注册方法。

## 特别说明

- `getLatestReport` 是 `ReportRemoteSource` 的未使用便捷方法，内部复用 `/api/v1/saas/physiques/reports`；同一路径已经通过 `getAllReports` 接入历史页，所以不单独算一个未落地接口，但可以作为“首页最近一次报告卡片”的候选能力。
- `addReportSymptom` / `deleteReportSymptom` 在静态引用里会被识别为 UI 已调用，因为同名回调在 widget 中存在；人工复核后确认默认实现仍是 no-op，属于“UI 控件已有但后端未接”的半成品。
- 个人中心、扫描、分享模块未发现“数据源已接但 UI 完全未触达”的新增接口。

## 建议落地顺序

1. 结算页从 mock 切换到 `previewRetailOrder -> submitRetailOrder -> getOrderCashier/prepay -> getOrderPayStatus`。
2. 报告症状勾选接入 `addReportSymptom` / `deleteReportSymptom`，补失败提示或回滚策略。
3. 报告解锁从本地 IAP 状态补上服务端锁定状态和权益解锁确认。
4. 报告编辑能力按入口拆小：自述、附图、性别修正、归属重绑、下载 token。
5. 首页运营能力先加 repository/provider，再决定动态首页、审核模式、场景码、订阅消息是否进入首屏。
6. 微信小程序注册先补 `phoneCode` 获取与注册页状态，再启用 `registerWithWechatMiniProgram`。
