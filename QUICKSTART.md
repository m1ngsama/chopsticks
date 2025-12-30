# Quick Start Guide

Get up and running with this Vim configuration in 5 minutes!

## Installation

### One-Line Install

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim && cd ~/.vim && ./install.sh
```

**IMPORTANT:** Always run the install script from the `~/.vim` directory (where you cloned the repository). The script validates this to ensure correct symlink creation.

That's it! The script will:
- Verify it's being run from the correct directory
- Backup your existing .vimrc
- Create and validate symlink to the new configuration
- Install vim-plug
- Install all plugins automatically

### Manual Install

```bash
# 1. Clone the repository
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim

# 2. Create symlink
ln -sf ~/.vim/.vimrc ~/.vimrc

# 3. Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 4. Open Vim and install plugins
vim +PlugInstall +qall
```

## Essential Key Mappings

### File Operations
| Key | Action |
|-----|--------|
| `,w` | Quick save |
| `,q` | Quick quit |
| `,x` | Save and quit |

### Navigation
| Key | Action |
|-----|--------|
| `Ctrl+n` | Toggle file explorer (NERDTree) |
| `Ctrl+p` | Fuzzy file search (FZF) |
| `Ctrl+h/j/k/l` | Navigate between windows |
| `,b` | Search open buffers |

### Code Intelligence
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Show documentation |
| `Tab` | Autocomplete (when popup is visible) |

### Editing
| Key | Action |
|-----|--------|
| `gc` | Comment/uncomment (in visual mode) |
| `Space` | Toggle fold |
| `,,+Enter` | Clear search highlight |

## Common Workflows

### Opening a Project

```bash
# Navigate to your project directory
cd ~/my-project

# Open Vim
vim

# Press Ctrl+n to open file explorer
# Press Ctrl+p to fuzzy search files
```

### Editing Code

1. Open a file with `Ctrl+p` or through NERDTree
2. Use `gd` to jump to definitions
3. Use `K` to view documentation
4. Use `Tab` for autocomplete while typing
5. Save with `,w`

### Working with Git

| Command | Action |
|---------|--------|
| `:Git status` | View git status |
| `:Git diff` | View changes |
| `:Git commit` | Commit changes |
| `:Git push` | Push to remote |
| `,gb` | Open git blame window |

### Search and Replace

```vim
" Search in current file
/searchterm

" Search across project (with FZF)
,rg

" Replace in file
:%s/old/new/g

" Replace with confirmation
:%s/old/new/gc
```

## Language-Specific Features

### Python

- Auto-formatting with Black (on save)
- Linting with flake8/pylint
- 4-space indentation
- 88-character line limit

**Setup:**
```bash
pip install black flake8 pylint
vim -c "CocInstall coc-pyright" -c "q"
```

### JavaScript/TypeScript

- Prettier formatting (on save)
- ESLint integration
- 2-space indentation

**Setup:**
```bash
npm install -g prettier eslint
vim -c "CocInstall coc-tsserver coc-prettier coc-eslint" -c "q"
```

### Go

- Auto-formatting with gofmt
- Auto-imports with goimports
- Tab indentation

**Setup:**
```bash
go install golang.org/x/tools/gopls@latest
vim -c "CocInstall coc-go" -c "q"
```

## Troubleshooting

### Plugins not working?

```vim
:PlugInstall
:PlugUpdate
```

### Autocomplete not working?

Make sure Node.js is installed:
```bash
node --version  # Should be >= 14.14
```

Then install CoC language servers:
```vim
:CocInstall coc-json coc-tsserver coc-pyright
```

### FZF not finding files?

Install FZF and ripgrep:
```bash
# Ubuntu/Debian
sudo apt install fzf ripgrep

# macOS
brew install fzf ripgrep
```

### Colors look weird?

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
export TERM=xterm-256color
```

## Customization

The `.vimrc` file is well-organized into sections:

1. **General Settings** (lines 1-150) - Basic Vim behavior
2. **Plugin Management** (lines 151-230) - Plugin list
3. **Key Mappings** (lines 300-400) - Custom shortcuts
4. **Plugin Settings** (lines 400-600) - Plugin configurations

To customize:
1. Open `~/.vim/.vimrc`
2. Find the section you want to modify
3. Make your changes
4. Reload with `:source ~/.vimrc` or restart Vim

### Common Customizations

**Change colorscheme:**
```vim
" In .vimrc, find the colorscheme line and change to:
colorscheme dracula
" or: solarized, onedark, gruvbox
```

**Change leader key:**
```vim
" Default is comma (,), change to space:
let mapleader = " "
```

**Disable relative line numbers:**
```vim
set norelativenumber
```

## Next Steps

1. Read the full [README.md](README.md) for complete documentation
2. Check out `:help` in Vim for built-in documentation
3. Customize the configuration to your needs
4. Share your improvements!

## Quick Reference Card

Print this for your desk:

```
┌─────────────────────────────────────────────┐
│           Vim Quick Reference               │
├─────────────────────────────────────────────┤
│ FILES                                       │
│  Ctrl+n    File explorer                    │
│  Ctrl+p    Fuzzy find files                 │
│  ,w        Save                             │
│  ,q        Quit                             │
├─────────────────────────────────────────────┤
│ NAVIGATION                                  │
│  gd        Go to definition                 │
│  gr        Find references                  │
│  K         Show docs                        │
│  Ctrl+o    Jump back                        │
│  Ctrl+i    Jump forward                     │
├─────────────────────────────────────────────┤
│ EDITING                                     │
│  gc        Comment (visual mode)            │
│  Tab       Autocomplete                     │
│  Space     Toggle fold                      │
├─────────────────────────────────────────────┤
│ SEARCH                                      │
│  /text     Search forward                   │
│  ?text     Search backward                  │
│  ,rg       Project-wide search              │
│  ,,Enter   Clear highlight                  │
└─────────────────────────────────────────────┘
```

Happy Vimming!
