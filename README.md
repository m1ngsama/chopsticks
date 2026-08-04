# chopsticks

[![check](https://github.com/m1ngsama/chopsticks/actions/workflows/check.yml/badge.svg)](https://github.com/m1ngsama/chopsticks/actions/workflows/check.yml)

一个现代、顺手、可读的 **Vim** 配置，尤其适合代码开发和 Markdown 写作。

它借鉴了 craftzdog/LazyVim 的工作流，但实现全部使用 Vimscript 和明确支持
Vim 的插件：没有 Lua、没有 Neovim API，也不会把 `vim` 偷换成 `nvim`。

当前版本是 **0.1.0**：这是删除旧模块化框架之后，以单文件 Vim 配置重新建立的
发布基线。仓库的历史标签继续保留，方便查阅重启前的实现。

## 设计目标

- 只支持 Vim 8.2/9.x，当前主要验证环境为 Vim 9.2。
- 保持一个可完整阅读的 `.vimrc`，不引入配置框架或生成代码。
- Vim 启动时不联网；插件使用 vim-plug 管理并固定到验证过的提交。
- 原生能力优先，插件只补足搜索、Git、LSP、写作等明确缺口。
- 默认键位尊重 Vim 的操作符、动作、寄存器和跳转模型。
- 本地终端、tmux 和 SSH 都能退化得体。

## 从 Craftzdog 体验到 Vim

| 体验 | chopsticks 的 Vim 实现 |
| --- | --- |
| Telescope | fzf + fzf.vim |
| File browser | netrw + vim-vinegar |
| Lualine / Bufferline | 原生 statusline / tabline |
| LazyGit | Vim `+terminal` 中运行 lazygit |
| LSP / completion | vim-lsp + vim-lsp-settings + asyncomplete |
| Diagnostics / formatting | ALE |
| Zen Mode | Goyo + Limelight |
| Dashboard | vim-startify |
| Which-key / cheatsheet | vim-which-key + 自动生成的完整键位表 |
| Treesitter Markdown 增强 | vim-markdown + Vim 原生 syntax |

Neovim 专属的 Treesitter、Mason、Noice、Lua 插件和浮动 UI 没有被生硬移植。
chopsticks 保留的是使用体验，而不是实现细节。

## 安装

必需项：Vim 8.2+、Git、
[vim-plug](https://github.com/junegunn/vim-plug)。

```sh
git clone https://github.com/m1ngsama/chopsticks.git
ln -s "$PWD/chopsticks/.vimrc" "$HOME/.vimrc"

curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +PlugInstall +qall
```

软链接命令在 `~/.vimrc` 已存在时会安全失败；请先自行备份或选择是否替换。
配置启动时不会自动下载任何东西。

推荐工具（都不是 Vim 启动的硬依赖）：

```sh
brew install ripgrep fzf fd lazygit marksman glow pandoc pngpaste
npm install --global markdownlint-cli prettier
```

安装完成后打开 Vim：

```vim
:ChopsticksHealth
:ChopsticksCheatsheet
```

`ChopsticksHealth` 会检查 Vim 能力、命令行工具和插件目录；`SPC ?` 随时打开
完整键位表，旧命令 `:ChopsticksKeys` 仍作为别名保留。

## 日常工作流

Leader 是空格，Markdown LocalLeader 是逗号。按下 Space 或在 Markdown 中
按下逗号后稍作停顿，会出现当前层级所有可用键位；Backspace 返回上一层。

Leader 的第一层按语义分组：

```text
SPC b  buffer    SPC c  code       SPC f  file       SPC g  Git
SPC q  quit      SPC r  run        SPC s  search     SPC t  terminal
SPC u  toggle    SPC w  window     SPC x  diagnostic SPC TAB  tab
```

最高频路径不要求先进入 Leader 菜单：

```text
Ctrl-s       保存                 Ctrl-p / ;f  查找文件
;r           全项目搜索           \ / SPC SPC  切换缓冲区
H / L        上一个 / 下一个 buffer
sh/sj/sk/sl  移动窗口焦点         ss / sv      水平 / 垂直分屏
SPC j        屏幕内快速跳转       SPC ?        完整 cheatsheet
```

### 查找

```text
Ctrl-p / ;f / SPC ff   查找文件
;r / SPC sg            全项目搜索
;b / \ / SPC SPC       查找打开的 buffer
;l / SPC /             搜索当前 buffer
SPC fg / SPC fr        Git 文件 / 最近文件
SPC sw                 搜索光标下的词
SPC sB/sc/sh/sm        所有 buffer / 命令 / Vim 帮助 / 映射
```

FZF 中使用 `Ctrl-v` 垂直分屏、`Ctrl-x` 水平分屏、`Ctrl-t` 新标签页。

### 缓冲区和窗口

```text
H / L、[b / ]b        上一个 / 下一个 buffer
SPC bb / bd / bo      交替 / 删除 / 删除其它未修改 buffer
Ctrl-hjkl、sh/sj/sk/sl 在窗口间移动
ss / sv / sq / s=     分屏 / 垂直分屏 / 关闭 / 平衡窗口
Ctrl-方向键            调整窗口尺寸
SPC tt / ts           标签页终端 / 底部分屏终端
SPC TAB TAB/[ /] /d   新建 / 前后切换 / 关闭 tab page
]q / [q、SPC xq       quickfix 导航 / 开关
```

普通模式的 `Tab`/`Ctrl-i` 保持 Vim 原生 jumplist 前进语义；tab page 操作集中在
`SPC TAB` 下，避免终端无法区分 Tab 与 Ctrl-i 导致跳转历史被破坏。

### Git、诊断和 LSP

```text
SPC gs    Git 状态            SPC gd    diff
SPC gb    blame               SPC go    浏览器打开远端文件
SPC gg    lazygit

]e / [e  ALE 问题            SPC xd    问题详情
]d / [d  LSP 诊断            SPC ci    LSP 状态
gd / gr  定义 / 引用          gI / gy   实现 / 类型定义
K        hover               SPC ca    code action
SPC cr   rename              SPC cf    format
SPC uf   切换保存时格式化
```

ALE 负责 lint 和 format，vim-lsp 负责语言智能，避免两个 LSP 客户端重复诊断。
`vim-lsp-settings` 会直接使用 PATH 中已有的语言服务器；本机已有 `marksman`
时，Markdown 会自动获得链接补全、跨文件引用和诊断。

## Markdown：一等场景

打开 Markdown 时会自动进入适合长文的软换行模式：

- `wrap + linebreak + breakindent`，视觉换行不修改源文件；
- Pencil 让 `j/k/0/$` 等动作理解屏幕行；
- 默认开启英文拼写并用 `cjk` 跳过中日韩文字；
- 默认显示原始 Markdown 标记，不用 conceal 隐藏重要语法；
- 相对行号和不可见字符暂时关闭，代码块仍保留语法高亮；
- markdownlint/ALE 只在打开和保存时检查，不在每次输入时打扰；
- Marksman、Prettier、浏览器预览和终端预览按工具是否存在自然启用。

在 Markdown 中按逗号稍作停顿查看上下文键位，按 `,?` 打开写作帮助。

### 列表和任务

```text
Enter      自动延续列表；空列表项再次 Enter 会结束列表
o          在普通模式延续列表
,x         切换任务复选框，并联动父子任务状态
gN         重新编号当前列表
>> / <<    调整列表层级
```

### 标题、链接和表格

```text
]] / [[    下一个 / 上一个标题
]u         父标题
,o         可跳转的标题目录
,O         在文档中插入三级目录
gx         浏览器打开光标所在链接
ge         在 Vim 中编辑相对 Markdown 链接
,tt        开关实时表格模式
,tr        重新对齐现有表格
visual ,tc 把选中内容转换成表格
```

### 预览和专注写作

```text
,p         Previm 浏览器实时预览（支持 Mermaid / PlantUML）
,g         Glow 终端预览
,z         Goyo + Limelight 专注模式
,s         开关拼写；]s/[s 跳转，z= 选择修正
,c         开关 Markdown conceal
,l         立即 lint
,f         使用 Prettier 格式化
g<C-g>     Vim 原生字数统计
gqap       格式化当前段落
```

### 从剪贴板粘贴图片

安装 `pngpaste` 后，在 Markdown 中执行：

```vim
:MarkdownPasteImage
:MarkdownPasteImage architecture.png
```

`,i` 使用时间戳文件名快速执行同一动作。图片默认保存到当前文档旁的
`assets/`，并插入相对 Markdown 图片链接。目标文件已存在时不会覆盖。

目录可以在 `.vimrc` 开头修改：

```vim
let g:chopsticks_markdown_image_dir = 'images'
```

## 输入法切换

`im-select` 不是常驻程序；每次执行时，它都会修改 macOS 当前的系统输入源，
自身没有“只改某个应用”的能力。chopsticks 因此在 Vim 获得焦点时先保存外部
输入源，只在 Vim 内为普通模式选择 ABC、为插入模式恢复该 buffer 上次使用的
输入法，并在 `FocusLost` 或退出 Vim 时原样恢复外部输入源。这样既保留中文
Markdown 写作体验；在焦点事件可用时，也不会把 Vim 的 ABC/中文状态遗留给
浏览器等其他应用。

```vim
:ChopsticksInputMethodStatus
:ChopsticksInputMethodToggle
:ChopsticksInputMethodEnable
:ChopsticksInputMethodDisable
```

SSH 会默认禁用输入法切换。退出 Vim 时会恢复保存的输入法，不把系统永久
留在 ABC。终端或 tmux 必须向 Vim 转发焦点事件，跨应用即时恢复才会生效；
`:ChopsticksInputMethodStatus` 会显示当前是否已捕获外部输入源。

如果只想在 Markdown 中启用，或需要完全关闭所有系统输入源调用，可以在
加载配置前设置：

```vim
let g:chopsticks_input_method_filetypes = ['markdown']
" 或：let g:chopsticks_enable_input_method = 0
```

## 其它好用的细节

- 持久撤销、集中 swap/backup/view 文件和自动创建保存目录。
- 10 MB 以上文件自动关闭 syntax 和 ALE，避免意外卡顿。
- `n/N`、`Ctrl-d/u` 搜索或滚动后保持目标位于屏幕中间。
- `vim-abolish` 提供大小写感知替换和 coercion。
- `vim-speeddating` 让 `Ctrl-a/x` 理解日期。
- `vim-surround`、commentary、targets 和 repeat 组成可重复的编辑语言。
- vim-which-key 在 Space 和 Markdown 逗号前缀后显示分组提示；完整键位表由
  同一份映射目录生成，不靠手工维护另一份易过期文档。
- 原生 statusline 显示模式、Git 分支、诊断、写作模式和文件位置。
- 原生 tabline 显示真实 Vim buffer，而不是把 buffer 冒充 tab page。
- Startify 提供最近文件、会话和书签，同时过滤凭据及 SSH 路径。

## 个性化

主要开关集中在 `.vimrc` 顶部：

```vim
let g:chopsticks_markdown_spell = 1
let g:chopsticks_markdown_conceal = 0
let g:chopsticks_markdown_image_dir = 'assets'
let g:chopsticks_transparent_background = 0
```

编辑后用 `SPC fR` 重新加载。插件提交全部固定；升级时修改声明中的 commit，
执行 `:PlugUpdate`，再运行 `:ChopsticksHealth` 和下方验证命令。

## 验证

最小启动检查：

```sh
vim -Nu "$PWD/.vimrc" -n -es '+qall!'
```

Markdown 交互检查：

```sh
vim -Nu "$PWD/.vimrc" README.md
```

进入后先分别按 Space 和逗号并停顿，确认全局和 Markdown 上下文菜单；再检查
`SPC ?`、`;f`、`ss`、`,x`、`,tt`、`,p`、`,g`、`,z`，最后运行：

```vim
:ChopsticksHealth
:LspStatus
:ALEInfo
```

## 社区来源

chopsticks 的取舍来自这些项目的公开实践和原始文档：

- [craftzdog/dotfiles-public](https://github.com/craftzdog/dotfiles-public)
- [LazyVim](https://github.com/LazyVim/LazyVim)
- [vim-plug](https://github.com/junegunn/vim-plug)
- [vim-which-key](https://github.com/liuchengxu/vim-which-key)
- [fzf.vim](https://github.com/junegunn/fzf.vim)
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
- [ALE](https://github.com/dense-analysis/ale)
- [vim-markdown](https://github.com/preservim/vim-markdown)
- [vim-pencil](https://github.com/preservim/vim-pencil)
- [bullets.vim](https://github.com/bullets-vim/bullets.vim)
- [vim-table-mode](https://github.com/dhruvasagar/vim-table-mode)
- [Previm](https://github.com/previm/previm)
- [Goyo](https://github.com/junegunn/goyo.vim) 和
  [Limelight](https://github.com/junegunn/limelight.vim)

配置会吸收它们的体验和接口约定，但不会复制 Neovim 专属实现。
