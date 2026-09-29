# 贡献指南

本仓库的产品与工程文档集中在 **[Docs/](Docs/README.md)**。

## 快速开始

1. 读 [Docs/README.md](Docs/README.md) 文档地图  
2. 做功能前查 [Docs/PRD.md](Docs/PRD.md) 是否在 V1 范围  
3. 写代码遵守 [Docs/DevelopmentGuide.md](Docs/DevelopmentGuide.md)（含 **§7 MainActor / 并发 / PhotosPicker**）  
4. 上线相关改动对照 [Docs/ReleaseReadinessAudit.md](Docs/ReleaseReadinessAudit.md) **§0 落地对照**与 [ReleaseEngineeringPlan §11](Docs/ReleaseEngineeringPlan.md)  
5. 提 PR 前运行：

```bash
bash Scripts/check-imports.sh
cd Packages/CoordinateKit && swift test  # Domain + Networking
```

涉及 `Task`、`@MainActor`、`PhotosPicker` 或 `CoordinateModels` 时，另跑：

```bash
xcodebuild -project 坐标系.xcodeproj -scheme 坐标系 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build OTHER_SWIFT_FLAGS="-warn-concurrency"
```

CI 模拟器名以 `.github/workflows/ios-test.yml` 为准。

## PR 要求

见 [DevelopmentGuide.md §9](Docs/DevelopmentGuide.md#9-功能开发流程)。
