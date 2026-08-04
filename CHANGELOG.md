# Changelog

## 0.1.0 - 2026-08-04

这是 chopsticks 作为纯 Vim 单文件配置重新出发的首个版本。

### Added

- 基于 fzf、Fugitive、ALE、vim-lsp 和原生 Vim UI 的现代开发工作流。
- 面向 Markdown 的 Pencil、任务列表、表格、TOC、浏览器与终端预览、专注模式。
- 通过 `pngpaste` 将剪贴板图片安全保存到文档资源目录。
- 通过 `im-select` 在普通模式和插入模式之间自动切换 macOS 输入法。
- craftzdog 风格的快速查找和窗口层，以及按语义分组的 Leader 键位体系。
- Space/逗号上下文按键提示和可搜索的 `:ChopsticksCheatsheet` 完整速查表。
- `:ChopsticksHealth` 和 Markdown 就地帮助。
- 在隔离环境中安装固定版本插件并验证 Vim 启动和 Markdown 能力的 CI。

### Changed

- 配置目标明确为 Vim 8.2/9.x，不支持 Neovim。
- 插件固定到已验证的提交，启动过程不再隐式下载软件。
- 版本序列重置为 0.1.0，作为新架构的发布基线。

### Removed

- 旧的模块加载框架、配置 profile、安装器、演示工程和大规模历史测试脚本。
- 与当前单文件工作流重复或已经失效的文档。
