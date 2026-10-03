# 15 · 测试标准（Test Spec）

---

## 1. 测试金字塔（本仓）

| 层 | 位置 | 测什么 |
|----|------|--------|
| Domain | `Packages/CoordinateKit/Tests/CoordinateDomainTests` | UseCase 纯逻辑（参加、主办、合并目录、预约状态机） |
| Networking | `CoordinateNetworkingTests` | Endpoint / 编解码约定 |
| App | `坐标系Tests` | 会话状态机、兴趣限制、持久化门面等 |

UI 全量 XCUITest **未**作为门禁；关键路径靠人工 + Domain 覆盖。

---

## 2. 必测域（改到就要跑）

| 变更 | 命令 / 套件 |
|------|-------------|
| Domain Activities / Buddies / Community Merge | `swift test --filter MergeRemote`（在 `Packages/CoordinateKit`） |
| Auth 会话 | `AuthSessionStateMachineTests` |
| 兴趣下限 | `InterestSelectionLimitsTests` |
| Import 边界 | `bash Scripts/check-imports.sh` |

涉及并发 / PhotosPicker：

```bash
xcodebuild -project 坐标系.xcodeproj -scheme 坐标系 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build OTHER_SWIFT_FLAGS="-warn-concurrency"
```

**日常改完不主动 xcodebuild**（仓库规则）；明确要求编译时再跑。

---

## 3. Domain 用例最低覆盖

- Join：成功 / 满员 / 已结束  
- Hosting：发布写入 hostUserID；取消校验 host  
- MergeRemote（Activities / Buddies / **Community**）：保留本机独有；engagement 并集；禁止空远程清空  
- Repair：不把 seed joinedIDs 并回用户取消态  
- Community Engagement：赞幂等；转发 mark/unrepost  

---

## 4. 软启动手工矩阵

见历史模块文档摘要：

**Auth**：演示码 / 远程短信 / Apple 撤销 / 协议 Gate / 兴趣硬门 / 失效登出。  
**Activities**：未登录无 Tab；发现；免费参加；Release 仅钱包；发起；主办改期；DEBUG 开远程目录合并。  
**Community（广场）**手工清单（详见 [CommunityModule](../Docs/CommunityModule.md)）：

| # | 路径 | 期望 |
|---|------|------|
| C1 | Tab 打开广场 | 顶栏发分享 + 搜索按钮；无常驻搜索框；无「更多」 |
| C2 | 五档筛选 | 全部→关注→发现作者→热议→与我相关；语义互斥；hint + 空态诚实 |
| C3 | 关注空态 | CTA「发现作者」切到发现筛选 |
| C4 | 搜索按钮 | 展开 `searchable`；取消由系统收起（不自清 text 以免死循环）；提交写入最近词（≤5） |
| C5 | 发分享 | 关联活动仅参加/主办/收藏；成功 `platformFeedback` |
| C6 | 赞 / 取消赞 | 赞 →「我的·通知」出现；取消赞 → **同 dedupeKey 通知撤销**；广场无预览；再赞可再通知 |
| C7 | 评 / 回复 | 通知文案与深链正确；出现在「我的·通知」 |
| C8 | 内容库 | 入口在「我的」；收藏/赞过/我的分享可达 |
| C9 | 动态区 | 推荐置顶≤1；无问卷卡；长按「少看」隐藏推荐；**无**广场通知预览轨；**无**推荐关注人轨 |
| C10 | 远程读（DEBUG Flag） | Merge 保留本机独有帖；engagement 并集；禁止空远程清空 |
| C11 | 通知关闭条 | denied/notDetermined 可见；授权成功后隐藏 |
| C12 | 发现作者关注 | 帖卡点关注 → 作者进「关注」档；该作者帖离开「发现作者」（诚实筛选，无会话假留） |
| C13 | 拉黑作者 | Feed / 推荐同步消失；社区通知在「我的·通知」按拉黑过滤 |
| C14 | 评论楼中楼 | 详情/评论 Sheet：展开收起回复；回复挂主楼并显示「回复 @」；发回复后线程保持展开；≤2 条默认展开 |
| C15 | VoiceOver 抽检 | 筛选选中态、赞/评/藏、关注、通知条、媒体页序号可读 |
| C16 | Dynamic Type | 筛选 chip 可横滑不截断；Feed 正文行数随字号 |

自动化：`swift test --filter Community`（BrowseFiltering / Engagement / MergeRemoteCommunity）。


---

## 5. PR 测试声明

PR 描述写清：

- 跑过哪些自动化  
- 未跑编译时写「按代码推断」  
- 若动导航 / 新文件：请人工编译  

---

## 6. 质量门与回归范围

| 变更类型 | 最低验证 |
|----------|----------|
| Domain UC | 对应 `swift test --filter` |
| Auth 门闸 | `AuthSessionStateMachineTests` + 手工登录一条 |
| 导航 / Zoom / Sheet 栈 | 人工：入口 → 返回 → Sheet 内 Push |
| Flag / 支付政策 | Release 配置心智走查（`16` C） |
| Copy / a11y | 大字号或 VO 抽一句主 CTA |

工程流程与评审清单见 [21](21_ENGINEERING_WORKFLOW.md)。

---

*下一篇：[16_RELEASE_CHECKLIST.md](16_RELEASE_CHECKLIST.md)*
