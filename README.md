# The Ultimate Vim Configuration

A comprehensive, modern Vim configuration optimized for engineering workflows. This configuration transforms vanilla Vim into a powerful, feature-rich development environment with enterprise-grade tooling.

**NEW: Quick installation script and enhanced engineering features!**

## Quick Start

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim && cd ~/.vim && ./install.sh
```

**Note:** The installation script must be run from the cloned `~/.vim` directory. See [QUICKSTART.md](QUICKSTART.md) for detailed getting started guide.

## Features

### Core Enhancements
- **Smart Line Numbers**: Hybrid line numbers (absolute + relative) for efficient navigation
- **Modern UI**: Gruvbox color scheme with airline status bar
- **Plugin Management**: vim-plug for easy plugin installation and updates
- **Auto-completion**: CoC (Conquer of Completion) for intelligent code completion
- **Syntax Checking**: ALE (Asynchronous Lint Engine) for real-time linting

### File Navigation
- **NERDTree**: Visual file explorer (`Ctrl+n`)
- **FZF**: Blazing fast fuzzy finder (`Ctrl+p`)
- **CtrlP**: Alternative fuzzy file finder
- **Easy Motion**: Jump to any location with minimal keystrokes

### Git Integration
- **Fugitive**: Complete Git wrapper for Vim
- **GitGutter**: Show git diff in the sign column

### Code Editing
- **Auto-pairs**: Automatic bracket/quote pairing
- **Surround**: Easily change surrounding quotes, brackets, tags
- **Commentary**: Quick code commenting (`gc`)
- **Multi-language Support**: vim-polyglot for 100+ languages

### Productivity Tools
- **UndoTree**: Visualize and navigate undo history (`F5`)
- **Tagbar**: Code structure browser (`F8`)
- **Smart Window Management**: Easy navigation with `Ctrl+hjkl`
- **Session Management**: Auto-save sessions with vim-obsession
- **Project-Specific Settings**: Per-project .vimrc support
- **Large File Optimization**: Automatic performance tuning for files >10MB
- **TTY/Basic Terminal Support**: Automatic optimization for console environments

## Installation

### Automatic Installation (Recommended)

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim
./install.sh
```

**IMPORTANT:** You must run the install script from the `~/.vim` directory (the cloned repository directory). Do not copy the script to another location and run it from there.

The installation script will:
- Verify it's being run from the correct directory
- Backup your existing configuration
- Create necessary symlinks
- Validate symlink creation
- Install vim-plug automatically
- Install all plugins
- Offer to install CoC language servers

### Manual Installation

```bash
# 1. Clone this repository
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim

# 2. Create symlink to .vimrc
ln -s ~/.vim/.vimrc ~/.vimrc

# 3. Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 4. Open Vim and install plugins
vim +PlugInstall +qall
```

### 4. (Optional) Install recommended dependencies

For the best experience, install these optional dependencies:

```bash
# FZF (fuzzy finder)
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# ripgrep (better grep)
# On Ubuntu/Debian
sudo apt install ripgrep

# On macOS
brew install ripgrep

# Node.js (for CoC)
# Required for code completion
curl -sL install-node.now.sh/lts | bash

# Universal Ctags (for Tagbar)
# On Ubuntu/Debian
sudo apt install universal-ctags

# On macOS
brew install universal-ctags
```

### 5. Install CoC language servers

For intelligent code completion, install language servers:

```vim
" Python
:CocInstall coc-pyright

" JavaScript/TypeScript
:CocInstall coc-tsserver

" Go
:CocInstall coc-go

" JSON
:CocInstall coc-json

" HTML/CSS
:CocInstall coc-html coc-css

" See more: https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions
```

## Key Mappings

### General

| Key | Action |
|-----|--------|
| `,w` | Quick save |
| `,q` | Quick quit |
| `,x` | Save and quit |
| `,,` + Enter | Clear search highlight |

### Window Navigation

| Key | Action |
|-----|--------|
| `Ctrl+h` | Move to left window |
| `Ctrl+j` | Move to bottom window |
| `Ctrl+k` | Move to top window |
| `Ctrl+l` | Move to right window |

### Buffer Management

| Key | Action |
|-----|--------|
| `,l` | Next buffer |
| `,h` | Previous buffer |
| `,bd` | Close current buffer |
| `,ba` | Close all buffers |

### Tab Management

| Key | Action |
|-----|--------|
| `,tn` | New tab |
| `,tc` | Close tab |
| `,tl` | Toggle to last tab |

### File Navigation

| Key | Action |
|-----|--------|
| `Ctrl+n` | Toggle NERDTree |
| `,n` | Find current file in NERDTree |
| `Ctrl+p` | FZF file search |
| `,b` | FZF buffer search |
| `,rg` | Ripgrep search |

### Code Navigation (CoC)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Go to references |
| `K` | Show documentation |
| `[g` | Previous diagnostic |
| `]g` | Next diagnostic |
| `,rn` | Rename symbol |

### Linting (ALE)

| Key | Action |
|-----|--------|
| `,aj` | Next error/warning |
| `,ak` | Previous error/warning |
| `,ad` | Show error details |

### Git Workflow

| Key | Action |
|-----|--------|
| `,gs` | Git status |
| `,gc` | Git commit |
| `,gp` | Git push |
| `,gl` | Git pull |
| `,gd` | Git diff |
| `,gb` | Git blame |

### Engineering Utilities

| Key | Action |
|-----|--------|
| `,ev` | Edit .vimrc |
| `,sv` | Reload .vimrc |
| `,F` | Format entire file |
| `,wa` | Save all buffers |
| `,cp` | Copy file path |
| `,cf` | Copy filename |
| `,*` | Search & replace word under cursor |
| `,<leader>` | Switch to last file |

### Other Utilities

| Key | Action |
|-----|--------|
| `F2` | Toggle paste mode |
| `F3` | Toggle line numbers |
| `F4` | Toggle relative numbers |
| `F5` | Toggle UndoTree |
| `F8` | Toggle Tagbar |
| `Space` | Toggle fold |
| `s` + 2 chars | EasyMotion jump |

## Plugin List

### File Navigation & Search
- **NERDTree**: File system explorer
- **FZF**: Fuzzy file finder
- **CtrlP**: Alternative fuzzy finder

### Git
- **vim-fugitive**: Git integration
- **vim-gitgutter**: Git diff in sign column

### UI
- **vim-airline**: Enhanced status line
- **gruvbox**: Color scheme

### Code Editing
- **vim-surround**: Manage surroundings
- **vim-commentary**: Code commenting
- **auto-pairs**: Auto close brackets
- **ALE**: Asynchronous linting

### Language Support
- **vim-polyglot**: Language pack for 100+ languages
- **vim-go**: Go development

### Productivity
- **UndoTree**: Undo history visualizer
- **Tagbar**: Code structure browser
- **EasyMotion**: Fast cursor movement
- **CoC**: Code completion and LSP
- **vim-obsession**: Session management
- **vim-prosession**: Project sessions
- **vim-unimpaired**: Handy bracket mappings
- **targets.vim**: Additional text objects

## Color Schemes

Available color schemes (change in .vimrc):

- **gruvbox** (default) - Warm, retro groove colors
- **dracula** - Dark theme with vivid colors
- **solarized** - Precision colors for machines and people
- **onedark** - Atom's iconic One Dark theme

To change:

```vim
colorscheme dracula
```

## Engineering Features

### Project-Specific Configuration

Create a `.vimrc` file in your project root for project-specific settings:

```vim
" .vimrc in project root
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

The configuration automatically loads project-specific settings while maintaining security.

### Session Management

Sessions are automatically saved with vim-obsession:

```vim
" Start session tracking
:Obsess

" Stop session tracking
:Obsess!

" Sessions are saved to ~/.vim/sessions/
```

### Large File Handling

Files larger than 10MB automatically disable heavy features for better performance:
- Syntax highlighting optimized
- Undo levels reduced
- Swap files disabled

### Terminal Integration

Open integrated terminal:
- `,tv` - Vertical terminal split
- `,th` - Horizontal terminal split (10 rows)

Navigate out of terminal with `Esc` then normal window navigation.

### TTY and Basic Terminal Support

The configuration automatically detects and optimizes for basic terminal environments (TTY, Linux console):

**Automatic Optimizations:**
- Disables true color mode for compatibility
- Uses simple ASCII separators instead of powerline fonts
- Falls back to default colorscheme
- Disables cursorline for better performance
- Simplifies signcolumn behavior
- Disables FZF preview windows
- Skips auto-opening NERDTree
- Uses simpler status line
- Reduces syntax highlighting complexity
- Faster startup and redraw

**Detected Terminals:**
- Linux console (TERM=linux)
- Screen sessions (TERM=screen)
- Basic built-in terminals

The configuration provides a message on first run in TTY mode to inform about the optimizations.

## Customization

The configuration is organized into sections:

1. **General Settings**: Basic Vim behavior
2. **Plugin Management**: vim-plug configuration
3. **Colors & Fonts**: Visual appearance
4. **Key Mappings**: Custom keybindings
5. **Plugin Settings**: Individual plugin configurations
6. **Auto Commands**: File-type specific settings
7. **Helper Functions**: Utility functions
8. **Engineering Utilities**: Project workflow tools
9. **Git Workflow**: Git integration shortcuts

Feel free to modify any section to suit your needs!

### Quick Customization

Edit configuration:
```vim
,ev  " Opens .vimrc in Vim
```

Reload configuration:
```vim
,sv  " Sources .vimrc without restart
```

## Language-Specific Settings

### Python
- 4 spaces indentation
- 88 character line limit (Black formatter)
- Auto-formatting with Black + isort on save
- Linting with flake8 and pylint

### JavaScript/TypeScript
- 2 spaces indentation
- Prettier formatting on save
- ESLint integration
- TypeScript server support

### Go
- Tab indentation
- Auto-formatting with gofmt
- Auto-import with goimports
- gopls language server

### Rust
- Auto-formatting with rustfmt
- Cargo integration

### Shell Scripts
- 2 spaces indentation
- shellcheck linting

### Docker
- Dockerfile syntax highlighting
- hadolint linting

### YAML
- 2 spaces indentation
- yamllint integration

### HTML/CSS
- 2 spaces indentation
- Prettier formatting

### Markdown
- Line wrapping enabled
- Spell checking enabled
- Prettier formatting

## Troubleshooting

### Plugins not working

```vim
:PlugInstall
:PlugUpdate
```

### CoC not working

Make sure Node.js is installed:

```bash
node --version  # Should be >= 14.14
```

### Colors look wrong

Enable true colors in your terminal emulator and add to your shell rc:

```bash
export TERM=xterm-256color
```

## References

This configuration is inspired by:

- [amix/vimrc](https://github.com/amix/vimrc) - The ultimate vimrc
- [vim-plug](https://github.com/junegunn/vim-plug) - Minimalist plugin manager
- [Top 50 Vim Configuration Options](https://www.shortcutfoo.com/blog/top-50-vim-configuration-options)
- [Modern Vim Development Setup 2025](https://swedishembedded.com/developers/vim-in-minutes)

## License

MIT License - Feel free to use and modify!

## Contributing

Suggestions and improvements are welcome! Feel free to open an issue or submit a pull request.
