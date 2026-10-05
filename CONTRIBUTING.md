# 贡献指南

产品与**现行开发规范**在 **[Project/](Project/README.md)**（00–21）。

历史附录与归档在 [Docs/](Docs/README.md)。

## 快速开始

1. 读 [Project/00_PROJECT_CHARTER.md](Project/00_PROJECT_CHARTER.md)  
2. 按角色读 Project 对应章节（见 Project/README）  
3. 功能是否在 V1： [Project/01_PRODUCT_SPEC.md](Project/01_PRODUCT_SPEC.md)  
4. 写代码遵守 [Project/07_ARCHITECTURE.md](Project/07_ARCHITECTURE.md) 与 import CI  
5. 提审 / 软启动：[Project/16_RELEASE_CHECKLIST.md](Project/16_RELEASE_CHECKLIST.md)  
6. 提 PR 前：

```bash
bash Scripts/check-imports.sh   # 含 import 边界 + 文本输入零旁路（check-text-input）
cd Packages/CoordinateKit && swift test
```

涉及 `Task`、`@MainActor`、`PhotosPicker` 时，按 [Project/15_TEST_SPEC.md](Project/15_TEST_SPEC.md) 再跑 concurrency build。

日常改完**不要**主动 `xcodebuild`，除非明确要求编译。

## PR 要求

见 Project/15 与 Project/00「改文档纪律」。AI 会话合同见 [Project/21 §7](Project/21_ENGINEERING_WORKFLOW.md)。  
规则：`honesty-gates`、`project-docs-dod`、`one-blocker-per-session`、`instruction-scope-gate`、`agent-self-verify`、`delivery-footer`（均在 `.cursor/rules/`）。