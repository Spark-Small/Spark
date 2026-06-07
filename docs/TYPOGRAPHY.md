# Spark Typography — 系统语义样式规范

> **Status:** Canonical — 与 `main` 代码一致。  
> **Last updated:** 2026-06-07  
> **Related:** [TAB_SCREENS.md](TAB_SCREENS.md) L3 · [HIG_COMPLIANCE.md](HIG_COMPLIANCE.md) · `.cursor/rules/ios-design-system.mdc`

Spark **不定义自定义字体族**。全部使用 Apple **SF Pro 系统语义 Text Style**（SwiftUI `Font` 文本样式），配合语义前景色与 Dynamic Type，与电话、信息等系统 App 同源。

---

## 原则

| 规则 | 说明 |
|------|------|
| 语义样式 | 使用 `.largeTitle` … `.caption2`，禁止为正文硬编码 point size |
| 字重 | 在语义样式上加 `.weight(.semibold)` 等，不替换为自定义字体 |
| 颜色 | `.primary` / `.secondary` / `Color.accentColor`；禁止 hex 灰表达层级 |
| Dynamic Type | 所有用户可见文案必须随系统字号缩放；Preview 测 XL |
| 本地化 | `String(localized:defaultValue:comment:)`；禁止拼接本地化字符串 |

**权威禁止项**见 [HIG_COMPLIANCE.md §2](HIG_COMPLIANCE.md#2-hard-coded-fonts-that-break-dynamic-type)。

---

## 语义层级（项目通用）

| 层级 | SwiftUI 样式 | 字重 | 前景色 | 典型用途 |
|------|-------------|------|--------|----------|
| 屏幕主标题 | `.largeTitle` | `.bold` | `.primary` | Tab 根页大标题（活动、我的等；社区/消息无） |
| 区块 / 卡片主标题 | `.title2` / `.title3` | `.bold` / `.semibold` | `.primary` | Match 标题、社区详情名、无图帖摘要 |
| 列表 / 卡片行标题 | `.body` / `.subheadline` | `.semibold` | `.primary` | 社区行名、帖子作者、会话名 |
| Section / 分段标签 | `.subheadline` | `.semibold` | `.secondary` | `CommunityFeedSectionHeader`、表单 Section |
| 正文 | `.body` / `.subheadline` | regular | `.primary` | 帖子详情、回复、简介 |
| 元数据 | `.caption` | regular / `.medium` / `.semibold` | `.secondary` | 社区名、统计、标签、关联活动 |
| 辅助 / 时间 | `.caption2` | regular / `.bold` | `.secondary` | 时间戳、成员数、角标数字 |
| 说明 / 脚注 | `.footnote` | regular | `.secondary` | Composer 提示、Premium 说明、空态副文案 |

**关系 / 强调：** 在 `.caption` 上使用 `Color.accentColor`（共同活动、局后随拍角标等），不用更大字号表达优先级。

---

## 导航与工具栏

| 元素 | 规范 |
|------|------|
| Tab 根大标题 | `SparkScreenContainer` 默认 `.large`（活动、我的等） |
| 详情 / Sheet | `.inline` + 具体标题文案 |
| 社区 / 消息 Tab 根 | **无中间导航标题**（`navigationTitle: ""`）；Tab 项已标识 |
| 顶部分段（社区） | `Picker(.segmented)` · `ToolbarItem(placement: .principal)` · `maxWidth: 280`；标签文案用系统 segmented 默认字号 |
| Toolbar 图标按钮 | SF Symbol + `accessibilityLabel`；触控区 ≥ 44pt |

---

## 代码写法

### ✅ 推荐

```swift
Text(title)
    .font(.subheadline.weight(.semibold))
    .foregroundStyle(.secondary)

Text(body)
    .font(.body)

Text(metadata)
    .font(.caption)
    .foregroundStyle(.secondary)
```

### ❌ 禁止（正文）

```swift
.font(.system(size: 14))
.font(.custom("SomeFont", size: 16))
.foregroundStyle(Color(white: 0.6))
```

### ⚠️ 允许例外（须 `// REASONING:`）

| 场景 | 写法 |
|------|------|
| 装饰性 SF Symbol（头像占位、引导插图） | `@ScaledMetric` + `.font(.system(size: X))` 或 `.font(.system(size: X, relativeTo: .title))` |
| 照片叠层姓名 | `.title2.bold` + `sparkPhotoTextScrim()` |

---

## 按 Tab 速查

组件级像素 spec（间距、尺寸）见 [TAB_SCREENS.md](TAB_SCREENS.md) L3；下表仅列**字号**。

### 喜欢

| 元素 | 样式 |
|------|------|
| 卡片姓名 | `.title2.bold`（叠层） |
| 地点 / Bio | `.subheadline` / `.caption` secondary |
| Inbound 姓名 | `.subheadline.semibold` |
| 角标 | `.caption2.bold` |

### 社区

| 元素 | 样式 |
|------|------|
| 分段「动态 / 我的社区」 | 系统 `Picker(.segmented)` 默认 |
| Section 标题 | `.subheadline.semibold` + `.secondary` |
| 帖子作者 | `.body.semibold` · 头像 36pt · 时间 `.caption2` 右对齐 |
| 帖子社区名 | 紧跟作者名后 `·` + `.footnote` secondary |
| 共同活动（和你去了） | 第二行 `.footnote.semibold` + accent（最高优先级） |
| 关联活动 + 局后随拍 | 第三行 `📅 活动名 · 局后随拍`；与 L2 同活动不重复 |
| 帖子正文（有图） | `.body` · **作者名 semibold + 正文**（Instagram 式） |
| 帖子正文（无图） | `.body` 直接在作者下（Threads 式） |
| 帖子正文（详情） | `.body` |
| 操作栏 | `.subheadline` 图标 · 计数 secondary |
| 标签 | `.footnote` accent · 配文末尾、互动栏之上（`CommunityPostTagsRow`） |
| 时间 | `.caption2` tertiary（作者行右侧） |
| 横滑社区名 | `.caption.semibold` |
| 横滑成员数 | `.caption2` secondary |
| 社区行标题 | `.body.semibold` |
| 社区行统计 | `.caption` secondary |
| 加入提示标题 / 说明 | `.subheadline.semibold` / `.footnote` secondary |
| 探索社区行 | `.body.semibold` 名 · `.footnote` 统计/bio · 无玻璃卡片 |
| 帖子详情作者 | `.body.semibold` primary |
| 帖子详情正文 / 回复 | `.body` |
| 评论区标题 | `.subheadline.semibold` + `.secondary`（「评论 · N」） |
| 回复行作者 | `.subheadline.semibold` primary |
| 活动关联（详情） | 作者下同行 `CommunityPostLinkedActivityLine` `.footnote` · 可点击 |
| 社区详情名 | `.title3.semibold` · 统计 `.footnote` · 简介 `.body` secondary |
| 社区详情活动行 | `.body.semibold` + 时间 `.footnote` |
| 社区详情帖子行 | `.subheadline.semibold` + `.body` + 互动 `.footnote` |
| 成员行 | `.body.semibold` + bio `.footnote` |
| 评论输入框 | `.body` |

### 消息

| 元素 | 样式 |
|------|------|
| Inbox Section 标题 | `.subheadline.semibold` + `.secondary` |
| 会话名 | `.body.semibold`（未读）/ `.body`（已读） |
| 预览文案 | `.subheadline` primary / secondary |
| 时间 | `.caption2` tertiary · 名称行右侧 |
| 未读角标 | `.caption2.semibold` · `UnreadBadge` · 头像右上角 |
| 群聊行 | 与消息行相同（无额外元数据行） |
| Action 卡片标题 | `.body.semibold` |
| Action 卡片元数据 | `.subheadline` secondary |
| 群聊顶栏标题 | `.subheadline.semibold` |
| 群聊顶栏倒计时 | `.caption` secondary |
| DM 共同活动 chip | `.caption2` + `.caption.semibold` |
| 气泡正文 | `.body` |
| 富卡片标题 | `.body.semibold` |
| Composer 输入 | `.body` · `.quaternary` 背景 · `.bar` 底栏 |

### 活动

| 元素 | 样式 |
|------|------|
| Segmented 筛选 | 系统 `Picker(.segmented)` · `maxWidth: 280` 居中 |
| 即将行动 Section | `.subheadline.semibold` + `.secondary` |
| 行日期块 | 月 `.caption2.semibold` · 日 `.title3.bold` |
| 行分类 | `.caption.semibold` uppercase secondary |
| 行标题 | `.body.semibold` |
| 行日期/时间 | `.subheadline` secondary（两行，Meetup 式） |
| 行地点 | `.subheadline` secondary |
| 行主办 | `.caption` secondary |
| RSVP 胶囊 | `.caption.medium` secondary |

### 我的

见 [TAB_SCREENS.md](TAB_SCREENS.md) Tab 5 L3；遵循上表语义层级。

---

## PR / 审查清单

- [ ] 无裸 `Font.system(size:)` 用于正文（例外已注释 `REASONING`）
- [ ] 层级用 **样式 + secondary**，非更小 point size 硬编码
- [ ] Section 标题使用 `.subheadline.semibold` + `.secondary`
- [ ] Preview 含 Dark + Accessibility XL
- [ ] 新 UI 文案已本地化

---

## 实现索引

| 类型 | 位置 |
|------|------|
| 间距 Token | `SparkLayoutMetrics` |
| 社区 Section 标题 | `CommunityFeedSectionHeader.swift` |
| 社区帖子卡片 | `CommunityPostCard.swift` |
| UI Skill 摘要 | `.cursor/skills/spark-ui-spec/references/typography.md` |
