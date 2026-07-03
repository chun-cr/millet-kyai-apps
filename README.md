# millet-kyai-apps

`millet-kyai-apps` 是一个 Flutter 移动端诊断类 Demo 项目，当前覆盖了登录鉴权、拍摄扫描、报告查看、历史记录、分享落地页、支付接入预研等核心流程。这个仓库更接近“可继续演进的业务原型”，不是一个只展示 UI 的静态示例。

当前代码已经按业务模块拆分，并接入了路由、状态管理、网络层、本地持久化和多语言能力，适合作为后续功能开发与联调的基础工程。

## 功能范围

- 登录与注册流程
- 扫描与采集流程
  - 面部
  - 舌象
  - 手掌
- 报告展示
- 历史记录
- 个人中心
- 分享落地页
- 支付相关接入预研

## 技术栈

- Flutter
- Riverpod
- GoRouter
- Dio
- GetIt
- SharedPreferences
- Hive
- Camera
- WebView
- In-App Purchase
- fl_chart

## 目录结构

```text
lib/
  core/          通用基础设施
    di/          依赖注入
    l10n/        国际化与语言切换
    network/     Dio 客户端与拦截器
    platform/    平台标识与应用身份
    router/      全局路由
    security/    安全相关能力
    theme/       主题与视觉基础
    utils/       工具函数
    widgets/     公共组件
  features/      业务模块
    auth/        登录/注册
    history/     历史记录
    home/        首页
    profile/     个人中心
    report/      报告
    scan/        扫描流程
    share/       分享页
    vision/      视觉相关能力
  l10n/          ARB 文案与生成代码
docs/            业务说明、接口约定、支付与分享方案
scripts/         项目脚本
```

## 运行环境

- Dart SDK: `^3.10.4`
- Flutter: 建议使用与当前 Dart SDK 匹配的稳定版 Flutter

首次进入项目后执行：

```bash
flutter pub get
```

## 启动项目

### 本地运行

```bash
flutter run
```

### Web 调试

```bash
flutter run -d chrome
```

项目的网络层默认接口地址为 `https://saas-api.dev51.permillet.com`。

## 编译时环境变量

项目当前支持以下 `--dart-define` 参数：

- `API_BASE_URL`
  - 覆盖默认接口地址
- `WECHAT_MINI_PROGRAM_APP_ID`
  - 覆盖小程序 App ID
- `X_PLATFORM`
  - 覆盖平台请求头，未传时原生平台会自动根据系统推断

示例：

```bash
flutter run \
  --dart-define=API_BASE_URL=https://example.com \
  --dart-define=WECHAT_MINI_PROGRAM_APP_ID=wx123456 \
  --dart-define=X_PLATFORM=ANDROID
```

## 国际化

项目已经接入 Flutter 官方 `gen-l10n` 流程。

- ARB 目录：`lib/l10n`
- 模板文件：`lib/l10n/app_zh.arb`
- 生成文件：`lib/l10n/app_localizations.dart`

当前已覆盖的语言：

- `zh`
- `en`
- `ja`
- `ko`

生成多语言代码：

```bash
flutter gen-l10n
```

开发时需要遵守以下规则：

- 所有用户可见文案必须进入 ARB，不要直接写死在页面中
- 动态文案优先使用 placeholder，不要用字符串拼接代替
- 新增文案时同步补齐 `zh / en / ja / ko`
- 涉及紧凑布局的页面要检查多语言长度溢出问题

## 常用命令

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

如果需要重新生成序列化、Freezed 或 Riverpod 相关代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 协作约定

这部分不是形式要求，而是这个仓库当前最容易出问题的地方。

### 1. 文件编码

- 所有源码、脚本、文档统一使用 UTF-8
- 统一使用 LF 换行
- 不要把 GBK、ANSI 或带 BOM 的文件混入仓库

项目中已经提供编码检查脚本：

```bash
python scripts/check_text_encoding.py
```

只检查 README：

```bash
python scripts/check_text_encoding.py README.md
```

### 2. 注释要求

- 不要为了“有注释”而写废话注释
- 复杂业务判断、状态切换、平台差异、接口约束要写清楚
- 公共模块优先补“为什么这样做”，而不是重复“代码正在做什么”
- 如果发现一段代码阅读成本明显偏高，应优先补充短注释或做小幅重构

### 3. 文档维护

- `README.md` 负责新同学首次接手时的全局说明
- 业务细节、接口契约、支付方案等放到 `docs/`
- 如果目录结构、运行方式、环境变量发生变化，需要同步更新 README

## 相关文档

- [移动端验证码登录契约](docs/20260409_app_mobile_verification_code_auth_contract.md)
- [Flutter 阿里云验证码接入契约](docs/20260410_app_flutter_aliyun_captcha_contract.md)
- [Apple Pay 无后端阶段实施清单](docs/2026-04-01_ApplePay_无后端阶段实施清单.md)
- [Google Pay 无后端阶段实施清单](docs/2026-04-01_GooglePay_无后端阶段实施清单.md)
- [报告二维码分享方案草案](docs/20260428_报告二维码分享方案草案.md)

说明：

- `docs/接口.md` 当前存在历史编码问题，使用前建议先完成转码或内容校正

## 当前已确认的工程特征

- 应用入口在 `lib/main.dart`
- 全局路由在 `lib/core/router/app_router.dart`
- 依赖注入在 `lib/core/di/injector.dart`
- 网络基础能力在 `lib/core/network/dio_client.dart`
- 应用当前锁定竖屏
- 应用使用 `MaterialApp.router`

如果你是第一次接手这个项目，建议按下面顺序阅读：

1. `README.md`
2. `lib/main.dart`
3. `lib/core/router/app_router.dart`
4. `lib/core/di/injector.dart`
5. 对应业务模块的 `features/*`

