# wmux

<p align="center">
  <b>A Lightweight, High-Performance macOS Terminal & AI Agent Workspace</b>
</p>

<p align="center">
  Powered by <b>GhosttyKit (Metal GPU)</b> · <b>Bonsplit Tiling</b> · <b>Zero Telemetry</b> · <b>Ultra-fast CI</b>
</p>

<p align="center">
  English | <a href="README.zh-CN.md">简体中文</a>
</p>

---

## Overview

**wmux** is a personal, streamlined macOS terminal application tailored for local software development and AI coding workflows. Forked from cmux and deeply optimized for personal use, it strips away all commercial cloud infrastructure, telemetry backends, and unnecessary multi-platform bloat, leaving a pure, lightning-fast, and distraction-free native macOS terminal experience.

---

## Highlights & Features

### ⚡ Sub-millisecond Native Rendering
Built on Apple Metal GPU acceleration via `GhosttyKit`, delivering native sub-millisecond typing latency, true color support, sixel/kitty graphics protocols, and smooth scrollback buffers.

### 🔲 Bonsplit Arbitrary Panes & Tiling
Split your terminal horizontally or vertically with ease (`Cmd+D` / `Cmd+Shift+D`). Freely resize, swap, break off, and rearrange panes with fluid gestures and deterministic shortcuts.

### 📑 Clean Vertical Workspace Sidebar
Say goodbye to cluttered top-bar tab overload. Manage multi-project workspaces cleanly on a collapsible left sidebar, with instant switching and drag-and-drop reordering.

### 🌐 Built-in WebKit Browser Surface
Open web applications, documentation, or local debug servers directly beside your terminal in a native WebKit pane without switching between external desktop apps.

### 📝 Integrated Markdown Viewer
Render plans, architectural specifications, and agent output logs with rich headings, syntax-highlighted code blocks, tables, and live reloading.

### 🔌 Powerful Local CLI & UNIX Socket Automation
Control windows, workspaces, surfaces, and key inputs directly from scripts and external tools using the native UNIX domain socket CLI.

### 🔒 100% Local & Zero Telemetry
Completely decoupled from remote cloud servers. All analytics (PostHog), crash reporting (Sentry), background process polling, and cloud accounts are permanently disabled. Zero network noise, 100% privacy.

### 🚀 Ultra-fast GitHub Actions DMG Build
Engineered with `XCBUILD_FILE_SYSTEM_MODE=checksum-only` and a multi-tiered persistent cache (DerivedData, SPM, Cargo, GhosttyKit). Full Release DMG builds complete in **~3.5 minutes**.

---

## Getting Started

### System Requirements
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Apple Silicon (arm64)
- Xcode 16.0+

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/wmux.git
   cd wmux
   ```

2. **Run setup:**
   ```bash
   ./scripts/setup.sh
   ```

3. **Build & launch the local tagged DEV app:**
   ```bash
   ./scripts/reload.sh
   ```

### Building DMG via GitHub Actions

Push a version tag (e.g., `v1.0.0`) or trigger the workflow manually from the **Actions** tab (`Build macOS DMG`). The cached pipeline will compile and package `wmux-macos-arm64.dmg` in approximately 3 to 4 minutes.

---

## License

Derived from cmux. Distributed under the project license.
