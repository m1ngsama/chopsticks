" editing.vim — EasyMotion, yank highlight, search auto-clear, undotree

" ── EasyMotion ──────────────────────────────────────────────────────────────

let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase  = 1

if exists('g:plugs["vim-easymotion"]')
    nmap <Leader>S <Plug>(easymotion-overwin-f2)
    nmap <Leader>j <Plug>(easymotion-j)
    nmap <Leader>k <Plug>(easymotion-k)
endif

" ── UndoTree ────────────────────────────────────────────────────────────────

if exists('g:plugs["undotree"]')
    nnoremap <F5>       :UndotreeToggle<CR>
    nnoremap <leader>u  :UndotreeToggle<CR>
endif

" ── Yank Highlight ──────────────────────────────────────────────────────────

if exists('##TextYankPost') && has('timers')
    function! s:YankHighlight() abort
        if v:event.operator !=# 'y' | return | endif
        let l:m = matchadd('IncSearch',
            \ printf('\%%>%dl\%%<%dl', line("'[") - 1, line("']") + 1))
        call timer_start(150, {-> execute('silent! call matchdelete(' . l:m . ')')})
    endfunction
    augroup ChopstickYankHL
        autocmd!
        autocmd TextYankPost * call s:YankHighlight()
    augroup END
endif

" ── Blank Line Insertion (replaces vim-unimpaired) ──────────────────────────

nnoremap <silent> [<Space> :<C-u>put! =repeat(nr2char(10), v:count1)<CR>'[
nnoremap <silent> ]<Space> :<C-u>put  =repeat(nr2char(10), v:count1)<CR>

" ── Auto-Clear Search Highlight ─────────────────────────────────────────────

augroup ChopstickSearchHL
    autocmd!
    autocmd CursorHold * if get(v:, 'hlsearch', 0) | let v:hlsearch = 0 | endif
augroup END

" ── Overlength Highlight (only chars past textwidth, not the whole column) ─

function! s:OverLengthApply() abort
    if exists('w:overlength_match')
        silent! call matchdelete(w:overlength_match)
        unlet w:overlength_match
    endif
    if &textwidth <= 0 || &buftype !=# '' | return | endif
    let w:overlength_match = matchadd('OverLength', '\%>' . &textwidth . 'v.\+', -1)
endfunction

function! s:OverLengthDefineHL() abort
    hi default OverLength ctermbg=52 ctermfg=NONE guibg=#3a1f1f guifg=NONE
endfunction

augroup ChopstickOverLength
    autocmd!
    autocmd ColorScheme    * call s:OverLengthDefineHL()
    autocmd OptionSet      textwidth call s:OverLengthApply()
    autocmd BufWinEnter,WinEnter,FileType * call s:OverLengthApply()
augroup END
call s:OverLengthDefineHL()
