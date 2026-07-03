---
name: flutter-enterprise-standards
description: >
  Flutter 企业项目开发规范。当用户在 Flutter 项目中编写任何功能代码、组件、页面、
  网络请求、状态管理、工具类时，必须触发此 skill，确保代码符合企业级规范。
  包括：组件封装、命名规范、目录结构、状态管理、网络层、错误处理、注释规范、
  Git 提交规范等。只要涉及 Flutter/Dart 代码编写或审查，都应使用此 skill。
---

# Flutter 企业项目开发规范

## 联动规则

- 只要任务涉及中文注释、中文字符串、Markdown 文档、ARB 或任何非 ASCII 文本，必须同时遵循 `D:\work\stitch_diag_demo\.omx\skills\encoding-standards\SKILL.md`
- 在 PowerShell 中读取或打印这类文件时，不要直接依赖默认编码；先切到 UTF-8，或改用 Python 显式 `encoding="utf-8"`

## 核心原则

1. **可复用优先**：超过 2 次使用的 UI 或逻辑，必须封装成组件或工具类
2. **单一职责**：每个类/函数只做一件事
3. **显式优于隐式**：代码意图必须清晰，避免魔法数字和隐晦逻辑
4. **统一出口**：同类功能只有一种做法，不允许各写各的

---

## 目录结构

```
lib/
├── main.dart
├── app.dart                  # App 根组件、路由、主题初始化
├── core/
│   ├── network/              # Dio 客户端、拦截器
│   ├── storage/              # 本地存储封装
│   ├── error/                # 统一错误处理
│   └── utils/                # 纯工具函数（无 UI、无状态）
├── shared/
│   ├── components/           # 全局通用组件
│   ├── constants/            # 常量、枚举
│   └── extensions/           # Dart extension 方法
├── features/                 # 按功能模块划分
│   └── [feature_name]/
│       ├── data/             # 数据层：API、Repository
│       ├── domain/           # 业务层：Model、逻辑
│       └── presentation/     # 表现层：页面、组件、状态
└── gen/                      # 自动生成文件（assets、国际化等）
```

---

## 组件封装规范

### 何时必须封装

- 同一 UI 片段在 **2 个或以上** 地方出现 → 必须提取为 Widget
- 单个 `build()` 方法超过 **80 行** → 必须拆分子组件
- 含有业务逻辑的 UI → 逻辑提取到 Controller/Notifier，UI 只做渲染

### 组件分类

| 类型 | 位置 | 说明 |
|------|------|------|
| 全局通用组件 | `shared/components/` | 按钮、输入框、弹窗、Loading 等无业务逻辑组件 |
| 功能内组件 | `features/[name]/presentation/widgets/` | 仅该功能使用的组件 |
| 页面 | `features/[name]/presentation/pages/` | 以 `Page` 结尾，只负责组合组件 |

### 组件编写规范

```dart
// ✅ 正确：提取常量，参数明确，有默认值
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;

  @override
  Widget build(BuildContext context) { ... }
}

// ❌ 错误：内联重复 UI，硬编码样式
Container(
  decoration: BoxDecoration(color: Color(0xFF4A7A48), borderRadius: BorderRadius.circular(14)),
  child: Text('提交'),
)
```

---

## 命名规范

### 文件命名
- 全部使用 `snake_case`
- 页面：`login_page.dart`
- 组件：`user_avatar.dart`
- 控制器：`login_controller.dart`
- 模型：`user_model.dart`
- 接口：`auth_api.dart`

### 类命名
- 页面：`LoginPage`
- 组件：`UserAvatar`
- 状态管理：`LoginController`、`LoginNotifier`
- 模型：`UserModel`
- 枚举：`UserStatus`（单数）

### 变量/函数命名
- 变量、函数：`camelCase`
- 常量：`camelCase`（Dart 规范，不用全大写）
- 私有成员：`_camelCase`
- 布尔值：以 `is`/`has`/`can` 开头，如 `isLoading`、`hasError`

### 禁止
```dart
// ❌ 禁止无意义命名
var data;
var temp;
void doSomething() {}

// ❌ 禁止缩写（常见缩写除外：id、url、api）
var usrNm;
void calcPrc() {}
```

---

## 网络请求规范

### 分层结构

```
API 层 (api/)         → 只负责发请求，返回原始数据
Repository 层 (data/) → 处理数据转换、缓存逻辑
Controller 层         → 调用 Repository，管理 UI 状态
```

### API 层写法

```dart
// ✅ 正确
class AuthApi {
  final DioClient _client;
  AuthApi(this._client);

  Future<Response> login(LoginRequest request) {
    return _client.dio.post('/api/auth/login', data: request.toJson());
  }
}

// ❌ 错误：在页面里直接调用 dio
dio.post('/api/auth/login', data: {...});
```

### 错误处理

所有网络请求必须经过统一错误拦截器处理，页面层只处理业务逻辑分支，不处理网络异常细节：

```dart
// ✅ 正确：Controller 层
Future<void> login() async {
  state = state.copyWith(isLoading: true);
  try {
    final result = await _authRepo.login(email, password);
    state = state.copyWith(user: result, isLoading: false);
  } on AppException catch (e) {
    state = state.copyWith(error: e.message, isLoading: false);
  }
}

// ❌ 错误：在 UI 层 try/catch 网络请求
onPressed: () async {
  try {
    await dio.post(...);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

---

## 状态管理规范

### 规则

- 统一使用项目约定的状态管理方案（Riverpod / Bloc / GetX 三选一，全项目一致）
- 禁止混用多种状态管理方案
- `StatefulWidget` 只用于纯 UI 动画状态（如 `AnimationController`），业务状态不得放在 Widget 内

### 状态模型

```dart
// ✅ 使用不可变状态模型
@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    @Default(false) bool isLoading,
    String? error,
    UserModel? user,
  }) = _LoginState;
}
```

---

## 常量与主题规范

### 禁止魔法数字和魔法颜色

```dart
// ❌ 禁止
SizedBox(height: 24)
Color(0xFF4A7A48)
BorderRadius.circular(14)
TextStyle(fontSize: 16, fontWeight: FontWeight.w500)

// ✅ 正确
SizedBox(height: AppSpacing.md)
AppColors.primary
AppRadius.card
AppTextStyles.bodyMedium
```

### 常量文件结构

```dart
// shared/constants/app_colors.dart
class AppColors {
  static const primary = Color(0xFF4A7A48);
  static const background = Color(0xFFF5F2EC);
  // ...
}

// shared/constants/app_spacing.dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
```

---

## 注释规范

### 必须写注释的情况

- 公共组件和公共方法：写 `///` 文档注释
- 复杂业务逻辑：写行内注释说明「为什么」，而不是「做什么」
- 临时方案或已知问题：用 `// TODO:` 或 `// FIXME:` 标注

```dart
// ✅ 正确：说明原因
// 后端返回的时间戳是秒级，需要乘以 1000 转换为毫秒
final time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

// ❌ 错误：注释只是重复代码
// 将 timestamp 乘以 1000
final time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

/// 用户头像组件
/// 
/// [size] 头像尺寸，默认 40
/// [url] 头像图片地址，为空时显示默认占位图
class UserAvatar extends StatelessWidget { ... }
```

---

## Git 规范

### .gitignore 必须包含

```
.dart_tool/
.idea/
build/
*.g.dart        # 如果不提交生成文件
*.freezed.dart  # 如果不提交生成文件
.env
.env.*
```

### Commit Message 格式

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <描述>

type:
  feat     新功能
  fix      修复 bug
  refactor 重构（不影响功能）
  style    代码格式（不影响逻辑）
  chore    构建/工具/依赖变更
  docs     文档
  test     测试

示例：
feat(auth): 新增手机号登录功能
fix(network): 修复 token 过期后未自动刷新的问题
refactor(user): 提取 UserAvatar 为独立组件
chore: 更新 flutter 依赖至 3.x
```

### 分支规范

```
main          生产环境，只接受 PR 合并
develop       开发主分支
feature/xxx   新功能分支，从 develop 切出
fix/xxx       修复分支
release/x.x   发版分支
```

---

## Code Review 检查清单

提交 PR 前自查：

- [ ] 重复 UI 是否已封装为组件
- [ ] 是否有魔法数字/颜色/尺寸
- [ ] 网络请求是否在正确的层级
- [ ] 状态管理是否符合约定方案
- [ ] 新增公共组件是否有文档注释
- [ ] `.gitignore` 是否正确，无多余文件提交
- [ ] Commit message 是否符合规范
- [ ] 是否有遗留的 `print()` 调试语句（应使用 logger）
