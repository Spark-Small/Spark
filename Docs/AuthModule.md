# 坐标系 · 登录 / 认证模块（附录）

> **裁决**：现行规范与验收以 [`Project/`](../Project/README.md) 为准（流程 `02`、架构 `07`、API `09`、上线 `16`、屏契约 `17`）。  
> **本文角色**：Auth 代码地图与联调细节的**深读附录**；与 Project 冲突时改 Project（或改代码后回写 Project），**不要**把本文当单一事实源。  
> **同步**：2026-10-05（按代码推断；Identity / ParticipantIdentity 收口）  
> 软启动 / 阻塞短桩：[SoftLaunchConventions.md](SoftLaunchConventions.md) · [ReleaseBlockers.md](ReleaseBlockers.md)

---

## 1. 用户路径（必须按此顺序）

`ContentView` 是唯一会话门闸，**未登录看不到任何 Tab（含活动）**。

```
冷启动
  ├─ 已登录 && 协议版本需重签 → LegalConsentGate
  ├─ 未登录 → LoginView
  ├─ 已登录 && AppModel 未就绪 → 启动屏底色 + BrandLogo（延后构造模型）
  └─ 已登录 && 模型就绪
        ├─ !hasCompletedInterestSelection → InterestOnboardingView（硬门槛，无跳过）
        └─ else → TabView（默认活动）
              └─ 未看过欢迎意图 → 强制选中活动 Tab；半屏 Sheet（可跳过）
```

| 阶段 | 文件 | 说明 |
|------|------|------|
| 会话门闸 | `坐标系/ContentView.swift` | `LocalAuthSession` + 延后 `AppModel` |
| 协议升级 | `LegalConsentGate` | 已登录用户遇协议版本 bump 时挡在登录后、主界面前 |
| 登录 UI | `Features/Launch/Views/LoginView.swift` | 短信 / Apple / 微信 |
| 登录 chrome | `LoginChrome.swift`、视频底见 `Resources/Videos/README.md` | 品牌底与社交按钮 |
| 串行登录 | `LoginAuthWorkGate.swift` | 防并发登录请求 |
| 兴趣 | `InterestOnboardingView.swift` | ≥ 标签下限；完成后写 `AppModel` |
| 欢迎意图 | `AppWelcomeGuideView` + `WelcomeGuideStore` | **不等于**兴趣；可跳过 |

兴趣编辑入口（非门闸）：我的 → 编辑资料 → `InterestTaxonomyFormEditor`。

---

## 2. 代码地图

```
Services/Auth/
  AuthSessionStore.swift          Keychain 会话快照
  AuthCredentialFormat.swift      手机号校验
  AuthSessionEvents.swift         远程会话失效通知
  AppleSignInService.swift
  WeChatSignInService.swift       SDK 未配置时 Release 隐藏入口
  UseCases/
    AuthUseCaseTypes.swift        AuthSignInResult / SendCodeResult
    AuthSMSUseCases.swift         远程发送码 + 登录；演示码登录
    AuthOAuthUseCases.swift       Apple / 微信
    AuthSessionLifecycleUseCases.swift  reconcile / invalidate

Services/API/
  AuthTokenStore.swift            JWT + refresh
  APIEndpoint+Auth.swift          sms/send|login · apple · wechat · refresh

Services/LocalAuthSession.swift   @Observable 门面，组合上述 UseCase
Services/LocalUserIdentity.swift  本机用户 UUID；远程登录可 adopt 服务端 id
Services/Analytics/AuthAnalytics.swift
```

Feature UI 只调 `LocalAuthSession` / `LoginView` 状态，**不直接写 Keychain / Token**。

---

## 3. 会话与 Token

| 层 | 职责 |
|----|------|
| `LocalAuthSession` | UI 可见：`isSignedIn` / `provider` / 手机号掩码 |
| `AuthSessionStore`（Keychain） | 持久快照；旧 `guest` 解码规范为未登录 |
| `AuthTokenStore` | access / refresh；401 触发 refresh；失败发 `AuthSessionEvents.remoteSessionInvalidated` |
| `ReconcileAuthSessionUseCase` | Release + `useRemoteAuth`：无 token 则登出 |
| Apple 凭证 | 冷启动 `refreshCredentialStateIfNeeded`；已撤销 → `signOut` |

远程登录成功后：`RemoteAuthAPI.applyLoginData` → 写入 token +（如有）`LocalUserIdentity.adopt(serverUUID)`。

---

## 4. Feature Flags

| Flag | DEBUG | Release | 含义 |
|------|-------|---------|------|
| `useRemoteAuth` | UserDefaults 可关（默认可关演示） | **恒 true** | 远程短信 JWT；关则演示码 `123456` |
| 微信入口 | SDK 未配置可 DEBUG 演示 | SDK 未配置则**不展示** | `WeChatSignInService.isSDKConfigured` |

演示码常量：`LocalAuthSession.demoCode`（仅 `!useRemoteAuth`）。

DEBUG 联调读路径：`FeatureFlags.enableReadPathRemoteIntegration()`（开远程 Auth + Catalog 等；**不创造活动写 API**）。

---

## 5. 登录方式契约

| 方式 | UseCase | 成功条件 |
|------|---------|----------|
| 短信（远程） | `SendRemoteSMSCodeUseCase` → `SignInWithRemoteSMSUseCase` | `POST auth/sms/*` + JWT |
| 短信（演示） | `SignInWithDemoSMSUseCase` | 码匹配；**不 mint JWT** |
| Apple | `SignInWithAppleUseCase` | 系统按钮 + 后端换票（服务端校验仍为上线依赖） |
| 微信 | `SignInWithWeChatUseCase` | SDK + `auth/wechat/login` |

埋点：`AuthAnalytics`（发送 / 成功 / 失败 / 取消）。

---

## 6. 与下游模块的边界（重要）

登录门闸**正确**。客户端参与身份已收口到稳定 UUID，**服务端履约贯通仍未完成**：

| 下游 | 现状 |
|------|------|
| 参与身份读口 | `ParticipantIdentity.currentUserID`（=`LocalUserIdentity`；远程登录可 `adopt`） |
| 活动报名 / 候补 / 主办 | Domain UC 写入 `participantUserIDs` / `hostUserID`；展示层仍可见昵称 |
| 搭子邀约 / 预约 | `inviteeUserID` / `companionUserID` + `BuddyIdentityMatching`（经 `ParticipantIdentity.matches`） |
| 身份能力门禁 | `IdentityCapability` / `AppModel.requireIdentityAccess`；`_ = auth`（不替登录态） |
| 活动目录 / 支付 | 见 [ActivitiesModule.md](ActivitiesModule.md) |

软启动可测「登录 → 兴趣 → 进活动 Tab」；不可把「本地报名成功」当成服务端履约。勾 `16` B 需后端真人目录 / 远程写就绪。

---

## 7. 改动规范

1. **门闸顺序不得跳级**（协议 → 登录 → 模型 → 兴趣 → Tab）。
2. 新登录渠道：先加 UseCase + APIEndpoint，再接线 `LocalAuthSession`，最后才改 `LoginView`。
3. 禁止在 Feature 内直接 `UserDefaults` 伪造已登录。
4. Release 禁止恢复演示码默认路径（`useRemoteAuth` 恒 true）。
5. 文案 / 分析事件变更同步本文件 §5 与 PRD 登录 FR。
6. UI：系统控件优先；登录品牌底 / 微信绿属刻意 chrome，勿扩散到活动 Form。

---

## 8. 软启动测试矩阵

| # | 场景 | 期望 |
|---|------|------|
| A1 | DEBUG + 关远程 Auth，码 `123456` | 进兴趣 / Tab；无 JWT |
| A2 | DEBUG/Release + 开远程，真短信 | JWT 入库；杀进程仍登录 |
| A3 | Apple 登录 | 成功进门；系统撤销凭证后下次冷启动登出 |
| A4 | 协议版本 bump | 已登录用户先见 `LegalConsentGate` |
| A5 | 兴趣未完成 | 无法进 Tab；完成 ≥ 下限后进活动 |
| A6 | `remoteSessionInvalidated` | 清会话，回 `LoginView`，拆掉 `AppModel` |
| A7 | 微信 SDK 未配置（Release） | 无微信按钮 |

自动化参考：`坐标系Tests/AuthSessionStateMachineTests.swift`、`InterestSelectionLimitsTests.swift`。
