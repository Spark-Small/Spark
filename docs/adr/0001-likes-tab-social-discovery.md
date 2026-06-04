# ADR-0001: Likes Tab = social discovery (SparkLikes)

- **Date:** 2026-06-05
- **Status:** Accepted

## Context

「喜欢」Tab 曾临时挂载 `SparkActivity` 的活动浏览列表，与产品定义的 TikTok 式 **人发现**（图/视频 + 喜欢/配对/好友）不符。活动收件箱已在「活动」Tab 完成。

## Decision

1. 新建 **`Packages/SparkLikes`**，Tab 根视图为 `LikesRootView`（垂直分页卡片流）。
2. **删除** `SparkActivity` 内未接线的 `ActivityBrowse*`（曾误挂在喜欢 Tab）；**人发现** 仅走 `SparkLikes` + `/v1/likes/*`。
3. **活动 Tab** 仅 `ActivityRootView`（收件箱 / 我主办等）；活动 Universal Link / 搜索进详情默认 **`SparkTab.activity`**。
4. 配对成功后经 `MessagesRepository.ensureDirectMessageThread` 进入消息，不在 Likes 内嵌聊天。
5. **未来「逛局」**（公开活动列表）若做，单独 PR + ADR；计划 API 为 `GET /v1/activities/browse`（见 [ACTIVITY_UPGRADE_PLAN.md](../ACTIVITY_UPGRADE_PLAN.md) Phase 19），**当前 iOS 未实现**。

## Consequences

- **Pros:** 模块边界清晰；Mock/Live 可并行；符合「形式服从功能」。
- **Cons:** 多一个 SPM 包与契约面；需维护推荐/审核后端。

## Alternatives considered

- **继续用 ActivityBrowseRootView：** 拒绝 — 与喜欢 Tab 人发现混淆；已删除死代码（2026-06-05）。
- **在 SparkActivity 保留 `fetchBrowsableActivities` 无 UI：** 拒绝 — 膨胀 Repository 且无调用方。
- **合并进 SparkCommunity：** 拒绝 — 内容形态与 UGC 帖子不同。
