# 登录页背景视频

登录页使用 **静音循环** 装饰视频（`AVQueuePlayer` + `AVPlayerLooper`）。

## 放入片源

将文件命名为下列之一，放到本目录（或任意会打进 App Target 的 Bundle Resources）：

- `LoginBackground.mp4`（推荐；扩展名请用小写，设备 Bundle 区分大小写）
- `LoginBackground.mov`

建议：

- 竖屏、短循环（6–15 秒）
- H.264 / HEVC，体积尽量小
- 画面可丰富；可读性交给 **Regular** 玻璃控件，不要再叠整屏白雾 / 底部暗角
- **无对白音轨**（代码会强制 `isMuted = true`）

未找到片源，或用户开启 **减弱动态效果** 时，自动回退为 `systemGroupedBackground`。

目录里现有一份短循环占位 `LoginBackground.mp4`（纯色渐变，便于联调）。正式发版前请换成品牌片源并保持同名。
