" lsp.vim — vim-lsp settings, asyncomplete, LSP buffer keymaps

function! s:CompletionOff(label) abort
    return ChopsticksInfoItem(a:label, 'off', 'LSP disabled by profile',
        \ {'diagnostic': 0})
endfunction

function! s:CompletionPluginItem(label, plugin) abort
    if !get(g:, 'chopsticks_enable_lsp', 1)
        return s:CompletionOff(a:label)
    endif
    if !ChopsticksPluginDeclared(a:plugin)
        return ChopsticksInfoDiagnosticItem(a:label, 'missing',
            \ 'not declared by profile', a:label,
            \ 'check g:chopsticks_enable_lsp and plugin profile', {
            \   'detail': a:plugin . ' is not declared by the active profile',
            \   'severity': 'setup',
            \ })
    endif
    if !ChopsticksPluginInstalled(a:plugin)
        return ChopsticksInfoDiagnosticItem(a:label, 'missing',
            \ 'not installed; run :PlugInstall', a:label,
            \ ':PlugInstall', {
            \   'detail': a:plugin . ' is declared but not installed',
            \   'severity': 'setup',
            \ })
    endif
    return ChopsticksInfoItem(a:label, 'ready', a:plugin,
        \ {'diagnostic': 0})
endfunction

function! s:RequiredCompleteOpt() abort
    let l:required = ['menuone', 'noinsert', 'noselect']
    if ChopsticksRuntimeFeatureAvailable('popup')
        call add(l:required, 'popup')
    endif
    return l:required
endfunction

function! s:MissingCompleteOpt() abort
    let l:opts = split(&completeopt, ',')
    let l:missing = []
    for l:opt in s:RequiredCompleteOpt()
        if index(l:opts, l:opt) < 0
            call add(l:missing, l:opt)
        endif
    endfor
    return l:missing
endfunction

function! s:PopupMenuItem() abort
    if !get(g:, 'chopsticks_enable_lsp', 1)
        return s:CompletionOff('popup menu')
    endif

    let l:missing = s:MissingCompleteOpt()
    if !empty(l:missing)
        return ChopsticksInfoDiagnosticItem('popup menu', 'missing',
            \ 'missing: ' . join(l:missing, ', '), 'popup menu',
            \ 'reload chopsticks or review local completeopt', {
            \   'detail': 'completeopt missing: ' . join(l:missing, ', '),
            \ })
    endif
    if &pumheight != 15
        return ChopsticksInfoDiagnosticItem('popup menu', 'missing',
            \ 'pumheight=' . &pumheight, 'popup menu',
            \ 'reload chopsticks or review local pumheight', {
            \   'detail': 'expected pumheight=15, found ' . &pumheight,
            \ })
    endif
    return ChopsticksInfoItem('popup menu', 'ready',
        \ &completeopt . '; pumheight=' . &pumheight, {'diagnostic': 0})
endfunction

function! s:AutoPopupItem() abort
    if !get(g:, 'chopsticks_enable_lsp', 1)
        return s:CompletionOff('auto popup')
    endif

    if !get(g:, 'asyncomplete_auto_popup', 0)
        return ChopsticksInfoDiagnosticItem('auto popup', 'missing',
            \ 'disabled', 'auto popup',
            \ 'reload chopsticks or set g:asyncomplete_auto_popup = 1', {
            \   'detail': 'asyncomplete auto popup is disabled',
            \ })
    endif
    if get(g:, 'asyncomplete_auto_completeopt', 1)
        return ChopsticksInfoDiagnosticItem('auto popup', 'missing',
            \ 'asyncomplete owns completeopt', 'auto popup',
            \ 'reload chopsticks or review asyncomplete settings', {
            \   'detail': 'expected g:asyncomplete_auto_completeopt = 0',
            \ })
    endif
    if get(g:, 'asyncomplete_popup_delay', -1) != 50
        return ChopsticksInfoDiagnosticItem('auto popup', 'missing',
            \ 'delay=' . get(g:, 'asyncomplete_popup_delay', 'unset'),
            \ 'auto popup',
            \ 'reload chopsticks or review asyncomplete settings', {
            \   'detail': 'expected popup delay=50',
            \ })
    endif
    return ChopsticksInfoItem('auto popup', 'ready', 'delay=50',
        \ {'diagnostic': 0})
endfunction

function! s:FallbackCompletionMapSpecs() abort
    let l:auto_pairs = get(g:, 'chopsticks_enable_auto_pairs', 0)
        \ && exists('g:AutoPairsLoaded')
    let l:specs = [
        \ {'kind': 'map', 'mode': 'i', 'lhs': '<Tab>',
        \  'text': 'pumvisible', 'key': '<Tab>', 'display_key': 'Tab'},
        \ {'kind': 'map', 'mode': 'i', 'lhs': '<S-Tab>',
        \  'text': 'pumvisible', 'key': '<S-Tab>',
        \  'display_key': 'S-Tab'},
        \ ]
    if l:auto_pairs
        call add(l:specs, {
            \ 'kind': 'auto_pairs_map',
            \ 'lhs': '<CR>',
            \ 'text': 'AutoPairsReturn',
            \ 'key': '<CR> auto-pairs',
            \ 'display_key': 'CR',
            \ })
        call add(l:specs, {
            \ 'kind': 'map',
            \ 'mode': 'i',
            \ 'lhs': '<CR>',
            \ 'text': 'AutoPairsOldCRWrapper',
            \ 'key': '<CR> completion wrapper',
            \ 'display_key': 'CR',
            \ })
    else
        call add(l:specs, {
            \ 'kind': 'map',
            \ 'mode': 'i',
            \ 'lhs': '<CR>',
            \ 'text': 'asyncomplete#close_popup',
            \ 'key': '<CR>',
            \ 'display_key': 'CR',
            \ })
    endif
    return l:specs
endfunction

function! s:FallbackCompletionKeys() abort
    return ['Tab', 'S-Tab', 'CR']
endfunction

function! s:CompletionMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('completion_keymaps',
        \ s:FallbackCompletionMapSpecs())
endfunction

function! s:LspMapSpec(mode, lhs, rhs, display_key) abort
    return {
        \ 'kind': 'map',
        \ 'mode': a:mode,
        \ 'lhs': a:lhs,
        \ 'rhs': a:rhs,
        \ 'text': a:rhs,
        \ 'display_key': a:display_key,
        \ 'map_command': a:mode ==# 'x' ? 'xmap' : 'nmap',
        \ }
endfunction

function! s:FallbackLspBufferMapSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ s:LspMapSpec('n', 'gd', '<plug>(lsp-definition)', 'gd'),
            \ s:LspMapSpec('n', 'gr', '<plug>(lsp-references)', 'gr'),
            \ s:LspMapSpec('n', 'gI', '<plug>(lsp-implementation)', 'gI'),
            \ s:LspMapSpec('n', 'gy', '<plug>(lsp-type-definition)', 'gy'),
            \ s:LspMapSpec('n', 'K', '<plug>(lsp-hover)', 'K'),
            \ s:LspMapSpec('n', '[d', '<plug>(lsp-previous-diagnostic)', '[d'),
            \ s:LspMapSpec('n', ']d', '<plug>(lsp-next-diagnostic)', ']d'),
            \ s:LspMapSpec('n', '<Space>ca', '<plug>(lsp-code-action)', 'SPC ca'),
            \ s:LspMapSpec('n', '<Space>cr', '<plug>(lsp-rename)', 'SPC cr'),
            \ s:LspMapSpec('n', '<Space>cf',
            \   '<plug>(lsp-document-format)', 'SPC cf'),
            \ s:LspMapSpec('x', '<Space>cf',
            \   '<plug>(lsp-document-range-format)', 'v SPC cf'),
            \ extend(s:LspMapSpec('n', '<Space>ci',
            \   ':LspStatus<CR>', 'SPC ci'), {'map_command': 'nnoremap'}),
            \ s:LspMapSpec('n', '<Space>co',
            \   '<plug>(lsp-document-symbol-search)', 'SPC co'),
            \ s:LspMapSpec('n', '<Space>cS',
            \   '<plug>(lsp-workspace-symbol-search)', 'SPC cS'),
            \ ]
    endif

    return [
        \ s:LspMapSpec('n', ',dd', '<plug>(lsp-definition)', ',dd'),
        \ s:LspMapSpec('n', ',dt', '<plug>(lsp-type-definition)', ',dt'),
        \ s:LspMapSpec('n', ',di', '<plug>(lsp-implementation)', ',di'),
        \ s:LspMapSpec('n', ',dr', '<plug>(lsp-references)', ',dr'),
        \ s:LspMapSpec('n', ',dp', '<plug>(lsp-previous-diagnostic)', ',dp'),
        \ s:LspMapSpec('n', ',dn', '<plug>(lsp-next-diagnostic)', ',dn'),
        \ s:LspMapSpec('n', ',dk', '<plug>(lsp-hover)', ',dk'),
        \ s:LspMapSpec('n', ',rn', '<plug>(lsp-rename)', ',rn'),
        \ s:LspMapSpec('n', ',ca', '<plug>(lsp-code-action)', ',ca'),
        \ s:LspMapSpec('n', ',f', '<plug>(lsp-document-format)', ',f'),
        \ s:LspMapSpec('x', ',f', '<plug>(lsp-document-range-format)', 'v ,f'),
        \ s:LspMapSpec('n', ',o', '<plug>(lsp-document-symbol-search)', ',o'),
        \ s:LspMapSpec('n', ',ws',
        \   '<plug>(lsp-workspace-symbol-search)', ',ws'),
        \ s:LspMapSpec('n', ',cD', '<plug>(lsp-document-diagnostics)', ',cD'),
        \ ]
endfunction

function! s:LspBufferMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('lsp_buffer_keymaps',
        \ s:FallbackLspBufferMapSpecs())
endfunction

function! s:ApplyLspMapSpec(spec) abort
    let l:mode = get(a:spec, 'mode', 'n')
    let l:cmd = get(a:spec, 'map_command', l:mode ==# 'x' ? 'xmap' : 'nmap')
    let l:rhs = get(a:spec, 'rhs', get(a:spec, 'text', ''))
    if empty(get(a:spec, 'lhs', '')) || empty(l:rhs)
        return
    endif
    execute l:cmd . ' <buffer> ' . get(a:spec, 'lhs', '') . ' ' . l:rhs
endfunction

function! s:Unique(values) abort
    let l:seen = {}
    let l:unique = []
    for l:value in a:values
        if has_key(l:seen, l:value)
            continue
        endif
        let l:seen[l:value] = 1
        call add(l:unique, l:value)
    endfor
    return l:unique
endfunction

function! s:CompletionKey() abort
    let l:keys = s:Unique(ChopsticksKeymapContractKeysOr('completion_keymaps',
        \ s:FallbackCompletionKeys()))
    return join(l:keys, '/')
endfunction

function! s:CompletionKeymapMissing() abort
    return ChopsticksKeymapMissingKeys(s:CompletionMapSpecs())
endfunction

function! s:CompletionKeymapsItem() abort
    if !get(g:, 'chopsticks_enable_lsp', 1)
        return s:CompletionOff('completion keymaps')
    endif
    if !get(g:, 'chopsticks_enable_completion_keymaps', 0)
        return ChopsticksInfoItem('completion keymaps', 'off',
            \ 'disabled by default', {'diagnostic': 0})
    endif

    let l:missing = s:CompletionKeymapMissing()
    if empty(l:missing)
        let l:reason = s:CompletionKey()
        let l:reason .= get(g:, 'chopsticks_enable_auto_pairs', 0)
            \ && exists('g:AutoPairsLoaded')
            \ ? '(auto-pairs)'
            \ : ''
        return ChopsticksInfoItem('completion keymaps', 'ready', l:reason,
            \ {'diagnostic': 0})
    endif

    return ChopsticksInfoDiagnosticItem('completion keymaps', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'completion keymaps',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'missing insert-mode completion maps: '
        \       . join(l:missing, ', '),
        \ })
endfunction

function! s:ServerSpecs() abort
    return [
        \ {'ft': 'python', 'server': 'pylsp', 'enabled': 1, 'reason': ''},
        \ {'ft': 'go', 'server': 'gopls', 'enabled': 1, 'reason': ''},
        \ {'ft': 'rust', 'server': 'rust-analyzer', 'enabled': 1, 'reason': ''},
        \ {'ft': 'typescript', 'server': 'typescript-language-server',
        \  'enabled': 1, 'reason': ''},
        \ {'ft': 'c/c++', 'server': 'clangd', 'enabled': 1, 'reason': ''},
        \ {'ft': 'bash', 'server': 'bash-language-server', 'enabled': 1,
        \  'reason': ''},
        \ {'ft': 'html', 'server': 'vscode-html-language-server',
        \  'enabled': 1, 'reason': ''},
        \ {'ft': 'json', 'server': 'vscode-json-language-server',
        \  'enabled': 1, 'reason': ''},
        \ {'ft': 'yaml', 'server': 'yaml-language-server', 'enabled': 1,
        \  'reason': ''},
        \ {'ft': 'markdown', 'server': 'marksman',
        \  'enabled': get(g:, 'chopsticks_markdown_lsp', 0),
        \  'reason': 'disabled by default'},
        \ {'ft': 'sql', 'server': 'sqls', 'enabled': 1, 'reason': ''},
        \ ]
endfunction

function! s:StackItem(state, reason) abort
    return ChopsticksInfoItem('vim-lsp stack', a:state, a:reason, {
        \ 'kind': 'stack',
        \ 'detail': a:reason,
        \ 'severity': 'setup',
        \ 'action': ':PlugInstall',
        \ 'diagnostic': a:state ==# 'missing',
        \ })
endfunction

function! s:StackState() abort
    if !get(g:, 'chopsticks_enable_lsp', 1)
        return s:StackItem('off', 'LSP disabled by profile')
    endif
    if !ChopsticksPluginDeclared('vim-lsp')
        return s:StackItem('missing', 'vim-lsp not declared by this profile')
    endif
    if !ChopsticksPluginInstalled('vim-lsp')
        return s:StackItem('missing', 'vim-lsp not installed; run :PlugInstall')
    endif
    if !ChopsticksPluginDeclared('vim-lsp-settings')
        return s:StackItem('missing',
            \ 'vim-lsp-settings not declared by this profile')
    endif
    if !ChopsticksPluginInstalled('vim-lsp-settings')
        return s:StackItem('missing',
            \ 'vim-lsp-settings not installed; run :PlugInstall')
    endif
    if ChopsticksCommandAvailable('LspStatus')
        \ || ChopsticksCommandAvailable('LspInstallServer')
        return s:StackItem('ready', 'installed')
    endif
    return s:StackItem('ready', 'installed; not loaded yet')
endfunction

function! s:LspServerItem(spec, state, reason, diagnostic) abort
    let l:label = get(a:spec, 'ft', 'server')
    let l:item = ChopsticksInfoItem(l:label, a:state, a:reason, {
        \ 'kind': 'server',
        \ 'severity': 'optional',
        \ 'action': ':LspInstallServer',
        \ 'issue_label': l:label . ' language server',
        \ 'diagnostic': a:diagnostic,
        \ 'detail': a:reason,
        \ })
    call extend(l:item, copy(a:spec), 'keep')
    return l:item
endfunction

function! s:ServerState(spec, stack) abort
    if a:stack.state ==# 'off'
        return s:LspServerItem(a:spec, 'off', a:stack.reason, 0)
    endif
    if a:stack.state !=# 'ready'
        return s:LspServerItem(a:spec, 'missing', a:stack.reason, 0)
    endif
    if !get(a:spec, 'enabled', 1)
        return s:LspServerItem(a:spec, 'off',
            \ get(a:spec, 'reason', 'disabled'), 0)
    endif

    let l:dir = expand('~/.local/share/vim-lsp-settings/servers/' . a:spec.server)
    if isdirectory(l:dir)
        let l:server = s:LspServerItem(a:spec, 'ready', a:spec.server, 0)
    else
        let l:server = s:LspServerItem(a:spec, 'missing',
            \ ':LspInstallServer in a ' . a:spec.ft . ' file', 1)
    endif
    let l:server.dir = l:dir
    return l:server
endfunction

function! ChopsticksLspInfo() abort
    let l:stack = s:StackState()
    let l:servers = []
    for l:spec in s:ServerSpecs()
        call add(l:servers, s:ServerState(l:spec, l:stack))
    endfor
    let l:items = [copy(l:stack)]
    call extend(l:items, copy(l:servers))
    let l:enabled = get(g:, 'chopsticks_enable_lsp', 1)
    return ChopsticksInfoSection('lsp servers', {
        \ 'enabled': l:enabled,
        \ 'suffix': ':LspInstallServer to install',
        \ 'stack': l:stack,
        \ 'servers': l:servers,
        \ 'items': l:items,
        \ 'notes': l:enabled ? [
        \   'LSP actions are buffer-local and start after a server attaches.',
        \   'Missing one? Open that filetype and run :LspInstallServer once.',
        \ ] : [],
        \ 'footers': l:enabled ? [
        \   'Install LSP servers with :LspInstallServer',
        \ ] : [],
        \ 'commands_loaded': ChopsticksCommandAvailable('LspStatus')
        \     || ChopsticksCommandAvailable('LspInstallServer'),
        \ 'current_filetype': &filetype,
        \ 'markdown_lsp': get(g:, 'chopsticks_markdown_lsp', 0),
        \ })
endfunction

function! ChopsticksLspLearningEnabled() abort
    return s:StackState().state !=# 'off'
endfunction

function! ChopsticksCompletionInfo() abort
    let l:enabled = get(g:, 'chopsticks_enable_lsp', 1)
    let l:keymaps = l:enabled
        \ && get(g:, 'chopsticks_enable_completion_keymaps', 0)
    return ChopsticksInfoSection('completion', {
        \ 'details': [
        \   ChopsticksInfoDetail('engine',
        \       l:enabled ? 'asyncomplete' : 'disabled'),
        \   ChopsticksInfoDetail('source',
        \       l:enabled ? 'vim-lsp' : 'disabled'),
        \   ChopsticksInfoDetail('keys', l:keymaps ? 'opt-in' : 'off'),
        \ ],
        \ 'items': [
        \   s:CompletionPluginItem('completion engine', 'asyncomplete.vim'),
        \   s:CompletionPluginItem(
        \       'vim-lsp completion source', 'asyncomplete-lsp.vim'),
        \   s:AutoPopupItem(),
        \   s:PopupMenuItem(),
        \   s:CompletionKeymapsItem(),
        \ ],
        \ })
endfunction

if !g:chopsticks_enable_lsp
    finish
endif

let g:lsp_settings_lazyload = 1

let g:lsp_settings_filetype_python     = ['pylsp']
let g:lsp_settings_filetype_go         = ['gopls']
let g:lsp_settings_filetype_rust       = ['rust-analyzer']
let g:lsp_settings_filetype_typescript = ['typescript-language-server']
let g:lsp_settings_filetype_javascript = ['typescript-language-server']
let g:lsp_settings_filetype_c          = ['clangd']
let g:lsp_settings_filetype_sh         = ['bash-language-server']
let g:lsp_settings_filetype_html       = ['vscode-html-language-server']
let g:lsp_settings_filetype_css        = ['vscode-css-language-server']
let g:lsp_settings_filetype_scss       = ['vscode-css-language-server']
let g:lsp_settings_filetype_json       = ['vscode-json-language-server']
let g:lsp_settings_filetype_yaml       = ['yaml-language-server']
let g:lsp_settings_filetype_sql        = ['sqls']

if g:chopsticks_markdown_lsp
    let g:lsp_settings_filetype_markdown = ['marksman']
endif

let g:lsp_diagnostics_virtual_text_enabled = g:chopsticks_lsp_virtual_text
let g:lsp_diagnostics_virtual_text_delay   = 200
let g:lsp_diagnostics_highlights_enabled   = !g:is_tty
let g:lsp_document_highlight_enabled       = !g:is_tty
let g:lsp_document_highlight_delay         = 200
let g:lsp_signs_enabled                    = 1
let g:lsp_diagnostics_echo_cursor          = 1
let g:lsp_diagnostics_echo_delay           = 100
let g:lsp_completion_documentation_enabled = 1

let g:lsp_signs_error       = {'text': 'X'}
let g:lsp_signs_warning     = {'text': '!'}
let g:lsp_signs_information = {'text': 'i'}
let g:lsp_signs_hint        = {'text': '>'}

" ── Completion ──────────────────────────────────────────────────────────────

if ChopsticksRuntimeFeatureAvailable('popup')
    set completeopt=menuone,noinsert,noselect,popup
else
    set completeopt=menuone,noinsert,noselect
endif
set pumheight=15
let g:asyncomplete_auto_popup       = 1
let g:asyncomplete_auto_completeopt = 0
let g:asyncomplete_popup_delay      = 50

if get(g:, 'chopsticks_enable_completion_keymaps', 0)
    inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"
endif

" ── Buffer Keymaps ──────────────────────────────────────────────────────────

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    if !g:is_tty && &filetype !=# 'markdown'
        setlocal signcolumn=yes
    endif

    for l:spec in s:LspBufferMapSpecs()
        call s:ApplyLspMapSpec(l:spec)
    endfor
endfunction

augroup lsp_install
    autocmd!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
