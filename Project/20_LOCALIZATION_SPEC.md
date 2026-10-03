# 20 · 本地化与文案治理（Localization / Copy）

> 现行产品文案以**简体中文**为主路径。本文件定文案所有权与演进到 String Catalog 的纪律，避免「同一意思三处硬编码」。

---

## 1. 现行约定（诚实）

| 项 | 状态 |
|----|------|
| 默认语言 | 简体中文（zh-Hans 产品口径） |
| 用户可见主路径文案 | Feature 内 `*Copy` 枚举 / `ActivityCardStatus` 等 |
| String Catalog（`.xcstrings`） | **目标态**；未全面迁完前禁止旁路再散落字面量 |
| 多语言上架 | 非 V1 阻塞；若开第二语言必须先 Catalog + 伪本地化抽检 |

---

## 2. 文案所有权

| 域 | 单一词表入口 | 说明 |
|----|--------------|------|
| 发现 / 详情主 CTA | `ActivityCardStatus` | 「免费」等动作词只此一处 |
| 详情长文案 | `ActivityDetailCopy` | 段落、主办管理短句 |
| 发起 | `ActivityComposeCopy` | 可与 CardStatus 别名共用「免费」 |
| 浏览 / 筛选 | `ActivityBrowseCopy` / `ActivityFilterCopy` | Menu value/hint |
| 反馈 | `ActivityFeedbackCopy` | |
| 社区 | `CommunityCopy` | |
| 登录 / 门闸 | Launch / Auth 侧 Copy 或既有常量 | 协议、错误可读 |
| 支付披露 | `CommercePaymentPolicy` 相关文案 | Release 必须诚实 |

**规则**：用户可见字符串不进 Domain UseCase（Domain 用错误枚举；Feature 映射文案）。

---

## 3. 写法纪律

1. 禁止在 View 里为**主 CTA / 空态标题 / 错误主句**新写字面量；先入对应 `*Copy`。  
2. 插值用格式化 API，保留语序可本地化（将来 `%@` / String Catalog）。  
3. 无障碍 label / hint 与可见文案同源或显式配对（见 `13`）。  
4. 渠道品牌名（微信、Apple）用官方称谓，不戏仿系统按钮文案。

---

## 4. 迁 String Catalog 时（何时做）

满足任一则启动迁移批次：

- 准备第二语言或 App Store 多本地化截图  
- 文案评审需要非工程角色直接改字符串  
- `*Copy` 枚举已过大难以检索  

迁移后：`*Copy` 可薄封装 `String(localized:)`；**真相源**改为 Catalog；本表更新所有权列。

---

## 5. 日期 / 数字 / 单位

- 日期时间：系统 `FormatStyle` / 本地化日历；存储用稳定 ISO 或 `Date`（API 见 `09`）。  
- 货币：展示与账本分离；Release 钱包披露「设备本地账本」。  
- 勿手写「昨天/周几」散落逻辑多份；集中 helper。

---

*下一篇：[21_ENGINEERING_WORKFLOW.md](21_ENGINEERING_WORKFLOW.md)*
