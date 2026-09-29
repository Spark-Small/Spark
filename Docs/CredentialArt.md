# 坐标系 · CredentialArt（行程凭证彩绘）

> **版本**：2026-09-02  
> **读者**：iOS 工程师、设计、AI Agent  
> **配套**：[DevelopmentGuide.md §6.4](DevelopmentGuide.md#64-活动行程凭证app-内主路径)、[DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) §6.1

---

## 1. 定位

CredentialArt 为 **App 内活动行程凭证** 的头图彩绘系统，与 **PassKit / 系统 Wallet** 解耦：

| 层 | 职责 |
|----|------|
| **App 内票面** | `ActivityJourneyCredentialFace` + `TintedCredentialArtHero`（主路径） |
| **纪念分享卡** | `ActivityJourneyMementoShareCard`（9:16，无条码） |
| **Wallet 导出** | `PassPackageBuilder` 生成 strip PNG；字段对齐 `ActivityPassFieldBuilder` |

用户主路径是「我的」夹 → Zoom 展开行程页 → **分享纪念票**；**加入 Apple Wallet** 在「更多」菜单，非主 CTA。

---

## 2. 场景与资源映射

| 场景 `CredentialArtScene` | 活动分类 | Bundle SVG | Assets 回退 |
|---------------------------|----------|------------|-------------|
| `transit` | 户外 / 城市探索 | `Resources/CredentialArt/transit.svg` | `CredentialArtTransit` |
| `event` | 娱乐 / 兴趣社交 | `event.svg` | `CredentialArtEvent` |
| `dining` | 美食 | `dining.svg` | `CredentialArtDining` |
| `workshop` | 手工 / 学习 | `workshop.svg` | `CredentialArtWorkshop` |
| `generic` | 默认 | `generic.svg` | `CredentialArtGeneric` |
| `memento` | 纪念模式专用 | `memento.svg` | `CredentialArtMemento` |

映射逻辑：`Features/Profile/Credential/CredentialArtCatalog.swift`（Features 层，可读 `CoordinateModels`）。

主题色：`Design/CredentialArt/CredentialArtTheme.swift`（**Design 白名单**，可 `import CoordinateModels`）。

---

## 3. SVG 模板约定

模板放在 `坐标系/Resources/CredentialArt/*.svg`，运行时由 `CredentialArtSVGLoader` 读取并替换占位符：

| 占位符 | 含义 |
|--------|------|
| `ACCENT_PRIMARY` | 主强调色（品牌 accent 或场景色） |
| `ACCENT_MUTED` | 次要 / 背景点缀色 |

**要求**：

- 使用 `fill="ACCENT_PRIMARY"` 等形式，**不要**写死 `#` 色值（便于运行时着色）。
- `Assets.xcassets/CredentialArt/*.imageset` 为 **SVGView 加载失败时的静态回退**；更新 Bundle 模板后，必要时同步 imageset（hex 须带 `#`）。

---

## 4. 运行时渲染

```
CredentialArtCatalog.scene(for:)
  → CredentialArtTheme（primary / muted Color）
  → BundledCredentialArt.load(named:)  // Bundle SVG 文本
  → CredentialArtSVGLoader.tintedSVG(...)  // 替换 ACCENT_*
  → TintedCredentialArtHero（SVGView）
  → 失败时 Image("CredentialArtTransit") 等 Assets 回退
```

**SPM 依赖**：`SVGView`（exyte）在 `坐标系.xcodeproj` 中手动 link；新增第三方包时同步改 `project.pbxproj`。

---

## 5. 与 PassKit 字段的关系

票面 **文案字段**（时间 / 活动名 / 地点 / 座位等）单源：`Services/PassKit/ActivityPassFieldBuilder.swift` → `pass.json` 与 `PassFaceModel`。

**彩绘** 与 App 内 UI 同源：`CredentialArtStripRenderer` 将 `CredentialArtScene` + 主题色渲染为 Wallet strip PNG（`PassPackageBuilder.writeTemplateAssets`），覆盖 `@1x/@2x/@3x`。头图与票面衔接见 `CredentialArtHeroChrome`（渐变高光 + 字段分隔线）。字段仍单源 `ActivityPassFieldBuilder`。

---

## 6. 许可与风格

插画风格参考 [unDraw](https://undraw.co/) 的扁平矢量语汇；当前仓库内 SVG 为项目自制模板，**非** unDraw 原文件直接打包。若后续引入第三方素材，须在本节补充署名与许可链接。

---

## 7. 维护检查表

- [ ] 新活动分类 → 更新 `CredentialArtCatalog` + 必要时新 SVG 场景
- [ ] 改占位符名 → 同步 `CredentialArtSVGLoader` + 全部模板
- [ ] 改票面布局 → `ActivityJourneyCredentialFace`，**不要**复活已删的 `WalletPassEventTicketFace`
- [ ] 改 PassKit 字段槽位 → `ActivityPassFieldBuilder` + `PassFacePresentation`
- [ ] 更新 [Archive.md](Archive.md) 若删除旧组件

---

*彩绘规范变更时同步 [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) §6.1 与 [DevelopmentGuide.md](DevelopmentGuide.md) §6.4。*
