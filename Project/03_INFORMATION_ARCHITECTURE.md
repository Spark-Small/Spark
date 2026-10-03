# 03 · 信息架构 / App 模块（IA）

---

## 1. 顶层 IA（Tab）

顺序固定（与 `ContentView` 一致）：

| Tab | 职责 | 根视图 |
|-----|------|--------|
| 活动 | 发现局、参加、发起；顶栏与五 Tab 同套 `platformTabRoot*` | `ActivitiesView` |
| 搭子 | 找搭子 / 约陪玩 / 俱乐部（标题菜单互切）；顶栏与五 Tab 同套 `platformTabRoot*` | `BuddiesView` |
| 广场 | 分享浏览；顶栏同套；发分享 + 系统搜索；筛选与推荐置顶；**互动通知归「我的」铃铛**；内容库归「我的」；完善方案见 [CommunityModule](../Docs/CommunityModule.md) | `CommunityView` |
| 消息 | 私聊、活动群；顶栏同套 | Messages 根 |
| 我的 | 身份、待办、服务（会员/钱包/订单）、我的内容（活动/预约/俱乐部/广场库）、设置；顶栏 **通知 + 设置**；最近浏览不在此 Tab | `ProfileView` |

未登录：**无 Tab**，仅会话门闸表面。

---

## 2. 模块边界（代码 = 架构）

| 模块 | 目录 | 拥有 | 不拥有 |
|------|------|------|--------|
| Auth / Launch | `Features/Launch` + `Services/Auth` | 登录、兴趣、欢迎、会话 | 报名业务规则 |
| Activities | `Features/Activities` + Domain Activities UC | 发现、详情、参加、主办编排 | Keychain、直接 Remote I/O |
| Buddies | `Features/Buddies` | 人/预约 UI | 活动主办规则 |
| Messages | `Features/Messages` | 会话 UI | 登录 |
| Profile | `Features/Profile` | 资料、凭证、钱包、广场内容库入口 | 发现货架 |
| Notifications | `Features/Notifications` + `InAppNotificationStore` | 站内通知中心、未读角标、深链打开 | 支付 / IM 投递真相 |
| Trust | `Features/Trust` + Trust Services | 核验、信用展示 | 支付 PSP |
| Design | `Design/` | Platform chrome、货架组件 | Feature 业务状态 |
| Domain | `Packages/.../CoordinateDomain` | UseCase、协议 | SwiftUI |
| Data / API | CoordinateData + `Services/API` | Repository、Endpoint | View |

**CI**：`Scripts/check-imports.sh`（Features 禁止 `import CoordinateData` / 直连 `AppComposition`）。

---

## 3. 活动模块内部分层（现行）

```
ActivitiesView（编排）
ActivitiesModel（目录 + 报名快照门面）
ActivitiesPresentationStore（Sheet / toast）
ActivitiesModel+Participation / +Hosting → Domain UC
Repository Snapshot ↔（可选）Remote catalog Merge
```

主办业务规则在 Domain，不在 View。

搭子域对照：`BuddiesModel`（快照门面）+ `BuddiesPresentationStore`（Sheet / toast）+ Domain 预约 UC / Merge。

---

## 4. 跨模块事件（编排层）

| 事件 | 编排者 | 下游 |
|------|--------|------|
| 参加成功 | `AppModel` + SyncOrchestrator | 群、通知、engagement |
| 发布成功 | 同上 | 群 |
| 登出 / 远程失效 | `LocalAuthSession` | 拆 `AppModel`、回登录 |
| 核验未过 | `IdentityAccessGate` | 编辑资料 / 认证 Sheet |

---

## 5. 模块成熟度（客观）

| 模块 | IA 清晰度 | 数据真相 |
|------|-----------|----------|
| Auth | 清晰 | Release 远程为主 |
| Activities | 清晰 | 本地快照 + 可选远程目录合并；写默认本地 |
| Buddies | 清晰 | 客户端接后端就绪：Merge + catalog 契约 + 预约已接 + 邀约/俱乐部写契约（Flag 关）；开发态 Sample/空态 CTA；**B4/B5/B1 仍待后端与运营** |
| Messages | 清晰 | 需真 IM 才闭环 |
| Profile / Trust | 清晰 | 核验本地 + 策略门控 |

---

## 6. 页面级职责

模块表不够支撑旗舰审阅时，用 **[17_SCREEN_SPEC](17_SCREEN_SPEC.md)**：每屏主职 / 输入 / 输出 / 禁止。  
新增主路径屏：先改 `17`，再写 View。

---

## 7. 依赖方向（硬）

```
Features → Domain / Models / FeatureFlags / Design
Services（组合根、Auth、API）→ Data / Networking / Domain
Design → 无业务 Snapshot
Domain → Models（无 SwiftUI、无具体 URLSession）
```

反向依赖（View 调 Repository、Domain 引用 Feature）视为架构缺陷，PR 拒收。

---

*下一篇：[04_UX_SPEC.md](04_UX_SPEC.md)*
