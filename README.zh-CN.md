# wmux

<p align="center">
  <b>个人专属的高性能 macOS 现代化平铺终端与 AI 协作工作台</b>
</p>

<p align="center">
  由 <b>GhosttyKit (Metal GPU)</b> 驱动 · <b>Bonsplit 自由分屏</b> · <b>零遥测零隐私外泄</b> · <b>极速 CI 构建</b>
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

---

## 项目简介

**wmux** 是基于 cmux 针对个人日常开发深度定制、重构精简的 macOS 原生桌面终端应用。

本应用专为追求极致性能、专注体验与本地 AI 协作的开发者打造，彻底剥离了商业云服务中继、多平台（iOS/Web）冗余包、Sentry/PostHog 遥测与后台进程快照轮询，仅保留最纯粹、稳定且丝滑的原生桌面体验。

---

## 核心特性

### ⚡ 亚毫秒级 Metal GPU 原生渲染
基于 `GhosttyKit` 的 Metal 硬件加速渲染管线，带来极致的输入低延迟、真彩色支持、主流终端图像协议（Sixel / Kitty）以及大容量无卡顿回滚缓冲区。

### 🔲 Bonsplit 自由网格分屏
支持水平、垂直任意方向的快捷切分（`Cmd+D` / `Cmd+Shift+D`）。分屏视窗支持自由拖拽微调、交换位置、独立拆出与快速聚焦导航。

### 📑 垂直工作区侧边栏
告别顶部杂乱的标签页横向堆叠。左侧专属侧边栏提供清晰的工作区树，支持多项目瞬时切换、拖拽重排与折叠收起。

### 🌐 内置 WebKit 浏览器面板
无需离开终端频繁切换浏览器，即可在终端旁快速分屏开辟本地网页视窗，无缝调试本地 Web 服务、接口或查阅开发文档。

### 📝 本地 Markdown 实时预览
内置优雅的 Markdown 渲染面板，实时呈现开发规范、技术文档以及 Coding Agent 生成的计划与执行记录。

### 🔌 UNIX Socket 命令行深度编排
提供完善的原生 CLI（`cmux` 命令），可通过脚本从外部终端精确控制窗口、工作区、面板切分以及键盘按键自动化注入。

### 🔒 纯本地离线自洽，零隐私外泄
完全解绑远程云服务器与多租户体系，彻底移除 PostHog 埋点与 Sentry 异常上报，停用每 5 分钟扫描全系统进程快照的后台定时任务，实现绝对的本地纯粹与隐私安全。

### 🚀 GitHub Actions 极速 DMG 缓存构建
工作流采用 `XCBUILD_FILE_SYSTEM_MODE=checksum-only` 增量内容哈希校验，配备 DerivedData、SPM、Cargo 及 GhosttyKit 5 级缓存，使完整 Release DMG 构建速度从 30+ 分钟缩短至 **~3.5 分钟**。

---

## 快速上手

### 系统要求
- macOS 14.0 (Sonoma) 或 macOS 15.0+ (Sequoia)
- Apple Silicon (arm64)
- Xcode 16.0+

### 本地编译与运行

1. **克隆仓库：**
   ```bash
   git clone https://github.com/your-username/wmux.git
   cd wmux
   ```

2. **环境自检与依赖初始化：**
   ```bash
   ./scripts/setup.sh
   ```

3. **编译并启动本地 DEV 实例：**
   ```bash
   ./scripts/reload.sh
   ```

### 自动打包 DMG

通过推送语义化版本标签（例如 `v1.0.0`），或在 GitHub **Actions** 页面手动触发 `Build macOS DMG` 工作流，流水线将在约 3.5 分钟内自动完成编译、Ad-hoc 签名并打包发布 `wmux-macos-arm64.dmg`。

---

## 开源许可

本项目由 cmux 演化定制而来，遵循项目既有开源许可协议。
