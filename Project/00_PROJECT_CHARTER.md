# 00 · 项目总纲（Project Charter）

> **仓库**：坐标系（Bundle ID `app.zuobiaoxi.coordinate`）  
> **平台**：iOS 26.5+ · SwiftUI First  
> **同步**：2026-09-30（按代码推断；非已编译验收）  
> **本套文档根**：`Project/`（**现行开发规范唯一入口**）

---

## 1. 这套文档是什么

面向「按 Apple 旗舰 App 工程 / HIG 标准做产品」的**开发规范**，不是融资叙事，也不是已废弃的批次进度表。

| 目标读者 | 用法 |
|----------|------|
| 产品 | 01–04、17：范围、流程、模块与页面职责 |
| 设计 | 04–06、12–13、20：体验 / 视觉 / 平台 / 组件 / a11y / 文案 |
| iOS | 06–11、15、17–21：架构、数据、API、状态、导航、屏契约、埋点、性能、工程 |
| 提审 / 联调 | 14、16、18：隐私、上线清单、观测 |

---

## 2. 对参考目录的客观裁剪（不迎合）

参考的 00–16 编号**保留**（便于检索），但本仓做了三处硬约束，避免「文档比产品还厚、还互相打架」：

1. **不写第二套 Design System 长文**  
   `05` / `12` 只定原则与代码锚点；像素级 token 以 `Design/Platform*.swift` 与历史 `DESIGN_SYSTEM.md` 实现为准，避免三处漂移。

2. **诚实区分「客户端规范」与「已上线能力」**  
   登录可远程联调；活动写路径 / 真支付 / 真 IM 仍阻塞（见 `16`）。规范描述「应该怎样」，清单标明「现在有没有」。

3. **旧 `Docs/*` 模块长文降级为过渡索引**  
   `Docs/AuthModule.md` 等可继续读作补充，**冲突时以 `Project/` 为准**。新改动只改 `Project/`。

---

## 3. 产品一句话

**愿景**：让一起玩，变得简单、自然、可信。  
**使命**：发现活动、找到搭子，用消息与履约凭证把「想一起」变成「约上了」。

V1 **不做**：通用社交网络、公开星级人格墙、万能生活服务。

---

## 4. 工程一句话

```
Features（编排）→ Domain UseCases（规则）→ Repository / Snapshot（持久化）
                ↘ Remote API（有则合并，无则本地诚实）
Design / Platform*（系统容器优先，业务少做布局决策）
```

登录：`Services/Auth` UseCases + Keychain/JWT。  
活动：参加 + 主办 Domain UC；表现态在 `ActivitiesPresentationStore`。

---

## 5. 文档地图

| # | 文件 | 回答 |
|---|------|------|
| 00 | 本文件 | 总纲、所有权、冲突规则 |
| 01 | [PRODUCT_SPEC](01_PRODUCT_SPEC.md) | 做什么 / 不做什么 / 验收口径 |
| 02 | [USER_FLOW](02_USER_FLOW.md) | 关键用户路径 |
| 03 | [INFORMATION_ARCHITECTURE](03_INFORMATION_ARCHITECTURE.md) | Tab / 模块边界 |
| 04 | [UX_SPEC](04_UX_SPEC.md) | 体验原则、转化优先 |
| 05 | [UI_SPEC](05_UI_SPEC.md) | 视觉气质与反模式 |
| 06 | [PLATFORM_SPEC](06_PLATFORM_SPEC.md) | Apple 平台硬约束 |
| 07 | [ARCHITECTURE](07_ARCHITECTURE.md) | 分层、DI、组合根 |
| 08 | [DATA_MODEL](08_DATA_MODEL.md) | 实体与快照 |
| 09 | [API_SPEC](09_API_SPEC.md) | 已有 / 契约 / 未接 |
| 10 | [STATE_SPEC](10_STATE_SPEC.md) | Loading / Empty / Error / Feedback |
| 11 | [NAVIGATION_SPEC](11_NAVIGATION_SPEC.md) | Stack / Zoom / Sheet / Deep Link |
| 12 | [COMPONENT_SPEC](12_COMPONENT_SPEC.md) | Design System 组件职责 |
| 13 | [ACCESSIBILITY_SPEC](13_ACCESSIBILITY_SPEC.md) | Dynamic Type / VO / Reduce * |
| 14 | [SECURITY_PRIVACY](14_SECURITY_PRIVACY.md) | 隐私、Keychain、门控 |
| 15 | [TEST_SPEC](15_TEST_SPEC.md) | 测什么、怎么跑 |
| 16 | [RELEASE_CHECKLIST](16_RELEASE_CHECKLIST.md) | 软启动 vs App Store |
| 17 | [SCREEN_SPEC](17_SCREEN_SPEC.md) | 单屏主职 / 输入输出 / 禁止 |
| 18 | [ANALYTICS_SPEC](18_ANALYTICS_SPEC.md) | 漏斗事件与可观测边界 |
| 19 | [PERFORMANCE_SPEC](19_PERFORMANCE_SPEC.md) | 启动 / 滚动 / 内存预算 |
| 20 | [LOCALIZATION_SPEC](20_LOCALIZATION_SPEC.md) | 文案所有权与 Catalog 演进 |
| 21 | [ENGINEERING_WORKFLOW](21_ENGINEERING_WORKFLOW.md) | PR / Flag / DoD / 评审 |

---

## 6. 单一事实源与改文档纪律

| 主题 | 真相源 |
|------|--------|
| 行为是否在 V1 | `01` |
| 门闸顺序 | `02` + `11` |
| 单屏职责 | `17` |
| 分层 import | `07` + `Scripts/check-imports.sh` |
| 文本输入皮 | `12` + `DESIGN_SYSTEM` §7.2.1 + `Scripts/check-text-input.sh`（经 `check-imports`） |
| API 是否已接 | `09`（勿在 PR 描述里「假装已接」） |
| 上线能否提审 | `16` |
| 怎么合码 | `21` |

**改代码若改变路径 / Flag / API 状态 → 同 PR 更新对应编号文档。**  
禁止再开平行「Wave 计划 / 七批次」长文；完成项写入 `Docs/Archive.md`。

AI 会话纪律（指令收窄、自检、强制交付、B 表一项、诚实门控）：见 `21` §7；规则见 `.cursor/rules/`（`instruction-scope-gate` / `agent-self-verify` / `delivery-footer` / `honesty-gates` / `project-docs-dod` / `one-blocker-per-session`）。

---

## 7. 当前成熟度（诚实快照）

| 域 | 客户端规范符合度 | 上线就绪 |
|----|------------------|----------|
| 登录 / 会话 | 高（UseCase、Keychain、Release 远程） | 软启动可联调；Apple 服务端校验 / 微信 SDK 仍欠 |
| 活动发现 UX | 高（货架 + Form + Zoom） | 软启动 UX 可测 |
| 活动数据底座 | 中（Domain 写规则齐；本地快照） | **未**正式供给；写 API 未默认远程 |
| 支付 | 中（诚实门控） | Release 仅本机钱包投影；远程契约已备（`useRemoteWallet` 默认关）；真 PSP 到账前 B1 未清 |
| 搭子 / 消息 / 广场 | 有实现 | 供给 / IM 仍阻塞正式闭环 |
| 文档完备度 | 00–21 覆盖模块→屏→工程 | 实现仍以代码为准；冲突改 `Project/` |

---

*下一篇：[01_PRODUCT_SPEC.md](01_PRODUCT_SPEC.md)*
