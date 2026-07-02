# Community UGC — compliance checklist (MODULE-E.0)

**Status:** Draft for Staging / internal review. **Not** a substitute for legal sign-off or ICP filing.

Related: [MISSING_MODULES_PLAN.md](MISSING_MODULES_PLAN.md) MODULE-E · [API_CONTRACT.md](API_CONTRACT.md)

## Scope (v1)

- Text posts and replies only (`POST /v1/community/posts`, `POST .../replies`)
- Report API (`POST /v1/community/posts/{post_id}/report`) → `spark_community_reports` queue
- No public moderation console (CloudBase console / export for reviewers)

## Pre-launch gates

| # | Item | Owner | Status |
|---|------|-------|--------|
| 1 | ICP 备案号在 About 页展示 | Legal / PM | 🔄 工程：`SPARK_ICP_RECORD_NUMBER` xcconfig → Info.plist |
| 2 | 隐私政策枚举 UGC 收集目的与保留期（≥6 个月审计日志） | Legal | ☐ 见 `docs/legal/PRIVACY_UGC_ADDENDUM.md` 模板 |
| 3 | 用户协议：禁止违法、骚扰、色情、引流诈骗内容 | Legal | ☐ |
| 4 | 举报入口可达（帖子详情 → 举报） | Product | ☑ `CommunityPostDetailView` 工具栏 |
| 5 | 审核 SLA：举报 24h 内首次响应（人工） | Ops | ☐ |
| 6 | 先审后发 vs 先发后审策略书面决定 | PM + Legal | ☑ Staging: **先发后审** + 举报队列（ADR-0007） |

## Engineering (P4 shipped)

- Write-time text moderation: `lib/content-moderation.js` + `SparkCore.UGCModeration`
- API `422 content_rejected` on posts/replies
- iOS compose + reply surfaces `CommunityError.contentRejected`

## Staging MVP (shipped)

- Posts/replies persist via CloudBase (`spark_community_posts`)
- Reports persist to `spark_community_reports` with `status: pending`
- Text moderation at publish time (`content_rejected`); blocklist in ADR-0007
- **Not shipped:** 第三方内容安全 API、图片自动审核、管理员 UI

## Data retention

| Data | Retention | Notes |
|------|-----------|-------|
| Posts / replies | Until user delete or moderation action | TBD production policy |
| Reports | ≥ 180 days | Regulatory audit minimum |

## Out of scope (E.3 / E.4 v2)

- Image/video posts with CDN + 易盾/天御
- Automated moderation classifier
- Public appeals workflow
