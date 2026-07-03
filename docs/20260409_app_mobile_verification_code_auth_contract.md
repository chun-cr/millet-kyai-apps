# APP 联调契约：移动端手机号验证码认证

## 1. 适用范围

- 生效日期：2026-04-09
- 适用服务：`millet-saas-mobile-bff`
- 适用能力：移动端手机号验证码登录 / 注册
- 对外唯一公开路径前缀：`/api/v1/saas/mobile/auth`

本文件是 APP 联调基线，后续客户端开发以此为准。

## 2. 结论先说

当前验证码认证统一为 4 段式流程：

1. `challenge`
2. 可选 `captcha/verify`
3. `send`
4. `authenticate`

`challenge` 登录和注册共用同一个接口，只通过 `scene` 区分场景：

- 登录页：`POST /api/v1/saas/mobile/auth/verification-code/challenge`，body 传 `scene = LOGIN`
- 注册页：`POST /api/v1/saas/mobile/auth/verification-code/challenge`，body 传 `scene = REGISTER`

旧分场景验证码路由已下线，不要再调：

- `/api/v1/saas/mobile/auth/login/verification-code/**`
- `/api/v1/saas/mobile/auth/register/verification-code/**`

## 3. APP 接入前提

### 3.1 公共请求头

所有下面验证码认证相关接口都按以下约定调用：

- `Content-Type: application/json`
- `X-App-Id`: 必填，标识当前 APP
- `X-Platform`: 建议必传，建议值由客户端统一约定，例如 `IOS`、`ANDROID`、`WX_MA`
- `Authorization`: 这些接口都不需要登录态

兼容头：

- `appId` 可以作为 `X-App-Id` 的兼容头，但新接入统一传 `X-App-Id`
- `platform` 可以作为 `X-Platform` 的兼容头，但新接入统一传 `X-Platform`

### 3.2 租户上下文

APP 不需要在 body 里传 `tenantId`，但联调环境必须保证网关 / 域名路由已经能正确解析租户上下文。否则某些链路会返回：

- `11103 mobile-bff.tenant-context-missing`

### 3.3 公共响应壳

成功响应：

```json
{
  "code": 0,
  "message": "请求成功",
  "messageKey": "common.success",
  "requestId": "trace-id",
  "timestamp": "2026-04-09T03:00:00Z",
  "data": {}
}
```

失败响应也是同一壳，只是没有业务 `data`，重点看：

- `code`
- `message`
- `messageKey`

## 4. 场景语义

### 4.1 `LOGIN`

用于“手机号验证码登录”。

注意：

- 为防枚举，`challenge` 和 `send` 阶段不能用来判断“手机号是否已注册”
- 即使手机号不存在，前两步也可能返回成功外观
- 是否最终登录成功，以 `authenticate` 为准

APP 不要在 `challenge` / `send` 阶段提示“该手机号未注册”。

### 4.2 `REGISTER`

用于“手机号验证码注册”。

注意：

- 如果手机号未注册，`authenticate` 会完成建号并返回 token
- 如果手机号已经存在，`authenticate` 会直接复用已有账号并返回 token
- APP 不要把 `REGISTER` 场景下的成功结果强制解释成“新注册成功”，更准确的 UI 文案应是“注册/登录成功”

## 5. 推荐联调时序

### 5.1 主流程

```text
challenge
  -> captchaRequired = false  -> send -> authenticate
  -> captchaRequired = true   -> captcha/verify -> send -> authenticate
```

### 5.2 客户端状态要求

- `challengeId` 由客户端保存，贯穿后续 `captcha/verify`、`send`、`authenticate`
- `inviteTicket` 如果存在，只在 `authenticate` 时上传；前面三个接口不要传
- 如果走分享/邀请链路，客户端必须自己暂存 `inviteTicket`，直到 `authenticate` 再带上
- 点击“重新发送验证码”时，复用同一个 `challengeId` 调 `send`
- 如果收到“challenge 已失效 / 验证码已过期”，重新从 `challenge` 开始

## 6. 接口契约

### 6.1 发起 challenge

- 方法：`POST`
- 路径：`/api/v1/saas/mobile/auth/verification-code/challenge`

请求体：

```json
{
  "scene": "LOGIN",
  "countryCode": "+86",
  "phoneNumber": "13800138000",
  "loginValue": "13800138000"
}
```

- 注册 challenge 仍然走同一路径：`/api/v1/saas/mobile/auth/verification-code/challenge`

请求体：

```json
{
  "scene": "REGISTER",
  "countryCode": "+86",
  "phoneNumber": "13800138000",
  "loginValue": "13800138000"
}
```

字段说明：

| 字段 | 类型 | 登录 challenge | 注册 challenge | 说明 |
| --- | --- | --- | --- | --- |
| `scene` | `String` | 是，仅支持 `LOGIN` | 是，仅支持 `REGISTER` | 用于区分登录/注册 challenge 场景 |
| `countryCode` | `String` | 是 | 是 | 国际区号，例如 `+86` |
| `phoneNumber` | `String` | 是 | 是 | 手机号正文，不要带空格和横杠 |
| `loginValue` | `String` | 是 | 是 | 当前仍传手机号正文，与 `phoneNumber` 保持一致 |

成功响应：

```json
{
  "code": 0,
  "message": "请求成功",
  "messageKey": "common.success",
  "requestId": "trace-id",
  "timestamp": "2026-04-09T03:00:00Z",
  "data": {
    "challengeId": "challenge-1",
    "captchaRequired": true,
    "captcha": {
      "provider": "TENCENT",
      "payload": {
        "appId": "captcha-app"
      }
    },
    "expireAt": "2026-04-09T03:10:00Z"
  }
}
```

响应字段说明：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `challengeId` | `String` | 后续三步都依赖这个 ID |
| `captchaRequired` | `boolean` | 是否必须先做人机验证 |
| `captcha.provider` | `String` | 人机验证 provider 标识 |
| `captcha.payload` | `Map<String,Object>` | 前端初始化 provider SDK 的参数，按 provider 透传使用 |
| `expireAt` | `String` | challenge 过期时间，UTC ISO-8601 |

客户端处理：

- `captchaRequired = false`：直接进入 `send`
- `captchaRequired = true`：先拉起对应 provider 的人机验证，再调 `captcha/verify`

注意：

- 登录和注册 challenge 都走同一个接口，只通过 `scene` 区分
- `loginValue` 当前仍传手机号正文，和 `phoneNumber` 一致
- `REGISTER` 场景下，APP 不需要传 `registerSource`，服务端会根据 `X-App-Id` 自动推导
- `challenge` 不会发短信

### 6.2 人机验证校验

- 方法：`POST`
- 路径：`/api/v1/saas/mobile/auth/verification-code/captcha/verify`

请求体：

```json
{
  "challengeId": "challenge-1",
  "captchaProvider": "TENCENT",
  "captchaPayload": {
    "ticket": "ticket-001"
  }
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `challengeId` | `String` | 是 | 上一步返回 |
| `captchaProvider` | `String` | 是 | 必须与 `challenge.data.captcha.provider` 一致 |
| `captchaPayload` | `Map<String,String>` | 是 | 前端 provider SDK 回传票据，value 统一按字符串传 |

成功响应：

```json
{
  "code": 0,
  "message": "请求成功",
  "messageKey": "common.success",
  "requestId": "trace-id",
  "timestamp": "2026-04-09T03:00:10Z",
  "data": {
    "challengeId": "challenge-1",
    "captchaVerified": true
  }
}
```

客户端处理：

- 只有 `captchaVerified = true` 才进入 `send`
- 同一个 `challengeId` 完成一次 captcha 校验后，在 challenge 未失效前重发验证码不需要重复校验

注意：

- `captchaPayload` 字段是敏感数据，客户端不要写业务日志明文
- 不要自己拼 provider 字段；以 `challenge` 返回为准

### 6.3 发送短信验证码

- 方法：`POST`
- 路径：`/api/v1/saas/mobile/auth/verification-code/send`

请求体：

```json
{
  "challengeId": "challenge-1"
}
```

成功响应：

```json
{
  "code": 0,
  "message": "请求成功",
  "messageKey": "common.success",
  "requestId": "trace-id",
  "timestamp": "2026-04-09T03:00:20Z",
  "data": {
    "channel": "PHONE",
    "maskedReceiver": "+861****8000",
    "expireAt": "2026-04-09T03:05:20Z",
    "resendAt": "2026-04-09T03:01:20Z"
  }
}
```

响应字段说明：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `channel` | `String` | 当前固定为 `PHONE` |
| `maskedReceiver` | `String` | 脱敏手机号，用于页面提示 |
| `expireAt` | `String` | 验证码过期时间，UTC ISO-8601 |
| `resendAt` | `String` | 可重发时间，UTC ISO-8601 |

客户端处理：

- 收到成功后展示验证码输入框
- 倒计时以 `resendAt` 为准
- 点击“重新发送”时继续调同一个接口，body 仍然只传 `challengeId`

注意：

- 如果前一步应做人机验证但没做，会返回 `11122`
- 不要把 `maskedReceiver` 反解析成真实手机号

### 6.4 验证码认证

- 方法：`POST`
- 路径：`/api/v1/saas/mobile/auth/verification-code/authenticate`

请求体：

```json
{
  "challengeId": "challenge-1",
  "verificationCode": "123456",
  "inviteTicket": "invite-ticket-004"
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `challengeId` | `String` | 是 | challenge ID |
| `verificationCode` | `String` | 是 | 6 位短信验证码 |
| `inviteTicket` | `String` | 否 | 邀请票据，只在最终认证时上传 |

成功响应：

```json
{
  "code": 0,
  "message": "请求成功",
  "messageKey": "common.success",
  "requestId": "trace-id",
  "timestamp": "2026-04-09T03:00:30Z",
  "data": {
    "accessToken": "access-token-004",
    "refreshToken": "refresh-token-004",
    "tokenType": "Bearer",
    "expiresIn": 7200,
    "scope": "profile"
  }
}
```

客户端处理：

- 成功后直接进入登录完成态
- `tokenType` 当前按 `Bearer` 使用
- `expiresIn` 单位是秒
- `inviteTicket` 只要带了，服务端会在认证成功后 best-effort 做邀请确认；失败不会影响主登录成功

## 7. 密码注册页兼容约定

如果 APP 还保留密码注册页，仍可继续调：

- `POST /api/v1/saas/mobile/auth/register/password`

但当手机号已经存在时，不会再直接报“已注册”，而是返回：

```json
{
  "code": 0,
  "message": "请求成功",
  "messageKey": "common.success",
  "data": {
    "result": "VERIFICATION_CODE_REQUIRED",
    "token": null,
    "challenge": {
      "challengeId": "challenge-1",
      "captchaRequired": false,
      "captcha": null,
      "expireAt": "2026-04-09T03:10:00Z"
    }
  }
}
```

客户端处理要求：

- 当 `result = REGISTERED`：正常注册成功
- 当 `result = VERIFICATION_CODE_REQUIRED`：不要再重复调 `challenge`
- 直接拿返回的 `data.challenge`，继续走：
  1. 可选 `captcha/verify`
  2. `send`
  3. `authenticate`
- 原始 `inviteTicket` 需要客户端继续保留，并在最终 `authenticate` 时带上

## 8. 错误码与客户端处理建议

| code | HTTP | message | 客户端处理建议 |
| --- | --- | --- | --- |
| `4001` | 400 | 参数校验失败 | 检查 body 字段缺失、空串、格式错误 |
| `11101` | 400 | 当前请求缺少 AppId | 客户端或网关请求头配置错误，先修环境 |
| `11103` | 400 | 当前请求缺少租户上下文 | 联调环境网关 / 域名未注入租户 |
| `11116` | 500 | 当前 AppId 未配置注册来源 | 仅 `REGISTER` 场景会命中，服务端配置问题 |
| `11118` | 400 | 验证码错误 | 停留当前输入页，允许重新输入 |
| `11119` | 400 | 验证码已过期 | 提示用户重新获取验证码，必要时重新 challenge |
| `11120` | 429 | 验证码发送过于频繁 | 以 `resendAt` 倒计时为准，禁用重发按钮 |
| `11121` | 409 | 验证码挑战已失效 | 当前 `challengeId` 不可再用，重新从 `challenge` 开始 |
| `11122` | 409 | 请先完成人机验证 | 先调 `captcha/verify` 再调 `send` |
| `11123` | 400 | 人机验证未通过 | 提示重新做人机验证 |

客户端统一规则：

- `11119`、`11121`：直接视为当前 challenge 已不可用，重新走第 1 步
- `11120`：不要重新 `challenge`，优先等待 `resendAt`
- `11122`、`11123`：停留在滑块 / 图形验证码页处理

## 9. APP 不要做的事

- 不要再调旧的 login/register 双验证码路由
- 不要用 `challenge` / `send` 的结果判断“手机号是否已注册”
- 不要把 `captchaPayload` 打到客户端业务日志
- 不要在 `REGISTER` 场景下把成功态强行文案写死成“新账号已创建”
- 不要在密码注册冲突回落后再次额外调一次 `challenge`

## 10. 联调自测清单

APP 提测前至少自测以下分支：

1. `LOGIN` + 无 captcha
2. `REGISTER` + 有 captcha
3. `REGISTER` 场景下手机号已存在，最终仍返回 token
4. `send` 前未做 captcha，正确收到 `11122`
5. captcha 校验失败，正确收到 `11123`
6. 验证码错误，正确收到 `11118`
7. 验证码过期，正确收到 `11119`
8. 重发过快，正确收到 `11120`
9. 密码注册冲突后返回 `VERIFICATION_CODE_REQUIRED`，且能直接续走后面三步


