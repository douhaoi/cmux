# LocalDeck

基于 [manaflow-ai/cmux](https://github.com/manaflow-ai/cmux) 的本地 macOS
终端与浏览器工作区，用于运行编码代理。

[English](README.md)

## 保留能力

- Ghostty 终端渲染、标签、分屏与工作区恢复。
- 内置浏览器、文件预览和 diff 查看器。
- 代理通知、hooks、随应用提供的 CLI 与本地 socket 自动化。
- 现有本地配置与 SSH 功能。

此发行版不提供账号、托管云机器、移动端配对、VPN 服务、遥测或自动更新。
尚未解除依赖的原生云端代码仍保留在源码中，由产品策略禁用。

## 获取构建产物

原生构建和打包通过 GitHub Actions 执行。在仓库中打开 **Actions → Package
LocalDeck → Run workflow**，选择分支；两个架构任务通过后下载对应 artifact。
入口为 [localdeck-package.yml](.github/workflows/localdeck-package.yml)。

每个架构提供 ZIP、DMG、SHA-256 校验值与构建信息。产物采用 ad hoc 签名，
不包含 Apple 公证，属于开发构建；不使用上游 Release、Homebrew 或更新源。
按机器架构安装，后续手动更新。

## 配置

应用标识为 `com.cmuxterm.local`，用户配置位于
`~/.config/cmux-local/cmux.json`，状态位于 `~/.local/state/cmux-local`。
随应用提供的 CLI 保留 `cmux` 命令名，以兼容已有本地集成。

可参考[外观配置](docs/customizing-appearance.md)、
[shell 集成](docs/shell-integration.md)与
[贡献验证说明](docs/contributor-verification.md)。

## 开发与许可

源码检查及 GitHub 打包方法见 [CONTRIBUTING.md](CONTRIBUTING.md)。
本轮清理不要求在本地执行原生构建。

保留 cmux 的来源说明、许可证及第三方声明；具体范围见 [LICENSE](LICENSE)。
保留的 relay 组件遵循其自身条款，此 fork 不重新授权这些组件。
