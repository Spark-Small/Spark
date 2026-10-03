# 21 · 工程流程与可维护性（Engineering Workflow）

> 模块划得再清，没有 PR / Flag / 废弃纪律也会腐坏。本文件定**怎么改仓**，与 `07`（架构）互补。

---

## 1. 分支与提交

| 项 | 约定 |
|----|------|
| 主干 | 可软启动联调；正式提审点用 git tag（见 `16`） |
| 提交信息 | 写清 why；中英均可，与近史风格一致 |
| 秘密 | 禁止提交 Key、`.env`、真机证书口令 |

未要求时不代用户 commit / push（用户规则）。

---

## 2. PR 体量与 Definition of Done

**体量**：一个 PR 一个意图（修导航 / 加 UC / 改文案）。大重构拆 PR，避免「架构 + UI 大改」捆绑难审。

**DoD（作者勾选）：**

- [ ] 分层未破：Features 不 `import CoordinateData`、不直连 `AppComposition`（`check-imports.sh`）  
- [ ] 领域规则在 Domain UC；表现态在 PresentationStore  
- [ ] 用户可见主文案走 `*Copy`（`20`）  
- [ ] 导航目的地未在子页重复注册（`11`）  
- [ ] **文件纪律（官方示例级）**：本次改动的 Features/Design 生产 Swift **≤400 行**；编辑超标文件须同 PR 先拆（见 `07` §7、`.cursor/rules/official-sample-file-discipline`）  
- [ ] 若改路径 / Flag / API 状态：同 PR 更新 `Project/` 对应编号  
- [ ] 测试：按 `15` 声明跑过什么；未编译写「按代码推断」  
- [ ] 无新增自定义 Toast / 旁路支付成功  

---

## 3. 代码评审清单（审者）

| 维 | 看什么 |
|----|--------|
| 模块 | 是否跨模块偷调仓储 / 登录 |
| 页面职责 | 是否违反 `17` 禁止列 |
| 状态 | Snapshot vs 表现态是否混放（`10`） |
| API | 是否假装已接远程写（`09`） |
| Design | 魔法数 padding？系统控件是否够用？（`05` / `12`） |
| a11y | Dynamic Type / label（`13`） |
| 诚实门控 | Release 演示路径是否回潮（`16` C） |

---

## 4. Feature Flag 生命周期

```
提案 → 入 CoordinateFeatureFlags + 写入 06 表
 → DEBUG 可覆写
 → 远程/能力就绪后改 Release 默认
 → 删除死分支与 Flag（禁止长期「永远 false 的尸旗」）
```

| 规则 | 说明 |
|------|------|
| 命名 | `use*` / `enable*` / `require*` 语义一眼可读 |
| 文档 | Release 默认以 `06` + `16` 为准 |
| 删除 | 能力全量且稳定 ≥ 一版软启动后，开清理 PR |

`enableReadPathRemoteIntegration()`：只开读路径并关 bootstrap；**不**偷偷开活动远程写。

---

## 5. 废弃与文档

- 禁止再开平行「Wave / 七批次」进度长文；完成项进 `Docs/Archive.md`。  
- 冲突：`Project/` > 旧 `Docs/` > 聊天口述。  
- 删除公共 API：同 PR 修调用方；Domain 测试更新。  
- 大文件：**硬上限** Features/Design 生产 Swift ≤ **400** 行（`07`）；超标先拆再加功能；Agent 规则 `official-sample-file-discipline`。  
- 气质：系统容器 + Platform chrome；对齐 Apple sample 克制，禁止巨型多职文件。  

---

## 6. 日常验证节奏

- **默认**：改完不主动 `xcodebuild`（仓库规则）。  
- **静态**：linter / 明显编译风险在 PR 注明请人编译。  
- **明确要求时**：按 `15` 命令跑 Domain / App 测试或并发警告构建。

---

## 7. AI 编程会话合同

> 与 `.cursor/rules/` 下下列规则一致；改规则时同步本节：  
> `honesty-gates` · `project-docs-dod` · `one-blocker-per-session` ·  
> `instruction-scope-gate` · `agent-self-verify` · `delivery-footer` ·  
> `official-sample-file-discipline`

### 7.1 用户指令（AI 代劳收窄）

用户**不需要**每次手写范围。Agent 按 `instruction-scope-gate`：

- 判定过宽 / 歧义 → 收窄为单模块或单 B# 并说明  
- 默认：「做成旗舰」→ 一模块规范对齐；「接后端」→ 未指定则 **B2**  
- 仅 Flag / `16` B / 不可逆分叉时才短问 A/B  

### 7.2 B 表清零 vs 按规范落地

| 目标 | 门禁 |
|------|------|
| `16` B 清零 | 一会话一 B#；可证伪才准勾；外部依赖不得口头完成 |
| 按规范落地 | 诚实门控 + 同步 `Project/` + 强制交付四段 + Agent 自检 |

### 7.3 推荐节奏

```
用户一句话（可模糊）
 → AI 判定并收窄范围（写明）
 → AI 改代码 + 静态自检（check-imports / grep / linter / 文档）
 → AI 强制交付四段；仅达标勾 16B
 → 用户只处理「需你验收」列表（真机 / 后端 / 授权编译）
```

模块规范对齐与 B 清零仍拆开（一个 PR 一个意图）。

### 7.4 验收分工（减轻用户）

| 谁 | 做什么 |
|----|--------|
| Agent | 分层脚本、诚实门控自查、导航对照、linter、文档、DoD 四段 |
| 用户（备份） | 真机、后端是否真通、外部 SDK/隐私页、授权后的编译；不必再催「写范围/写四段」 |

若 Agent 未出交付块或把自检甩回用户 → 该轮不合格，下一轮先补。

---

*返回总纲：[00_PROJECT_CHARTER.md](00_PROJECT_CHARTER.md) · 上线清单：[16_RELEASE_CHECKLIST.md](16_RELEASE_CHECKLIST.md)*
