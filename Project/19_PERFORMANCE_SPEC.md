# 19 · 性能预算（Performance Spec）

> 旗舰感很大一部分是「首屏不卡、列表不抖、进详情不喘」。本文件定**可度量预算**与禁止项；未接自动化基准前以真机体感 + Instruments 抽检为准。

---

## 1. 启动与门闸

| 指标 | 预算（目标） | 做法 |
|------|--------------|------|
| 冷启动到登录可交互 | 尽快；禁止为首帧解码全量活动目录 | `ContentView` 延后构造 `AppModel`（见 `07`） |
| 已登录到 Tab 可交互 | 兴趣未完成可先兴趣屏；主模型就绪前用启动占位 | 勿假进度条掩盖长同步 |
| 首屏主网络 | 登录可不挡；活动目录远程静默 | 失败保留本地（`09` / `10`） |

---

## 2. 发现货架与滚动

| 项 | 要求 |
|----|------|
| 列表 | 长列表用 Lazy；避免在 `body` 做重计算无缓存 |
| 图片 | 异步解码 / 降采样；封面失败有占位，不反复同步读盘 |
| 动画 | 经 `PlatformMotion` / `platformAnimation`；Reduce Motion 可关 |
| 筛选 | 即时过滤应 O(n) 可接受于本机目录规模；过大则分页/索引（接入远程后见 `09` 分页） |

---

## 3. 详情与媒体

- Zoom 过渡：系统 matched transition；源视图保持轻量。  
- Hero / 多图：按需加载；勿一次解码全部原图进内存。  
- Form 详情：首屏服务决策；长文下沉减少首屏布局抖动。

---

## 4. 持久化与主线程

| 项 | 要求 |
|----|------|
| UI | MainActor（`06`） |
| 写盘 | `MainActorPersistence.chained`；失败可见，不 silent |
| 后台 | `scenePhase == .background` flush；避免在滚动临界路径同步大 snapshot 编码 |

---

## 5. 内存与包体（抽检）

- 大图 / 视频进 `LocalMediaLibrary` 生命周期，离开屏可释放。  
- 禁止在 DEBUG 演示路径向 Release 打进大样例包作为默认供给。  
- 提审前关注 App 体积与 On-Demand 资源策略（若引入）。

---

## 6. 验证方式

| 场景 | 工具 |
|------|------|
| 启动 / 挂起 | Instruments Time Profiler / App Launch |
| 滚动掉帧 | SwiftUI / Core Animation 抽检 |
| 内存峰值 | Allocations / 真机进详情来回 |

日常改完不强制跑 Instruments；动启动路径、目录加载、货架结构时建议抽检，结论写入 PR。

---

*下一篇：[20_LOCALIZATION_SPEC.md](20_LOCALIZATION_SPEC.md)*
