# 报告页付费解锁设计方案

## 目标

在当前 `report_page.dart` 基础上，实现：

- `总览` 免费可看
- `体质 / 调理 / 建议` 作为深度内容模块锁定
- 点击任意锁定模块统一进入“解锁报告”流程
- 当前先走本地 mock 成功流程
- 后续再替换为 Apple IAP

本方案强调：

- **最小结构改造**
- **最大化复用现有组件**
- **避免当前多 Tab 结构与付费锁定交互冲突**

---

## 为什么不推荐继续保留多 Tab 锁定

当前结构：

- Tab1：总览
- Tab2：体质
- Tab3：调理
- Tab4：建议

问题：

1. `TabBarView` 支持横滑，用户会不断滑入锁页，体验像坏掉而不是高级内容
2. 四个 tab 会被理解为平级内容，但实际上 Tab2-4 都是“深度内容”
3. 锁定态、支付态、当前 tab 状态三者叠加后，Flutter 代码会明显变复杂

因此本方案采用：

> **单页总览 + 3 个锁定深度模块**

---

## 推荐结构（采用方案）

### 免费区

保留当前最有价值的免费内容：

- Hero
- 健康分
- 三诊评分
- 舌象 / 五行概览
- 辨证摘要

### 付费区

改为 3 个锁定模块卡：

1. 体质详解
2. 调理方案
3. 个性化建议

每个模块卡：

- 标题
- 一句摘要
- 1~2 个 teaser 点
- 渐变遮罩
- 锁图标
- 主按钮：`解锁报告`

### 解锁后

用户完成解锁后：

- 同页原位展开完整模块内容
- 不恢复原来的 4 个 Tab 结构

---

## 组件结构建议

```dart
ReportPage (StatefulWidget)
 ├─ _ReportSliverHeader
 │   └─ _ReportHeroSpace
 │
 └─ 单页滚动内容
     ├─ _ReportOverviewSection
     ├─ _PremiumEntryBanner（可选）
     ├─ _PremiumModuleSection(type: constitution)
     │   ├─ lockedPreview
     │   └─ _ConstitutionModuleContent
     ├─ _PremiumModuleSection(type: therapy)
     │   ├─ lockedPreview
     │   └─ _TherapyModuleContent
     └─ _PremiumModuleSection(type: advice)
         ├─ lockedPreview
         └─ _AdviceModuleContent
```

---

## 现有代码如何改造

### 保留

- `_buildSliverHeader`
- `_ReportHeroSpace`
- `_Tab1Overview` 的大部分免费内容
- `_buildConstitutionDetail`
- `_buildCausalAnalysis`
- `_buildDiseaseTendency`
- `_buildBadHabits`
- `_buildAcupuncturePoints`
- `_buildMentalWellness`
- `_buildSeasonalCare`
- `_buildTongueAnalysis`
- `_buildDietAdvice`
- `_buildProductRecommendations`

### 改造

把：

- `_Tab2Constitution`
- `_Tab3Therapy`
- `_Tab4Advice`

改成纯内容组件：

- `_ConstitutionModuleContent`
- `_TherapyModuleContent`
- `_AdviceModuleContent`

注意：

- 不再返回 `ListView`
- 改为返回 `Column`
- 这样才能嵌进同一个页面中

### 去掉

- `TabBarView`
- 深度 tab 的对外曝光
- 基于 tab 的切换逻辑

---

## 锁定态组件建议

### 1. `LockedContentOverlay`

职责：

- 负责预览内容 + 渐变遮罩 + 锁定提示 + CTA

核心视觉：

- 上半区显示真实 preview 内容
- 中下区渐变遮罩
- 底部锁定信息卡

### 2. `PremiumModuleSection`

职责：

- 统一管理模块的 locked / unlocked 切换

行为：

- `unlocked == false` → 显示 `LockedContentOverlay`
- `unlocked == true` → 显示完整模块内容

---

## 状态模型（第一版）

第一版推荐只做整份报告统一解锁，不做模块单独购买。

```dart
enum PremiumModuleType { constitution, therapy, advice }

class ReportAccessState {
  final bool isUnlocked;
  final bool isUnlocking;
  final PremiumModuleType? targetModule;

  const ReportAccessState({
    required this.isUnlocked,
    required this.isUnlocking,
    this.targetModule,
  });
}
```

页面级本地状态即可，暂不需要引新的状态管理。

---

## 交互流程

### 未解锁

用户进入报告页：

- 免费内容正常展示
- 深度模块以锁定卡片展示

点击任意锁定模块：

- 记录 `targetModule`
- 弹出统一支付弹层

### mock 解锁成功

- `isUnlocked = true`
- 关闭弹层
- 三个模块全部展开
- 如有 `targetModule`，滚动到对应模块位置

### 后续接 Apple IAP

只替换解锁动作，不重写页面结构：

- 当前 `mock unlock success`
- 替换成 `IAP purchase success`

---

## 推荐的免费 / 付费切分

### 免费

- Hero
- 健康分
- 三诊评分
- 舌象 / 五行概览
- 辨证摘要
- 每个深度模块的 teaser

### 付费

#### 体质
- 体质详解
- 成因分析
- 易诱发疾病
- 不当习惯

#### 调理
- 穴位方案
- 精神养生
- 四季保养

#### 建议
- 舌象详解
- 饮食建议
- 产品推荐

---

## 为什么这个方案最适合当前代码

1. **改动最小**：现有深度模块内容大量可复用
2. **逻辑最干净**：锁定逻辑集中在外层壳组件，不散落到每个模块里
3. **付费体验更顺**：用户先看到价值，再决定是否解锁
4. **后续替换支付方式最顺**：mock → Apple IAP 不需要重做页面架构

---

## 第一版实现边界

本次建议只做：

- 免费总览
- 3 个锁定模块
- 统一“解锁报告”入口
- 本地 mock 成功流

本次不做：

- 单模块购买
- 恢复购买
- 真正的 Apple IAP 接入
- 后端权益同步

---

## 实施顺序建议

1. 新增 `ReportAccessState`
2. 去掉深度 `TabBarView`
3. 把 Tab2/3/4 改成纯内容组件
4. 新增 `LockedContentOverlay`
5. 新增 `PremiumModuleSection`
6. 在总览下插入 3 个锁定模块
7. 新增统一支付弹层（mock）
8. mock 成功后展开全部模块

---

## 当前建议结论

> 采用“单页总览 + 3 个锁定深度模块 + 统一解锁报告”的结构，先走 mock 购买流，后续平滑替换 Apple IAP。 
