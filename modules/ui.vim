" ui.vim — colorscheme, statusline, startify

" ── Colorscheme (Solarized Dark — matches tmux palette) ────────────────────

if g:has_true_color && has('termguicolors') && !g:is_tty
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

set background=dark

if !g:is_tty
    try
        colorscheme solarized8
    catch
        colorscheme default
    endtry
else
    colorscheme default
endif

if has("gui_running")
    if has("gui_gtk2") || has("gui_gtk3")
        set guifont=Hack\ 12,Source\ Code\ Pro\ 12,Monospace\ 12
    elseif has("gui_win32")
        set guifont=Consolas:h11:cANSI
    endif
endif

" ── Startify ────────────────────────────────────────────────────────────────

if exists('g:plugs["vim-startify"]')
    let g:startify_lists = [
        \ { 'type': 'sessions',  'header': ['   Sessions']     },
        \ { 'type': 'files',     'header': ['   Recent Files'] },
        \ { 'type': 'dir',       'header': ['   Current Dir']  },
        \ ]

    let g:startify_bookmarks          = [{'v': '~/.vimrc'}]
    let g:startify_session_persistence = 1
    let g:startify_session_autoload    = 1
    let g:startify_change_to_vcs_root  = 1
    let g:startify_fortune_use_unicode = 0
    let g:startify_enable_special      = 0
    let g:startify_files_number        = 8
    let g:startify_padding_left        = 4

    function! s:SetupDirView() abort
        if argc() != 1 || !isdirectory(argv()[0]) || exists('s:std_in')
            return
        endif
        let l:dir = fnameescape(argv()[0])
        execute 'cd ' . l:dir
        vertical rightbelow vnew
        if exists(':Startify') == 2
            Startify
        else
            enew
        endif
        wincmd h
        vertical resize 30
        setlocal winfixwidth
        wincmd l
    endfunction

    if !g:is_tty
        augroup ChopstickStartup
            autocmd!
            autocmd StdinReadPre * let s:std_in = 1
            autocmd VimEnter * nested call <SID>SetupDirView()
        augroup END
    endif

endif

" ── Status Line (native — Solarized palette, seamless with tmux bar) ───────

set laststatus=2
set noshowmode

function! s:SLDefineColors() abort
    hi SLNormal  ctermbg=136 ctermfg=234 cterm=bold guibg=#b58900 guifg=#002b36 gui=bold
    hi SLInsert  ctermbg=33  ctermfg=234 cterm=bold guibg=#268bd2 guifg=#002b36 gui=bold
    hi SLVisual  ctermbg=125 ctermfg=234 cterm=bold guibg=#d33682 guifg=#002b36 gui=bold
    hi SLReplace ctermbg=160 ctermfg=234 cterm=bold guibg=#dc322f guifg=#002b36 gui=bold
    hi SLCommand ctermbg=37  ctermfg=234 cterm=bold guibg=#2aa198 guifg=#002b36 gui=bold
    hi SLBody    ctermbg=235 ctermfg=245 cterm=none guibg=#073642 guifg=#93a1a1
    hi SLFlag    ctermbg=235 ctermfg=136 cterm=none guibg=#073642 guifg=#b58900
    hi SLRight   ctermbg=235 ctermfg=240 cterm=none guibg=#073642 guifg=#586e75
    hi SLGit     ctermbg=235 ctermfg=37  cterm=none guibg=#073642 guifg=#2aa198
    hi SLFtype   ctermbg=235 ctermfg=244 cterm=none guibg=#073642 guifg=#839496
endfunction

augroup SLColors
    autocmd!
    autocmd ColorScheme * call s:SLDefineColors()
augroup END
call s:SLDefineColors()

function! SLMode() abort
    let l:m = mode()
    if     l:m ==# 'n'                          | return [' N ', 'SLNormal' ]
    elseif l:m ==# 'i'                          | return [' I ', 'SLInsert' ]
    elseif l:m =~# '[vV]' || l:m ==# "\<C-v>"  | return [' V ', 'SLVisual' ]
    elseif l:m ==# 'R'                          | return [' R ', 'SLReplace']
    elseif l:m ==# 'c'                          | return [' C ', 'SLCommand']
    elseif l:m ==# 't'                          | return [' T ', 'SLInsert' ]
    else                                        | return [' ' . l:m . ' ', 'SLNormal']
    endif
endfunction

function! SLGit() abort
    if !exists('*FugitiveHead') | return '' | endif
    let l:b = FugitiveHead()
    return empty(l:b) ? '' : '  ' . l:b . ' '
endfunction

function! SLAle() abort
    if !exists('*ale#statusline#Count') | return '' | endif
    let l:c = ale#statusline#Count(bufnr(''))
    let l:e = l:c.error + l:c.style_error
    let l:w = l:c.warning + l:c.style_warning
    if l:e == 0 && l:w == 0 | return '' | endif
    return printf(' E:%d W:%d ', l:e, l:w)
endfunction

function! SLFlags() abort
    let l:f = ''
    if &paste | let l:f .= ' PASTE' | endif
    if &spell | let l:f .= ' SPELL' | endif
    return empty(l:f) ? '' : l:f . ' '
endfunction

function! SLBuild() abort
    let [l:label, l:hl] = SLMode()
    let l:s  = '%#' . l:hl . '#' . l:label
    let l:s .= '%#SLBody# %f '
    let l:s .= '%#SLFlag#%m%r'
    let l:s .= '%#SLFlag#' . SLFlags()
    let l:s .= '%#SLBody#%='
    let l:s .= '%#SLFlag#' . SLAle()
    let l:s .= '%#SLGit#'  . SLGit()
    let l:s .= '%#SLFtype# %y '
    let l:s .= '%#SLRight# %l:%c  %P '
    return l:s
endfunction

set statusline=%!SLBuild()

if g:is_tty
    set statusline=%f\ %h%w%m%r\ %=%(%l,%c%V\ %=\ %P%)
endif
