" plugins.vim — vim-plug declarations

let s:autoload_dir = expand('~/.vim/autoload')
let s:plug_path = s:autoload_dir . '/plug.vim'

" Locked to the plugin revisions currently verified by the Vim smoke suite.
" Set g:chopsticks_pin_plugins = 0 before loading chopsticks to test updates.
let s:plugin_locks = {
    \ 'ale': 'ba8b9cbab95131e284c5be926642f803b2be0058',
    \ 'asyncomplete-lsp.vim': 'da23f4418a6301feac7b99e1728fb79acb243d69',
    \ 'asyncomplete.vim': '17b654a87a834d4e835fb7467e562b4421ad9310',
    \ 'auto-pairs': '39f06b873a8449af8ff6a3eee716d3da14d63a76',
    \ 'fzf': '0eb2ae9f8bd57fed6242d76d2273df4a1be31cc8',
    \ 'fzf.vim': '34a564c81f36047f50e593c1656f4580ff75ccca',
    \ 'previm': '2bccb5e2a14e9f344f2656578b815b0da5c37fe3',
    \ 'targets.vim': '6325416da8f89992b005db3e4517aaef0242602e',
    \ 'undotree': '6fa6b57cda8459e1e4b2ca34df702f55242f4e4d',
    \ 'vim-commentary': '64a654ef4a20db1727938338310209b6a63f60c9',
    \ 'vim-easymotion': 'b3cfab2a6302b3b39f53d9fd2cd997e1127d7878',
    \ 'vim-fugitive': '3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0',
    \ 'vim-gitgutter': '21c977e8597c468c7dc76001389b0b430d46a4b0',
    \ 'vim-go': 'f4b4ba17035aebcd222df90375c1cbb1dc4d8c5b',
    \ 'vim-javascript': 'b26c9edb3563e02f5c0b20580f7cf9743e95b157',
    \ 'vim-lsp': '0c49560e5fbc97876e51bef6b993e48677cc15fc',
    \ 'vim-lsp-settings': 'a0ec2ee4e75a14f2471896a1192c1970d7be4258',
    \ 'vim-markdown': '1bc9d0cd8e1cc3e901b0a49c2b50a843f1c89397',
    \ 'vim-repeat': '65846025c15494983dafe5e3b46c8f88ab2e9635',
    \ 'vim-sleuth': 'be69bff86754b1aa5adcbb527d7fcd1635a84080',
    \ 'vim-solarized8': '4433b4411de92b2446a4d32f0d8bf1b25c476bf9',
    \ 'vim-startify': '4e089dffdad46f3f5593f34362d530e8fe823dcf',
    \ 'vim-surround': '3d188ed2113431cf8dac77be61b842acb64433d9',
    \ 'vim-tmux-navigator': 'e41c431a0c7b7388ae7ba341f01a0d217eb3a432',
    \ 'yats.vim': '2d9b95b91b9f72bb1769951841b32d2a879d3cd7',
    \ }
let g:chopsticks_plugin_lock_count = len(s:plugin_locks)
let g:chopsticks_plugin_locks = copy(s:plugin_locks)

function! ChopsticksLockedPlugOpts(name, opts) abort
    let l:opts = copy(a:opts)
    if get(g:, 'chopsticks_pin_plugins', 1)
        let l:commit = get(get(g:, 'chopsticks_plugin_locks', {}), a:name, '')
        if !empty(l:commit)
            let l:opts.commit = l:commit
        endif
    endif
    return l:opts
endfunction

if empty(glob(s:plug_path))
    silent execute '!curl -fLo ' . shellescape(s:plug_path) . ' --create-dirs '
        \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    augroup PlugBootstrap
        autocmd!
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    augroup END
endif

call plug#begin('~/.vim/plugged')

" ── Navigation & Search ──────────────────────────────────────────────────────
Plug 'junegunn/fzf', ChopsticksLockedPlugOpts('fzf', { 'do': { -> fzf#install() } })
Plug 'junegunn/fzf.vim', ChopsticksLockedPlugOpts('fzf.vim', {})

" ── Git ──────────────────────────────────────────────────────────────────────
Plug 'tpope/vim-fugitive', ChopsticksLockedPlugOpts('vim-fugitive', {})
Plug 'airblade/vim-gitgutter', ChopsticksLockedPlugOpts('vim-gitgutter', {})

" ── Editing ──────────────────────────────────────────────────────────────────
Plug 'tpope/vim-surround', ChopsticksLockedPlugOpts('vim-surround', {})
Plug 'tpope/vim-commentary', ChopsticksLockedPlugOpts('vim-commentary', {})
Plug 'tpope/vim-repeat', ChopsticksLockedPlugOpts('vim-repeat', {})
Plug 'tpope/vim-sleuth', ChopsticksLockedPlugOpts('vim-sleuth', {})
Plug 'wellle/targets.vim', ChopsticksLockedPlugOpts('targets.vim', {})
Plug 'easymotion/vim-easymotion', ChopsticksLockedPlugOpts('vim-easymotion', { 'on': '<Plug>(easymotion' })

if g:chopsticks_enable_auto_pairs
    Plug 'jiangmiao/auto-pairs', ChopsticksLockedPlugOpts('auto-pairs', {})
endif

if g:chopsticks_enable_lint
    " ── Linting & Formatting ────────────────────────────────────────────────
    Plug 'dense-analysis/ale', ChopsticksLockedPlugOpts('ale', {})
endif

if g:chopsticks_enable_lsp
    " ── LSP + Completion ─────────────────────────────────────────────────────
    Plug 'prabirshrestha/vim-lsp', ChopsticksLockedPlugOpts('vim-lsp', {})
    Plug 'mattn/vim-lsp-settings', ChopsticksLockedPlugOpts('vim-lsp-settings', {})
    Plug 'prabirshrestha/asyncomplete.vim', ChopsticksLockedPlugOpts('asyncomplete.vim', {})
    Plug 'prabirshrestha/asyncomplete-lsp.vim', ChopsticksLockedPlugOpts('asyncomplete-lsp.vim', {})
endif

" ── Language Syntax ──────────────────────────────────────────────────────────
Plug 'preservim/vim-markdown', ChopsticksLockedPlugOpts('vim-markdown', { 'for': 'markdown' })
if g:chopsticks_enable_markdown_preview
    Plug 'previm/previm', ChopsticksLockedPlugOpts('previm', { 'on': 'PrevimOpen' })
endif
if g:chopsticks_enable_extra_languages
    Plug 'pangloss/vim-javascript', ChopsticksLockedPlugOpts('vim-javascript', { 'for': ['javascript', 'javascript.jsx'] })
    Plug 'HerringtonDarkholme/yats.vim', ChopsticksLockedPlugOpts('yats.vim', { 'for': ['typescript', 'typescript.tsx'] })
    Plug 'fatih/vim-go', ChopsticksLockedPlugOpts('vim-go', { 'for': 'go' })
endif

" ── UI ───────────────────────────────────────────────────────────────────────
if g:chopsticks_enable_ui_extras
    Plug 'mbbill/undotree', ChopsticksLockedPlugOpts('undotree', { 'on': 'UndotreeToggle' })
    Plug 'mhinz/vim-startify', ChopsticksLockedPlugOpts('vim-startify', {})
endif
Plug 'lifepillar/vim-solarized8', ChopsticksLockedPlugOpts('vim-solarized8', {})
if g:chopsticks_enable_tmux_navigator && !empty($TMUX)
    Plug 'christoomey/vim-tmux-navigator', ChopsticksLockedPlugOpts('vim-tmux-navigator', {})
endif

call plug#end()

function! ChopsticksPluginInfo() abort
    let l:declared = exists('g:plugs') ? sort(keys(g:plugs)) : []
    let l:locks = get(g:, 'chopsticks_plugin_locks', {})
    let l:active = []
    let l:missing_locks = []
    let l:unlocked = []
    let l:missing_installs = []

    for l:name in l:declared
        let l:spec = get(g:plugs, l:name, {})
        let l:locked_commit = get(l:locks, l:name, '')
        let l:declared_commit = get(l:spec, 'commit', '')
        let l:installed = ChopsticksPluginInstalled(l:name)
        call add(l:active, {
            \ 'name': l:name,
            \ 'dir': get(l:spec, 'dir', ''),
            \ 'locked_commit': l:locked_commit,
            \ 'declared_commit': l:declared_commit,
            \ 'locked': !empty(l:locked_commit),
            \ 'pinned': !empty(l:declared_commit),
            \ 'installed': l:installed,
            \ })
        if empty(l:locked_commit)
            call add(l:missing_locks, l:name)
        endif
        if empty(l:declared_commit)
            call add(l:unlocked, l:name)
        endif
        if !l:installed
            call add(l:missing_installs, l:name)
        endif
    endfor

    let l:pinning_enabled = get(g:, 'chopsticks_pin_plugins', 1)
    let l:all_active_locked = empty(l:missing_locks)
    let l:all_active_pinned = empty(l:unlocked)
    let l:all_active_installed = empty(l:missing_installs)

    let l:details = [
        \ ChopsticksInfoDetail('mode', l:pinning_enabled ? 'pinned' : 'unpinned'),
        \ ChopsticksInfoDetail('declared',
        \     len(l:declared) . ' active, ' . len(l:locks) . ' locked'),
        \ ]

    if l:all_active_locked
        let l:lock_item = ChopsticksInfoItem('lock coverage', 'ready',
            \ 'all active plugins locked', {
            \   'diagnostic': 0,
            \   'severity': 'attention',
            \   'detail': 'active plugin without lock: ',
            \   'action': 'add verified commits to g:chopsticks_plugin_locks',
            \   'issue_label': 'plugin locks',
            \ })
    else
        let l:lock_item = ChopsticksInfoDiagnosticItem('lock coverage',
            \ 'missing', 'missing: ' . join(l:missing_locks, ', '),
            \ 'plugin locks',
            \ 'add verified commits to g:chopsticks_plugin_locks', {
            \   'detail': 'active plugin without lock: '
            \       . join(l:missing_locks, ', '),
            \ })
    endif

    let l:items = [l:lock_item]

    if !l:pinning_enabled
        call add(l:items, ChopsticksInfoItem('applied pins', 'off',
            \ 'disabled for update testing', {
            \   'diagnostic': 0,
            \ }))
    elseif l:all_active_pinned
        call add(l:items, ChopsticksInfoItem('applied pins', 'ready',
            \ 'all active plugins pinned', {
            \   'diagnostic': 0,
            \   'severity': 'attention',
            \   'detail': 'active plugin declared without commit: ',
            \   'action': 'use ChopsticksLockedPlugOpts() for every Plug',
            \   'issue_label': 'plugin pinning',
            \ }))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('applied pins',
            \ 'missing', 'missing: ' . join(l:unlocked, ', '),
            \ 'plugin pinning',
            \ 'use ChopsticksLockedPlugOpts() for every Plug', {
            \   'detail': 'active plugin declared without commit: '
            \       . join(l:unlocked, ', '),
            \ }))
    endif

    if l:all_active_installed
        call add(l:items, ChopsticksInfoItem('installed plugins', 'ready',
            \ 'all active plugin dirs exist', {
            \   'diagnostic': 0,
            \   'severity': 'setup',
            \   'detail': 'missing plugin dirs: ',
            \   'action': ':PlugInstall',
            \   'issue_label': 'plugin install',
            \ }))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('installed plugins',
            \ 'missing', 'missing: ' . join(l:missing_installs, ', '),
            \ 'plugin install', ':PlugInstall', {
            \   'severity': 'setup',
            \   'detail': 'missing plugin dirs: '
            \       . join(l:missing_installs, ', '),
            \ }))
    endif

    return ChopsticksInfoSection('plugin reproducibility', {
        \ 'pinning_enabled': l:pinning_enabled,
        \ 'declared_count': len(l:declared),
        \ 'lock_count': len(l:locks),
        \ 'active': l:active,
        \ 'missing_locks': l:missing_locks,
        \ 'unlocked': l:unlocked,
        \ 'missing_installs': l:missing_installs,
        \ 'all_active_locked': l:all_active_locked,
        \ 'all_active_pinned': l:all_active_pinned,
        \ 'all_active_installed': l:all_active_installed,
        \ 'details': l:details,
        \ 'items': l:items,
        \ })
endfunction
