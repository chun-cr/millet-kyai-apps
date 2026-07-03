# APP 联调契约：Flutter 接入阿里云验证码 2.0

## 1. 适用范围

- 生效日期：2026-04-10
- 适用客户端：Flutter App
- 适用能力：手机号验证码登录 / 注册
- 适用 provider：`ALIYUN`
- 对外路径前缀：`/api/v1/saas/mobile/auth`

本文是对 [20260409_app_mobile_verification_code_auth_contract.md](./20260409_app_mobile_verification_code_auth_contract.md) 的 Flutter 化补充，重点回答两件事：

- `challenge` 返回的 `captcha.payload` 到底怎么用
- Flutter 如何通过 WebView + H5 容器页完成阿里云验证码 2.0 联调

## 2. 结论先说

当前 App 联调统一按 4 段式流程执行：

1. `challenge`
2. 可选 `captcha/verify`
3. `send`
4. `authenticate`

其中，阿里云验证码链路的职责划分如下：

- Flutter App：负责发起业务接口、打开 WebView、接收 H5 回传结果
- H5 容器页：负责消费 `captcha.payload`、初始化阿里云验证码 JS、把 `captchaVerifyParam` 回传给 Flutter
- 后端：负责 `challenge`、阿里云服务端二次校验、发送短信验证码、最终认证

一句话总结：

`challenge.payload` 不是直接发回后端的票据，而是“让 H5 页面初始化阿里云验证码”的参数集合；真正回传后端的是阿里云成功回调出来的 `captchaVerifyParam`。

## 3. 官方参考

- 阿里云 Web/H5 接入：
  [https://help.aliyun.com/zh/captcha/captcha2-0/user-guide/new-architecture-for-web-and-h5-client-access](https://help.aliyun.com/zh/captcha/captcha2-0/user-guide/new-architecture-for-web-and-h5-client-access)
- 阿里云 Flutter 接入：
  [https://help.aliyun.com/zh/captcha/captcha2-0/user-guide/flutter-access-v3-architecture](https://help.aliyun.com/zh/captcha/captcha2-0/user-guide/flutter-access-v3-architecture)
- 阿里云服务端二次校验：
  [https://help.aliyun.com/zh/captcha/captcha2-0/user-guide/server-access](https://help.aliyun.com/zh/captcha/captcha2-0/user-guide/server-access)
- Flutter `webview_flutter`：
  [https://pub.dev/packages/webview_flutter](https://pub.dev/packages/webview_flutter)

## 4. 接口总览

以下接口路径沿用基线文档中的 `millet-saas-mobile-bff` 对外公开契约：

- `/api/v1/saas/mobile/auth/**`

不要把这里的公开路径理解成 `millet-uaa-user` 内部控制器路径。

客户端仍然只需要关心这 4 个接口：

| 步骤 | 方法 | 路径 |
| --- | --- | --- |
| 发起 challenge | `POST` | `/api/v1/saas/mobile/auth/verification-code/challenge` |
| 人机校验 | `POST` | `/api/v1/saas/mobile/auth/verification-code/captcha/verify` |
| 发送验证码 | `POST` | `/api/v1/saas/mobile/auth/verification-code/send` |
| 验证码认证 | `POST` | `/api/v1/saas/mobile/auth/verification-code/authenticate` |

公共请求头：

- `Content-Type: application/json`
- `X-App-Id: <your-app-id>`
- `X-Platform: ANDROID` 或 `IOS`

## 5. challenge 返回的 payload 怎么用

后端示例响应：

```json
{
  "challengeId": "2042523836131659778",
  "captchaRequired": true,
  "captcha": {
    "provider": "ALIYUN",
    "payload": {
      "sceneId": "7v4wtfh4",
      "region": "cn",
      "prefix": "29st3w",
      "userCertifyId": "29st3w_WOXHkPgOfj",
      "mode": "aliyun-captcha2",
      "h5Url": "https://captcha.dev51.permillet.com/index.html"
    }
  },
  "expireAt": "2026-04-10T08:53:25.448Z"
}
```

字段用途如下：

| 字段 | 谁来消费 | 用途 | 备注 |
| --- | --- | --- | --- |
| `challengeId` | Flutter | 贯穿 `captcha/verify`、`send`、`authenticate` | 必须持久化到当前流程结束 |
| `captcha.provider` | Flutter | 标识当前 provider | 当前固定 `ALIYUN`，不要自行写死拼接 |
| `payload.sceneId` | H5 | 传给 `initAliyunCaptcha` 的 `SceneId` | 由后端按业务场景计算，前端不要改 |
| `payload.region` | H5 | 传给 `window.AliyunCaptchaConfig.region` | 当前常见值 `cn` / `sgp` |
| `payload.prefix` | H5 | 传给 `window.AliyunCaptchaConfig.prefix` | 阿里云业务前缀 |
| `payload.userCertifyId` | H5 | 传给 `initAliyunCaptcha` 的 `UserCertifyId` | 标识本次 challenge 的验证码流水 |
| `payload.h5Url` | Flutter | WebView 实际打开的容器页地址 | 必须是 App 内可访问的 HTTPS 页面 |
| `payload.mode` | Flutter / H5 | 我方业务标识 | 当前固定 `aliyun-captcha2`，不是阿里云 SDK 的 `mode` |
| `expireAt` | Flutter | challenge 过期时间 | 过期后重新发起 `challenge` |

特别注意：

- `payload.mode = aliyun-captcha2` 不是阿里云 JS SDK 的 `mode`
- 阿里云 JS SDK 的 `mode` 仍然建议传 `"popup"`
- `captchaVerifyParam` 不在 `challenge` 响应里；它只会出现在阿里云前端成功回调中
- `payload.h5Url` 如果为空或缺失，说明当前环境还没配好 H5 容器页地址；Flutter 不要自行写死兜底地址，应先修服务端配置

## 6. 联调流程总览（推荐时序）

```text
Flutter
  -> challenge
  -> 保存 challengeId
  -> 如果 captchaRequired = false
       -> send
       -> authenticate
  -> 如果 captchaRequired = true
       -> 打开 WebView(h5Url + payload)
       -> H5 initAliyunCaptcha(...)
       -> 阿里云 success(captchaVerifyParam)
       -> H5 通过 JS bridge 把 captchaVerifyParam 回传 Flutter
       -> Flutter 调 captcha/verify
       -> verify 成功后调 send
       -> 用户输入短信验证码后调 authenticate
```

状态要求：

- 同一个 `challengeId` 只对应一次 challenge 生命周期
- 同一个 `challengeId` 完成一次 `captcha/verify` 后，challenge 未失效前再次点“发送验证码”不需要重复做人机校验
- 收到“challenge 已失效 / 验证码已过期”后，重新从 `challenge` 开始

## 7. H5 容器页完整示例

### 7.1 Flutter 传给 H5 的 query 参数

推荐 Flutter 直接在 `payload.h5Url` 后追加以下 query 参数：

- `sceneId`
- `region`
- `prefix`
- `userCertifyId`
- `provider`
- `challengeId`

例如：

```text
https://captcha.dev51.permillet.com/index.html
  ?sceneId=7v4wtfh4
  &region=cn
  &prefix=29st3w
  &userCertifyId=29st3w_WOXHkPgOfj
  &provider=ALIYUN
  &challengeId=2042523836131659778
```

### 7.2 H5 页面完整示例

下面示例可作为独立部署的 `index.html`。它做了几件事：

- 从 query 中读取后端下发的 payload
- 初始化阿里云验证码 2.0
- 通过 `CaptchaBridge.postMessage(...)` 回传给 Flutter
- 成功时回传 `captchaVerifyParam`
- 失败时回传错误信息，供 Flutter 决定是否重试或关闭页面

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
    <title>阿里云验证码容器页</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f5f7fb;
        --panel: #ffffff;
        --text: #1f2937;
        --muted: #6b7280;
        --brand: #1d4ed8;
        --danger: #dc2626;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Helvetica Neue", sans-serif;
        background: linear-gradient(180deg, #eef4ff 0%, var(--bg) 100%);
        color: var(--text);
      }

      .page {
        min-height: 100vh;
        padding: 24px 16px 40px;
        display: flex;
        align-items: center;
        justify-content: center;
      }

      .card {
        width: 100%;
        max-width: 420px;
        background: var(--panel);
        border-radius: 18px;
        padding: 24px;
        box-shadow: 0 20px 60px rgba(29, 78, 216, 0.12);
      }

      h1 {
        margin: 0 0 12px;
        font-size: 22px;
      }

      p {
        margin: 0 0 12px;
        line-height: 1.6;
      }

      .tips {
        color: var(--muted);
        min-height: 48px;
      }

      .danger {
        color: var(--danger);
      }

      #captcha-element {
        min-height: 52px;
        margin: 12px 0 20px;
      }

      #captcha-button {
        width: 100%;
        border: 0;
        border-radius: 12px;
        height: 48px;
        background: var(--brand);
        color: white;
        font-size: 16px;
        font-weight: 600;
        cursor: pointer;
      }

      #captcha-button[disabled] {
        cursor: not-allowed;
        opacity: 0.5;
      }
    </style>
  </head>
  <body>
    <div class="page">
      <div class="card">
        <h1>安全验证</h1>
        <p class="tips" id="tips">正在准备验证码组件...</p>
        <div id="captcha-element"></div>
        <button id="captcha-button" disabled>点击开始验证</button>
      </div>
    </div>

    <script>
      (function () {
        const tipsEl = document.getElementById("tips");
        const buttonEl = document.getElementById("captcha-button");
        const params = new URLSearchParams(window.location.search);
        const captchaPayload = {
          sceneId: params.get("sceneId") || "",
          region: params.get("region") || "cn",
          prefix: params.get("prefix") || "",
          userCertifyId: params.get("userCertifyId") || "",
          provider: params.get("provider") || "ALIYUN",
          challengeId: params.get("challengeId") || ""
        };

        function postBridgeMessage(message) {
          const serialized = JSON.stringify(message);
          if (window.CaptchaBridge && typeof window.CaptchaBridge.postMessage === "function") {
            window.CaptchaBridge.postMessage(serialized);
            return;
          }
          if (window.parent && window.parent !== window) {
            window.parent.postMessage(message, "*");
          }
        }

        function setTips(message, isError) {
          tipsEl.textContent = message;
          tipsEl.className = isError ? "tips danger" : "tips";
        }

        function assertField(name, value) {
          if (!value) {
            throw new Error("缺少必要参数: " + name);
          }
        }

        function loadAliyunCaptchaScript() {
          return new Promise(function (resolve, reject) {
            if (window.initAliyunCaptcha) {
              resolve();
              return;
            }
            const script = document.createElement("script");
            script.type = "text/javascript";
            script.src = "https://o.alicdn.com/captcha-frontend/aliyunCaptcha/AliyunCaptcha.js";
            script.async = true;
            script.onload = resolve;
            script.onerror = function () {
              reject(new Error("阿里云验证码 SDK 加载失败"));
            };
            document.head.appendChild(script);
          });
        }

        async function bootstrap() {
          try {
            assertField("sceneId", captchaPayload.sceneId);
            assertField("prefix", captchaPayload.prefix);
            assertField("userCertifyId", captchaPayload.userCertifyId);

            window.AliyunCaptchaConfig = {
              region: captchaPayload.region,
              prefix: captchaPayload.prefix
            };

            await loadAliyunCaptchaScript();

            setTips("组件已加载，请点击按钮完成验证。");
            postBridgeMessage({
              type: "ready",
              challengeId: captchaPayload.challengeId,
              provider: captchaPayload.provider
            });

            buttonEl.disabled = false;

            window.initAliyunCaptcha({
              SceneId: captchaPayload.sceneId,
              UserCertifyId: captchaPayload.userCertifyId,
              mode: "popup",
              element: "#captcha-element",
              button: "#captcha-button",
              success: function (captchaVerifyParam) {
                setTips("验证成功，正在回传 App。");
                postBridgeMessage({
                  type: "success",
                  challengeId: captchaPayload.challengeId,
                  provider: captchaPayload.provider,
                  captchaVerifyParam: captchaVerifyParam
                });
              },
              fail: function (result) {
                console.error("aliyun captcha fail", result);
                setTips("验证码未通过，请重试。", true);
                postBridgeMessage({
                  type: "fail",
                  challengeId: captchaPayload.challengeId,
                  provider: captchaPayload.provider,
                  result: result
                });
              },
              getInstance: function () {
                console.info("aliyun captcha instance ready");
              },
              slideStyle: {
                width: 360,
                height: 40
              }
            });
          } catch (error) {
            console.error("bootstrap error", error);
            setTips(error.message || "验证码初始化失败", true);
            postBridgeMessage({
              type: "error",
              challengeId: captchaPayload.challengeId,
              provider: captchaPayload.provider,
              message: error.message || "验证码初始化失败"
            });
          }
        }

        bootstrap();
      })();
    </script>
  </body>
</html>
```

### 7.3 H5 页开发要求

- `sceneId`、`prefix`、`userCertifyId` 都以后端返回值为准，不要前端写死
- 阿里云官方要求验证码 JS 尽量前置加载，初始化与验证请求之间建议大于 2 秒
- `success(captchaVerifyParam)` 的入参要原样回传给后端，不能改、不能拆、不能重新编码
- `captchaVerifyParam` 属于敏感数据，H5 页面不要写明文业务日志

## 8. Flutter 完整示例

### 8.1 示例依赖

示例使用：

- `http` 负责调用业务后端
- `webview_flutter` 负责承载 H5 容器页

`webview_flutter` 官方包见：
[https://pub.dev/packages/webview_flutter](https://pub.dev/packages/webview_flutter)

`pubspec.yaml` 可按项目现有版本策略选择兼容版本，示例代码按 `webview_flutter` 4.x 风格 API 编写。

### 8.2 示例代码

下面示例放在同一个 `main.dart` 中即可跑通 Demo。生产环境可以再拆分为 `api/`、`pages/`、`models/`。

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MaterialApp(home: PhoneCodeAuthPage()));
}

class AppConfig {
  static const String baseUrl = 'https://api.example.com';
  static const String appId = 'millet-flutter-app';
  static const String platform = 'ANDROID';
}

class ChallengeCaptchaPayload {
  ChallengeCaptchaPayload({
    required this.provider,
    required this.sceneId,
    required this.region,
    required this.prefix,
    required this.userCertifyId,
    required this.h5Url,
    required this.mode,
  });

  final String provider;
  final String sceneId;
  final String region;
  final String prefix;
  final String userCertifyId;
  final String h5Url;
  final String mode;

  factory ChallengeCaptchaPayload.fromJson(Map<String, dynamic> json, String provider) {
    return ChallengeCaptchaPayload(
      provider: provider,
      sceneId: (json['sceneId'] ?? '') as String,
      region: (json['region'] ?? 'cn') as String,
      prefix: (json['prefix'] ?? '') as String,
      userCertifyId: (json['userCertifyId'] ?? '') as String,
      h5Url: (json['h5Url'] ?? '') as String,
      mode: (json['mode'] ?? '') as String,
    );
  }
}

class VerificationChallenge {
  VerificationChallenge({
    required this.challengeId,
    required this.captchaRequired,
    required this.expireAt,
    required this.captcha,
  });

  final String challengeId;
  final bool captchaRequired;
  final String expireAt;
  final ChallengeCaptchaPayload? captcha;

  factory VerificationChallenge.fromJson(Map<String, dynamic> json) {
    final captchaJson = json['captcha'] as Map<String, dynamic>?;
    return VerificationChallenge(
      challengeId: (json['challengeId'] ?? '') as String,
      captchaRequired: (json['captchaRequired'] ?? false) as bool,
      expireAt: (json['expireAt'] ?? '') as String,
      captcha: captchaJson == null
          ? null
          : ChallengeCaptchaPayload.fromJson(
              (captchaJson['payload'] as Map<String, dynamic>? ?? <String, dynamic>{}),
              (captchaJson['provider'] ?? '') as String,
            ),
    );
  }
}

class AuthToken {
  AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: (json['accessToken'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
      tokenType: (json['tokenType'] ?? 'Bearer') as String,
      expiresIn: (json['expiresIn'] ?? 0) as int,
    );
  }
}

class MobileAuthApi {
  MobileAuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<VerificationChallenge> createChallenge({
    required String scene,
    required String countryCode,
    required String phoneNumber,
  }) async {
    final data = await _post(
      '/api/v1/saas/mobile/auth/verification-code/challenge',
      <String, dynamic>{
        'scene': scene,
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
      },
    );
    return VerificationChallenge.fromJson(data);
  }

  Future<void> verifyCaptcha({
    required String challengeId,
    required String captchaProvider,
    required String captchaVerifyParam,
  }) async {
    await _post(
      '/api/v1/saas/mobile/auth/verification-code/captcha/verify',
      <String, dynamic>{
        'challengeId': challengeId,
        'captchaProvider': captchaProvider,
        'captchaPayload': <String, String>{
          'captchaVerifyParam': captchaVerifyParam,
        },
      },
    );
  }

  Future<Map<String, dynamic>> sendVerificationCode({
    required String challengeId,
  }) async {
    return _post(
      '/api/v1/saas/mobile/auth/verification-code/send',
      <String, dynamic>{'challengeId': challengeId},
    );
  }

  Future<AuthToken> authenticate({
    required String challengeId,
    required String verificationCode,
  }) async {
    final data = await _post(
      '/api/v1/saas/mobile/auth/verification-code/authenticate',
      <String, dynamic>{
        'challengeId': challengeId,
        'verificationCode': verificationCode,
      },
    );
    return AuthToken.fromJson(data);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-App-Id': AppConfig.appId,
        'X-Platform': AppConfig.platform,
      },
      body: jsonEncode(body),
    );

    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    final code = (envelope['code'] ?? -1) as int;
    if (code != 0) {
      throw Exception(
        'request failed: code=$code, message=${envelope['message']}, messageKey=${envelope['messageKey']}',
      );
    }
    return (envelope['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
  }
}

class PhoneCodeAuthPage extends StatefulWidget {
  const PhoneCodeAuthPage({super.key});

  @override
  State<PhoneCodeAuthPage> createState() => _PhoneCodeAuthPageState();
}

class _PhoneCodeAuthPageState extends State<PhoneCodeAuthPage> {
  final MobileAuthApi _api = MobileAuthApi();
  final TextEditingController _countryCodeController = TextEditingController(text: '+86');
  final TextEditingController _phoneController = TextEditingController(text: '13800138000');
  final TextEditingController _verificationCodeController = TextEditingController();

  VerificationChallenge? _challenge;
  bool _loading = false;
  String _scene = 'LOGIN';
  String _status = '待开始';

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _startFlow() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _status = '正在发起 challenge...';
    });
    try {
      final challenge = await _api.createChallenge(
        scene: _scene,
        countryCode: _countryCodeController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      _challenge = challenge;

      if (challenge.captchaRequired) {
        final payload = challenge.captcha;
        if (payload == null) {
          throw Exception('captchaRequired=true 但 captcha.payload 为空');
        }
        setState(() {
          _status = 'challenge 成功，正在打开阿里云验证码...';
        });
        final captchaVerifyParam = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => AliyunCaptchaPage(
              challengeId: challenge.challengeId,
              payload: payload,
            ),
          ),
        );
        if (!mounted) {
          return;
        }
        if (captchaVerifyParam == null || captchaVerifyParam.isEmpty) {
          setState(() {
            _status = '用户取消或验证码未完成';
            _loading = false;
          });
          return;
        }
        setState(() {
          _status = '正在调用 captcha/verify...';
        });
        await _api.verifyCaptcha(
          challengeId: challenge.challengeId,
          captchaProvider: payload.provider,
          captchaVerifyParam: captchaVerifyParam,
        );
      }

      setState(() {
        _status = '正在发送短信验证码...';
      });
      await _api.sendVerificationCode(challengeId: challenge.challengeId);
      setState(() {
        _status = '短信验证码已发送，请输入验证码';
      });
    } catch (error) {
      setState(() {
        _status = '流程失败: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    final challenge = _challenge;
    if (challenge == null) {
      setState(() {
        _status = '请先完成 challenge';
      });
      return;
    }
    setState(() {
      _loading = true;
      _status = '正在认证...';
    });
    try {
      final token = await _api.authenticate(
        challengeId: challenge.challengeId,
        verificationCode: _verificationCodeController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = '认证成功';
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('认证成功'),
          content: Text(
            'accessToken: ${token.accessToken}\n'
            'refreshToken: ${token.refreshToken}\n'
            'tokenType: ${token.tokenType}\n'
            'expiresIn: ${token.expiresIn}',
          ),
        ),
      );
    } catch (error) {
      setState(() {
        _status = '认证失败: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手机号验证码登录/注册')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _scene,
            decoration: const InputDecoration(labelText: '场景'),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'LOGIN', child: Text('LOGIN')),
              DropdownMenuItem(value: 'REGISTER', child: Text('REGISTER')),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _scene = value;
                    });
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryCodeController,
            decoration: const InputDecoration(labelText: '国际区号'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: '手机号'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _verificationCodeController,
            decoration: const InputDecoration(labelText: '短信验证码'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _startFlow,
            child: const Text('开始 challenge / 验证 / 发送验证码'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _loading ? null : _authenticate,
            child: const Text('提交短信验证码并认证'),
          ),
          const SizedBox(height: 24),
          Text('当前状态：$_status'),
          const SizedBox(height: 8),
          Text('当前 challengeId：${_challenge?.challengeId ?? '-'}'),
          const SizedBox(height: 8),
          Text('challenge expireAt：${_challenge?.expireAt ?? '-'}'),
        ],
      ),
    );
  }
}

class AliyunCaptchaPage extends StatefulWidget {
  const AliyunCaptchaPage({
    super.key,
    required this.challengeId,
    required this.payload,
  });

  final String challengeId;
  final ChallengeCaptchaPayload payload;

  @override
  State<AliyunCaptchaPage> createState() => _AliyunCaptchaPageState();
}

class _AliyunCaptchaPageState extends State<AliyunCaptchaPage> {
  late final WebViewController _controller;
  String _status = '正在加载验证码页面...';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _status = '页面加载失败: ${error.description}';
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'CaptchaBridge',
        onMessageReceived: (message) {
          final event = jsonDecode(message.message) as Map<String, dynamic>;
          final type = event['type'] as String? ?? '';

          if (type == 'ready') {
            setState(() {
              _status = '验证码组件已就绪，请在页面内完成人机验证';
            });
            return;
          }

          if (type == 'success') {
            final captchaVerifyParam = (event['captchaVerifyParam'] ?? '') as String;
            Navigator.of(context).pop(captchaVerifyParam);
            return;
          }

          if (type == 'fail' || type == 'error') {
            setState(() {
              _status = '验证码失败，请重试';
            });
          }
        },
      )
      ..loadRequest(_buildCaptchaUri());
  }

  Uri _buildCaptchaUri() {
    final uri = Uri.parse(widget.payload.h5Url);
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        'sceneId': widget.payload.sceneId,
        'region': widget.payload.region,
        'prefix': widget.payload.prefix,
        'userCertifyId': widget.payload.userCertifyId,
        'provider': widget.payload.provider,
        'challengeId': widget.challengeId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('阿里云人机验证')),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: Colors.black12,
            padding: const EdgeInsets.all(12),
            child: Text(_status),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
```

### 8.3 Flutter 示例说明

- `createChallenge()` 只负责拿到 `challengeId + captcha.payload`
- `AliyunCaptchaPage` 负责把 payload 透传给 H5
- H5 成功后通过 `CaptchaBridge.postMessage(...)` 把 `captchaVerifyParam` 回传给 Flutter
- Flutter 拿到 `captchaVerifyParam` 后调用 `/captcha/verify`
- `captcha/verify` 成功后再调用 `/send`
- 用户输入短信验证码后调用 `/authenticate`
- 本示例是最小联调闭环，未包含 `inviteTicket`；如果业务有邀请链路，只在 `/authenticate` 时追加上传

## 9. H5 和 Flutter 的桥接协议

H5 建议统一发送 JSON 字符串给 Flutter：

```json
{
  "type": "success",
  "challengeId": "2042523836131659778",
  "provider": "ALIYUN",
  "captchaVerifyParam": "CF_CHL_1.0.0-opaque-verify-param"
}
```

推荐事件类型：

| `type` | 含义 | Flutter 处理 |
| --- | --- | --- |
| `ready` | 验证码组件已就绪 | 更新页面状态 |
| `success` | 已拿到 `captchaVerifyParam` | 关闭 WebView，回调业务层 |
| `fail` | 用户验证未通过 | 页面提示“请重试” |
| `error` | SDK 加载或初始化失败 | 页面提示错误，可允许关闭重开 |

## 10. 常见坑

### 10.1 `captchaVerifyParam` 被改写

不要做任何处理，直接原样发给后端：

```json
{
  "challengeId": "2042523836131659778",
  "captchaProvider": "ALIYUN",
  "captchaPayload": {
    "captchaVerifyParam": "原样字符串"
  }
}
```

阿里云官方明确说明：

- `CaptchaVerifyParam` 不能为空
- 服务端不能对它做任何改动

### 10.2 前端自己决定 scene

不要自己根据页面是“登录”还是“注册”去覆盖 `payload.sceneId`。

原因：

- 后端已经按业务场景和配置映射好了阿里云 `sceneId`
- 多场景配置下，`LOGIN` 和 `REGISTER` 可能对应不同的阿里云场景

### 10.3 Flutter 直接把 payload 整个发回 `/captcha/verify`

不要这样做。后端只需要：

- `challengeId`
- `captchaProvider`
- `captchaPayload.captchaVerifyParam`

### 10.4 `h5Url` 打不开

联调前先确认：

- 页面是 HTTPS
- Android / iOS 真机网络可以访问
- WebView 没有被域名白名单或网络策略拦截
- 页面能加载 `https://o.alicdn.com/captcha-frontend/aliyunCaptcha/AliyunCaptcha.js`

### 10.5 把 `payload.mode` 当成阿里云 SDK 参数

不要混淆：

- `payload.mode = aliyun-captcha2`：我方业务标识
- `initAliyunCaptcha({ mode: "popup" })`：阿里云 SDK 初始化参数

## 11. 联调 Checklist

- challenge 返回 `captchaRequired=true`
- Flutter 成功打开 `payload.h5Url`
- H5 成功读取 `sceneId / region / prefix / userCertifyId`
- H5 成功执行 `initAliyunCaptcha`
- 阿里云 `success(captchaVerifyParam)` 能被触发
- Flutter 成功收到 `CaptchaBridge` 回调
- `/captcha/verify` 返回成功
- `/send` 返回成功并展示倒计时
- `/authenticate` 返回 token
- 全链路不打印 `captchaVerifyParam` 明文日志

## 12. 口径统一

这份文档之后，Flutter 侧统一按以下口径联调：

- 业务主流程：Flutter
- 验证码渲染：H5 容器页
- 人机票据：H5 成功回调出的 `captchaVerifyParam`
- 服务端验票：`/verification-code/captcha/verify`
- 短信发送：`/verification-code/send`
- 最终认证：`/verification-code/authenticate`

如果后续需要支持更多业务场景，只新增后端 scene 配置和 challenge 返回，不改变 Flutter / H5 主流程。
