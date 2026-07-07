我刚用提升权限确认了本机环境：Flutter 3.38.5 / Dart 3.10.4。这个版本下，forui 最新版暂时不合适，因为它当前页明确写了 0.22.0+ 需要 Flutter 3.44.0+。除非我们升级 Flutter，否则不建议接它。forui
更稳的选择是：
优先用现有依赖做“设计组件层”
项目里已经有 flutter_animate、shimmer、fl_chart。flutter_animate 本身就是成熟的 UI 动效库，适合做报告卡片进入、展开、状态反馈，不需要新增依赖。flutter_animate

如果要上第三方组件库，我更倾向 shadcn_flutter
它可以和现有 MaterialApp 增量混用，组件覆盖 Card、Dialog、Sheet、Tabs、Form、Input、Badge、Skeleton 等，视觉会比 Flutter 默认控件现代很多。shadcn_flutter

表单类可以考虑 flutter_form_builder，但不是视觉库
它适合“用户自述 / 调理建议编辑 / 多字段保存”这种表单，能减少表单校验和取值样板代码，但美观还要靠我们的壳组件和主题。flutter_form_builder
