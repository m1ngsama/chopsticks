# chopsticks

[![check](https://github.com/m1ngsama/chopsticks/actions/workflows/check.yml/badge.svg)](https://github.com/m1ngsama/chopsticks/actions/workflows/check.yml)

A single-file configuration for Vim 8.2/9.x, focused on development and
Markdown writing. Neovim is not supported. Startup never uses the network.

## Install

Requires Vim 8.2+, Git, and
[vim-plug](https://github.com/junegunn/vim-plug):

```sh
git clone https://github.com/m1ngsama/chopsticks.git
ln -s "$PWD/chopsticks/.vimrc" "$HOME/.vimrc"

curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +PlugInstall +qall
```

Handle an existing `~/.vimrc` before creating the link. Recommended tools:

```sh
brew install ripgrep fzf fd lazygit marksman glow pandoc pngpaste
npm install --global markdownlint-cli prettier
```

iTerm2 enables Nerd Font icons automatically when its active font supports
them. Set `g:chopsticks_icons = 0` before sourcing the file for ASCII output.

## Use

Pause after Space, or after comma in Markdown, to open the contextual key
guide. `SPC ?` opens the searchable full cheatsheet.

```text
Ctrl-s  save              Ctrl-p / ;f  find files
;r      project grep      \             list buffers
H / L   previous/next     sh/sj/sk/sl   focus window
ss / sv split/vsplit      sq            close window
SPC e   toggle file tree  SPC u i       toggle icons

SPC b   buffers           SPC c         code
SPC f   files             SPC g         Git
SPC r   run               SPC s         search
SPC t   terminal          SPC w         windows
SPC x   diagnostics       SPC u         toggles
```

Comma is the Markdown LocalLeader:

```text
,o  heading outline       ,O  insert TOC
,x  toggle task           ,tt table mode
,tr realign table         ,i  paste clipboard image
,p  browser preview       ,g  Glow preview
,z  focus mode            ,f  format
,l  lint                  ,?  Markdown keys
```

```vim
:ChopsticksHealth
:ChopsticksCheatsheet
```

## Input methods

[im-select](https://github.com/daipeihust/im-select) changes the current macOS
system input source; it has no per-application state. Chopsticks snapshots the
outside source when Vim gains focus, applies Normal/Insert preferences while
Vim is active, and restores the snapshot on focus loss or exit. The terminal
or tmux must forward focus events to Vim.

```vim
:ChopsticksInputMethodStatus
:ChopsticksInputMethodToggle

" Optional: enable only for Markdown
let g:chopsticks_input_method_filetypes = ['markdown']

" Optional: disable all input-source calls
let g:chopsticks_enable_input_method = 0
```

## Update

```sh
git pull --ff-only
vim +PlugUpdate +qall
```

## License

MIT
