# Vim9 core migration

Status: proposed, 2026-09-04

## Problem

Chopsticks is a 2843-line single-file `.vimrc` for Vim 8.2/9.x. It is strong on
presentation, Markdown authoring, and supply-chain discipline: every plugin is
commit-pinned, the vim-plug bootstrap is SHA-256 verified, startup never uses
the network, and the README documents refusing fzf's bundled downloader because
that downloader fetches a second artifact without verifying a checksum.

It is thin on development capability. These are absent from `.vimrc`, verified
by grep:

- Debugging. No `termdebug` configuration and no DAP client.
- Snippets. `vim-lsp` does not support them without a third-party plugin, so
  completing a function inserts its name and no parameter placeholders.
- Symbol outline and workspace symbol search, although an LSP client is running.
- Inlay hints and semantic highlighting.

Two structural liabilities compound this:

- `fzf` is an external executable. It is the most awkward step in the Windows
  install path, and it sits uneasily beside the project's own supply-chain rules.
- `g:lsp_settings_lazyload = 0` is set deliberately (`.vimrc:359`) because
  vim-lsp-settings' lazy path replays `BufEnter` for every loaded buffer, which
  parses large Markdown files twice. Server startup timing is not ours to control.

## Decisions

| # | Decision |
| --- | --- |
| D1 | Chopsticks becomes a terminal development environment. This spec covers only the editor core. |
| D2 | Our own code moves from one legacy-script `.vimrc` to Vim9script `autoload/` modules. The single-file property is retired. |
| D3 | LSP client: `prabirshrestha/vim-lsp` + `mattn/vim-lsp-settings` to `yegappan/lsp`. |
| D4 | Insert-mode completion: `asyncomplete.vim` + `asyncomplete-lsp.vim` to Vim's built-in `'autocomplete'`. |
| D5 | Fuzzy finding: `junegunn/fzf` + `fzf.vim` to `vim-fuzzbox/fuzzbox.vim`. |
| D6 | Command-line completion: adopt built-in `wildtrigger()` with `wildoptions=pum`. |
| D7 | Debugging: built-in `termdebug`. DAP is deferred. |
| D8 | Snippets: `vim-vsnip` + `vim-vsnip-integ`. |
| D9 | No in-editor AI agent plugin. |

### D2, retiring the single file

`vim9script` must be a file's first command (`vim9.txt:233-240`); there is no
inline Vim9 block, and `:vim9cmd` is per-line. So a Vim9 `.vimrc` means
rewriting all 2843 lines at once, with 117 functions, 68 mappings, and 16
commands changing syntax in a single irreversible step.

Splitting into `autoload/` modules costs the "single-file" line in the README
and buys three things:

1. Migration proceeds one module at a time, each independently revertable.
2. `import autoload` does not read a module until one of its functions is first
   called. This is stricter laziness than vim-plug's `for:`/`on:`, and it is the
   mechanism the language registry below depends on.
3. `def` functions are compiled (`vim9.txt`: "many times faster"), which matters
   most on the dashboard, statusline, and bufferline redraw paths that
   `docs/performance.md` already tracks.

`.vimrc` stays legacy script and becomes thin. It runs earliest and must
`:source` the user's own `chopsticks.local.vim`, which is legacy.

### D3, the LSP client

`yegappan/lsp` is pure Vim9script, requires Vim 9.0+, and was last updated
2026-09-03. It ships the three gaps above as built-in features: `:LspOutline`,
`showInlayHints`, and `semanticHighlight`, plus `:LspSymbolSearch`, call and
type hierarchy, and `:LspPeek*`. That removes any need for `vista.vim` or
`tagbar`.

It has no equivalent of `:LspInstallServer`. Servers are registered explicitly
via `LspAddServer()`, which is what makes the language registry possible and
puts startup timing back under our control. vim-lsp's maintainer has argued
against a Vim9script port on the grounds that the real bottlenecks belong in
Vim's C core, so the current stack is unlikely to follow the platform forward
even though it remains maintained.

### D4, completion with no completion plugin

`'complete'` accepts an `o` flag, documented as: "equivalent to `F{func}`, where
{func} is taken from the 'omnifunc' option. If a plugin (such as an LSP client)
defines 'omnifunc', it can be used through this flag." `yegappan/lsp` exposes an
`omniComplete` option. `'autocomplete'` then drives the popup automatically,
collecting from every source in `'complete'` under a decaying timeout that keeps
Vim responsive.

    yegappan/lsp sets omnifunc
      -> set complete=.,w,b,o,F{snippet}
      -> set autocomplete

Two plugins removed, nothing added.

### D5, buying the fuzzy finder rather than building it

An earlier draft of this design proposed `girishji/scope.vim`. Both `scope.vim`
and `girishji/vimcomplete` are now marked deprecated by their author, who
upstreamed their core features into Vim. That is what D4 and D6 consume.

The replacement draft proposed hand-writing pickers from the `cmdline.txt`
examples. `vim-fuzzbox/fuzzbox.vim` is a better trade:

- Actively maintained: last commit 2026-09-02, zero open issues, issue #140
  fixed within a day.
- Pure vim9script, Vim 9.0+, explicitly does not support Neovim.
- 26 selectors against roughly six we would have written, and it has a preview
  window, which `scope.vim` deliberately omitted.
- Works out of the box on macOS, Linux, and Windows. It prefers `rg`/`ugrep`/
  `ag`/`fd` when present and falls back to `grep`, `git grep`, `findstr`, or
  `powershell`. So `fzf` leaves the README's required-tools list without a new
  hard dependency taking its place.
- Integrates with `vim-nerdfont` and `vim-glyph-palette`, both already installed
  for Fern.
- Extensible through `fuzzbox#Select()` and `fuzzbox#Launch()` for
  chopsticks-specific pickers.

### D7, why termdebug before DAP

`vimspector`'s `:VimspectorInstall` downloads debug adapters at runtime without
checksum verification. That is the same pattern this project already rejected
for fzf's downloader, and it contradicts "startup never uses the network."
`termdebug` is built in, needs no network, cannot be deprecated, and covers
gdb/lldb, so C, C++, Rust, and Go. DAP can be revisited once adapters can be
pinned and verified the way plugins already are.

## Architecture

### Layout

    .vimrc                          thin bootstrap, legacy script
    plugin/chopsticks.vim           command and mapping declarations
    autoload/chopsticks/
      options.vim  keys.vim  session.vim  health.vim
      ui/ theme.vim  dashboard.vim  statusline.vim  bufferline.vim  icons.vim
      lsp.vim                       LspAddServer dispatch, registry driver
      complete.vim                  'autocomplete' and 'complete' wiring
      find.vim                      fuzzbox configuration and custom selectors
      debug.vim                     termdebug wrapper
      markdown.vim
    lang/                           one file per language

`plugin/chopsticks.vim` only declares commands and mappings, which is cheap and
must happen at startup. Every mapping's right-hand side calls into an
`autoload/` function, so no module is read until it is used.

### Language registry

`lang/rust.vim` holds the rust-analyzer `LspAddServer()` dictionary, the ALE
linter and fixer entries, and the `termdebug` settings for Rust. A `FileType`
autocommand calls `chopsticks#lsp#Ensure('rust')`, which reads `lang/rust.vim`
on first use and registers the server once.

A language you never open costs nothing: no file read, no server started, no
entry in any dictionary. This is what replaces answering "which languages do you
use", and it is why `g:lsp_settings_lazyload` stops being a dilemma. We choose
the registration moment ourselves instead of accepting a plugin's `BufEnter`
replay.

### Theming

fuzzbox exposes `g:fuzzbox_borderchars` and the `fuzzbox*` highlight groups.
`ui/theme.vim` wires these to Everforest alongside the existing groups. Existing
switches map across: `g:chopsticks_icons = 0` sets `g:fuzzbox_devicons = 0`, and
`g:fuzzbox_devicons_glyph_func` and `g:fuzzbox_devicons_color_func` point at
`nerdfont#find` and `glyph_palette#apply`.

## Plugin accounting

| Removed | Added |
| --- | --- |
| `junegunn/fzf` | `yegappan/lsp` |
| `junegunn/fzf.vim` | `vim-fuzzbox/fuzzbox.vim` |
| `prabirshrestha/vim-lsp` | `hrsh7th/vim-vsnip` |
| `mattn/vim-lsp-settings` | `hrsh7th/vim-vsnip-integ` |
| `prabirshrestha/asyncomplete.vim` | |
| `prabirshrestha/asyncomplete-lsp.vim` | |

Six out, four in, and the `fzf` executable leaves the prerequisite list. Gained:
debugging, snippets, symbol outline, workspace symbol search, inlay hints,
semantic highlighting, call and type hierarchy, and a preview window in the
finder.

Every new plugin is commit-pinned like the rest.

## Phases

Each phase is one pull request. CI must be green before the next begins.

**Phase 0 — skeleton.** Create the `autoload/` layout and move existing code
into it, converting legacy syntax to Vim9. No behavior changes. This separates
"we restructured" from "we swapped a plugin", so a later regression has one
obvious cause.

Done when: `tests/plugins.vim` and `tests/ui.vim` pass unchanged,
`scripts/benchmark-vim.py` shows no startup regression, and every documented
command, mapping, and `g:chopsticks_*` switch behaves as before.

**Phase 1 — LSP.** Replace vim-lsp with `yegappan/lsp`. Build the language
registry and `chopsticks#lsp#Ensure()`. Remove `g:lsp_settings_lazyload`.

Done when: `:LspOutline`, inlay hints, and semantic highlighting work; opening a
file of an unregistered filetype reads no `lang/` file.

**Phase 2 — completion.** Move to `'autocomplete'` with `complete+=o`. Delete
both asyncomplete plugins. Rework the existing `<Tab>`/`<S-Tab>` handlers at
`.vimrc:2529-2530`.

**Phase 3 — finder.** Replace fzf and fzf.vim with fuzzbox. Port the existing
`s:fzf_abort_keys` and `s:FzfVisualOptions()` behavior onto `g:fuzzbox_keymaps`
and window options. Adopt `wildtrigger()` for command-line completion. Update
the README install steps and `docs/configuration.md`.

Done when: no `fzf` binary is required on any of the three platforms.

**Phase 4 — new capability.** Add vim-vsnip and the `termdebug` wrapper. Fill
the Python and Rust linter and fixer gaps in `lang/`.

## Risks

| Risk | Mitigation |
| --- | --- |
| Phase 0 is a large mechanical rewrite where a typo becomes a silent behavior change. | Behavior must be provably identical; the existing test and benchmark suites are the gate. Convert one module per commit. |
| `yegappan/lsp` has no server auto-installer, so every server must be installed by hand. | `:ChopsticksHealth` reports missing servers with the install command for the platform. |
| fuzzbox is a single-maintainer project. | Same exposure as the other 30 pinned plugins. Commit-pin it, and note that its selectors are ordinary popups, so a fork or replacement is contained to `find.vim`. |
| `'autocomplete'` is recent and less battle-tested than asyncomplete. | Phase 2 is independently revertable; it touches only `complete.vim` and the Tab handlers. |
| Retiring "single-file" weakens a documented selling point. | Replace the claim in the README with what actually matters: no network at startup, pinned dependencies, and now genuine lazy loading. |

## Out of scope

Deferred to their own spec, plan, and implementation cycle:

- **A.** Palette and theme generator, a separate repository. A neutral-format
  palette generating the Vim colorscheme alongside ghostty, wezterm, kitty,
  tmux, starship, bat, delta, lazygit, and eza themes, so every layer shares one
  source. Modeled on `folke/tokyonight.nvim`'s extras mechanism, but with the
  palette held outside the editor's language rather than inside it.
- **C.** Terminal environment layer. Terminal emulator and tmux configuration, a
  cross-platform installer, and the seams that let Vim and a terminal agent
  coexist: pane navigation, pushing file, selection, and diagnostics to the
  agent, and reloading changed files with the diff highlighted.
- **D.** Ergonomic key layer. Caps Lock as Esc/Ctrl and home-row mods, expressed
  once and shared across Karabiner on macOS, keyd on Arch, and WSL, then a
  review of the 60-plus in-editor mappings.

A depends on nothing. C consumes A's output. D depends on C's tmux.
