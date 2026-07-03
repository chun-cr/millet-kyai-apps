---
name: encoding-standards
description: >
  处理本仓库内包含中文注释、中文字符串、Markdown 文档、ARB、本地化资源或任何
  非 ASCII 文本时，必须遵循的编码规范。目标是在 Windows + PowerShell + Codex
  环境下稳定保持 UTF-8 无 BOM，避免“文件本身正常，但终端显示乱码”或“错误编码
  写回源码”的问题。
---

# 编码与注释防乱码规范

## 适用范围

以下场景必须触发本 skill：

- 读取、搜索、比较、打印任何可能包含中文或其他非 ASCII 字符的文件
- 编辑中文注释、中文文档、中文 UI 字符串、ARB、多语言资源
- 排查乱码、BOM、换行符、不可见字符、终端输出异常
- 在 PowerShell 中把文件内容输出到终端，或把代码片段经由管道传给 Python

默认覆盖的文件类型：

- `*.dart`
- `*.md`
- `*.yaml`
- `*.yml`
- `*.json`
- `*.arb`
- `*.py`
- `*.ps1`
- `*.txt`
- `*.toml`
- `*.xml`
- `*.gradle`
- `*.properties`

## 目标状态

- 仓库文本文件编码统一为 UTF-8 无 BOM
- 新增或修改的文本行统一为 LF
- 中文注释和文档在终端、编辑器、Git diff 中都能稳定显示
- Codex 不把“终端显示乱码”误判为“源码已损坏”

## 强制执行规则

### 1. 先修正终端编码，再看文件内容

在 PowerShell 中处理非 ASCII 文本前，先执行以下 UTF-8 预设：

```powershell
$env:PYTHONIOENCODING = 'utf-8'
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
```

可以合并成一行：

```powershell
$env:PYTHONIOENCODING='utf-8'; $OutputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false); [Console]::InputEncoding=[System.Text.UTF8Encoding]::new($false)
```

如果没有先做这一步，不要根据 PowerShell 输出结果判断源码是否乱码。

### 2. 读取包含中文的文件时，必须显式声明 UTF-8

优先做法：

```powershell
$env:PYTHONIOENCODING='utf-8'; $OutputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false); [Console]::InputEncoding=[System.Text.UTF8Encoding]::new($false); @'
from pathlib import Path
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
print(Path("lib/main.dart").read_text(encoding="utf-8"))
'@ | python -
```

可接受做法：

```powershell
Get-Content -Raw -Encoding utf8 lib\main.dart
```

禁止做法：

- 裸用 `Get-Content`、`type`、`more` 读取中文文件
- 用未声明编码的 `Set-Content`、`Out-File`、重定向写回文本文件
- 看见终端里的乱码就直接批量重写源码

### 3. 写入文件时，保持 UTF-8 无 BOM

- Codex 改文件时优先使用 `apply_patch`
- Python 读写文件必须显式 `encoding="utf-8"`
- 不从网页、Word、飞书文档直接粘贴全角符号或不可见字符到源码
- 不把 PowerShell 控制台输出重定向回源码文件

### 4. 提交前必须运行编码检查

默认检查当前工作区改动：

```powershell
python scripts/check_text_encoding.py
```

如果工作区已经有与当前任务无关的脏文件，或仓库仍有历史 CRLF 基线，改为只检查本次触达文件：

```powershell
python scripts/check_text_encoding.py path/to/file1 path/to/file2
```

检查指定文件：

```powershell
python scripts/check_text_encoding.py lib/main.dart docs/接口.md
```

检查全部已跟踪文本文件：

```powershell
python scripts/check_text_encoding.py --all
```

`--all` 适合做专项治理或基线审计；日常任务默认以“当前任务触达文件”作为阻塞范围。

检查失败时，必须先修复再继续。

## 判断原则

### 终端乱码不等于源码乱码

如果出现以下情况：

- `Get-Content` 输出中文异常
- Python 打印中文时报 `UnicodeEncodeError`
- 同一文件在编辑器里正常、在终端里乱码

优先判断为“终端通道编码异常”，先验证文件原始字节和 UTF-8 解码结果，不要立刻修改源码。

### 只有证据充足时才修文件

以下情况才算源码真的有编码问题：

- 文件无法按 UTF-8 解码
- 文件带 UTF-8 BOM，且项目要求无 BOM
- 文件中出现 `U+FFFD` 替换字符
- 文件中混入零宽字符、不可见控制字符、非预期 CRLF

## 中文注释与文案规范

- 注释使用标准简体中文
- 中英文混排时保留必要空格，例如 `获取 user 信息并刷新 UI`
- 代码 token 周围禁止混入全角分号、全角括号、全角方括号
- 注释说明“为什么”，不要机械复述代码

示例：

```dart
// 后端返回秒级时间戳，这里统一转成毫秒，避免 UI 层重复处理
final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
```

禁止：

```dart
final name = "用户名"；
final list = ［1, 2, 3］；
```

## Codex 执行清单

当任务涉及中文注释或非 ASCII 文本时，Codex 必须按以下顺序执行：

1. 先切换 PowerShell/Python 输出为 UTF-8
2. 用显式 UTF-8 的方式读取文件
3. 编辑时保持 UTF-8 无 BOM，不使用默认编码写回
4. 运行 `python scripts/check_text_encoding.py` 校验本次改动
5. 只有在校验通过后，才把编码问题视为已解决

## 与其他规范的关系

- 本 skill 只处理编码、终端输出、中文注释与文本文件安全读写
- Flutter 架构、命名、组件拆分等仍由 `flutter-standards` 负责
- 如果一个任务同时涉及 Flutter 代码和中文文本，两个 skill 都要遵循
