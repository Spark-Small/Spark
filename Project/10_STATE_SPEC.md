# 10 · 状态规格（Loading / Error / Empty / Feedback）

---

## 1. 状态分层

| 层 | 例子 | 存放 |
|----|------|------|
| 会话 | 未登录 / 已登录 / 协议待签 | `LocalAuthSession` + ContentView |
| 领域快照 | 目录、报名集合 | `ActivitiesModel` 等 |
| 表现 | Sheet、toast、compose | `ActivitiesPresentationStore` 等 |
| 系统 | 持久化健康、远程 sync 状态 | `AppPersistenceHealth` / `RemoteSyncStatus` |

**原则**：表现态不进 Snapshot；领域规则不进 View `@State` 散落复制。

---

## 2. Loading

| 场景 | UI |
|------|------|
| 已登录冷启动模型未就绪 | 启动屏底色 + Logo（非假进度条） |
| 表单提交 / 支付 | 按钮 disabled + 系统 Progress 或 processing 文案 |
| 媒体处理 | `ProgressView` +「正在处理…」 |
| 远程目录 | 静默；失败保留本地，不挡浏览 |

避免全屏阻塞 Loading 盖在可浏览货架上。

---

## 3. Empty

全 App 统一系统空态（Apple `ContentUnavailableView`）：

| 规则 | 要求 |
|------|------|
| 组件 | 仅 `ContentUnavailableView`；搜索无结果仅 `.search` / `.search(text:)` |
| 结构 | `Label(title, systemImage:)` + `description: Text` + 可选 `actions: { Button… }` |
| 行动 | 裸 `Button`（系统 tint 文字）；**禁止**空态挂 `activityPrimaryCTA` / `activitySecondaryCTA` / `.borderedProminent` / `.buttonSizing` |
| 留白 | 交给系统居中；**禁止**再叠 `emptyStateVerticalPadding` 业务空态皮 |
| 放置 | **纯空页**：`Group { if empty { … } else { List } }` + `platformContentUnavailablePageChrome()`。**Scroll 货架 / 社交主页**：空态作内容子视图（头/档条下）+ `platformScrollEmbeddedEmptyChrome()` 随滚区内居中。**禁止** `List`/`Scroll` `.overlay` 钉死、空态做 List 行 / Scroll **首行**顶对齐、再叠业务垂直 padding |
| 文案 | 进 `*Copy`；诚实说明，不塞假供给 |

| 场景 | 行动示例 |
|------|------|
| 发现无结果（筛选） | 清除条件 |
| 发现无局 | 发起活动 |
| 订单空 | 去发现 |
| 评论空 | 写评论提示 |
| 搭子供给空（Release） | 诚实空态，不塞 Sample 交易 |

---

## 4. Error

| 类型 | 呈现 |
|------|------|
| 可恢复业务错（满员、未支付） | light feedback / alert 文案 |
| 持久化失败 | 横幅 +「保存失败…」 |
| 会话失效 | 强制登出 |
| 远程读失败 | 记录 sync status；UI 不恐吓式弹窗刷屏 |

禁止吞错后假装成功。

---

## 5. Feedback 通道

见 `04`：仅系统 alert / `platformFeedbackAlert` / `platformLightFeedback` / Dialog。  
**禁止**自定义 Toast。

---

## 6. 活动表现态字段（现行）

`ActivitiesPresentationStore`：

- `isComposing` / `editingActivityID`  
- `joinSuccessActivityID` / `publishSuccessActivityID`  
- `toastMessage` / `lightFeedbackMessage`  

领域集合（`joinedIDs` 等）留在 `ActivitiesModel`。

### 6.1 搭子表现态（现行）

`BuddiesPresentationStore`（挂在 `BuddiesModel.presentation`）：

- Sheet：`inviteTarget` / `bookingPresentation` / `isComposingClub` / `pendingOrgJoin*` / `pendingOrgInvite`  
- 订单链路 pending：acknowledgement / success / payment / awaitingPaymentReview / safetyCheckIn / inviteSuccess  
- `toastMessage`  

预约 / 邀约 / 俱乐部记录仍在 `BuddiesModel` 快照字段。

---

## 7. 四态矩阵（按屏填 · 模板）

主路径屏在 PR / `17` 中应能回答：

| 屏 | Content | Loading | Empty | Error |
|----|---------|---------|-------|-------|
| 发现 | 货架 | 不挡浏览的静默 sync | `ContentUnavailableView` + 行动 | sync 失败不弹窗刷屏；持久化横幅 |
| 详情 | Form + CTA | CTA processing | 活动缺失 → 返回/说明 | 业务错 light feedback |
| 登录 | 表单 | 主按钮 processing | n/a | 错误文案可读、非仅颜色 |
| 兴趣 | 选择器 | 提交中 | n/a | 下限不满足可感知 |

未单独列表的 Sheet：至少 Content + Error（或 dismiss + feedback）。

---

## 8. 离线与重试

| 场景 | 行为 |
|------|------|
| 无网读目录 | 本地 Snapshot；标明或静默保持上次 |
| 无网写（远程写未开） | 本地写照常；远程写开启后：失败入对账队列或明确「未同步」——**禁止**显示成功却丢数据 |
| 用户触发重试 | 空态/横幅提供一次明确重试；自动退避见 `09` |

---

## 9. 谁拥有哪类状态（防泄漏）

| 状态类 | 允许位置 | 禁止 |
|--------|----------|------|
| 报名/主办结果 | Domain → Model 快照字段 | View `@State` 私藏一份「已参加」 |
| Sheet 显隐 | PresentationStore / 明确 `@State` | 写入 Snapshot |
| 「正在提交」 | 该次操作作用域 | 全局永久 flag 忘清 |
| 会话 | Auth 会话栈 | 活动 Model |

---

*下一篇：[11_NAVIGATION_SPEC.md](11_NAVIGATION_SPEC.md)*
