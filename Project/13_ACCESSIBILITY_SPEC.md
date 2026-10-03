# 13 · 无障碍规格（Accessibility / Dynamic Type）

---

## 1. 最低要求

| 项 | 要求 |
|----|------|
| Dynamic Type | 系统 Text Style；大字号下货架可 stacked |
| VoiceOver | 图标按钮有 label；装饰图 `accessibilityHidden` |
| 触控 | 系统控件默认命中区；自定义控件对齐 HIG 最小触控 |
| Reduce Motion | `PlatformMotion` / `platformAnimation`；业务少直调 `withAnimation` |
| Reduce Transparency | Material helper 退化不透明系统底 |

---

## 2. 活动域检查点

- [ ] 发现卡标题 / 费用 / 席位可组合朗读  
- [ ] Zoom 源与详情有合理 label/hint  
- [ ] 决策卡主 CTA hint 说明后果（支付 / 候补）  
- [ ] 成功插图 `accessibilityHidden`，文案承担信息  
- [ ] 筛选 Menu 有 value 与 hint（`ActivityFilterCopy`）  

---

## 2.1 Tab 根无障碍

| 项 | 要求 |
|----|------|
| 筛选 Badge | 与 Menu 的 accessibilityValue 一致概括生效条件 |
| 通讯录 Badge | 好友请求数可读；按钮有 hint |
| Tab Badge | 消息未读 / 搭子待办预约由系统 Tab 朗读 |

---

## 3. 登录 / 门闸

- [ ] 协议链接可聚焦  
- [ ] 错误信息不止靠颜色  
- [ ] 兴趣选择状态可感知  

---

## 4. 禁止

- 固定 pt 字号  
- 仅靠颜色传达错误  
- 无 label 的纯 SF Symbol 按钮（顶栏/消息高频区）  
- 动画无法关闭且干扰阅读  

---

## 5. 验证

人工：系统更大字体、VoiceOver 走通「登录 → 兴趣 → 发现 → 参加确认」。  
自动化：优先 Domains 规则测试；UI a11y 以抽检清单为准（本仓未强制 XCUITest 全覆盖）。

---

## 6. Sheet / 焦点 / 模态

| 项 | 要求 |
|----|------|
| Sheet 打开 | 焦点落到标题或首个有效控件；勿困在背后列表 |
| 成功 / 确认 Sheet | 主 CTA 可被 VO 优先到达；插图隐藏 |
| Dialog | 双按钮角色清晰（取消 / 破坏性） |
| Zoom | 过渡后详情有可聚焦的标题与主 CTA |

---

## 7. 审计节奏

| 时机 | 做什么 |
|------|--------|
| 每版软启动前 | 跑 §2–§3 清单 + 大字号抽检 |
| 大改发现 / 详情 / 登录 | 同上 + Reduce Motion / Transparency |
| 提审 | 记入 `16` 人工项；缺口不装已通过 |

文案与 VO 用词同源：见 `20`。

---

*下一篇：[14_SECURITY_PRIVACY.md](14_SECURITY_PRIVACY.md)*
