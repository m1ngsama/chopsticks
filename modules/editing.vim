" editing.vim — EasyMotion, yank highlight, search auto-clear, undotree

" ── EasyMotion ──────────────────────────────────────────────────────────────

let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase  = 1

if exists('g:plugs["vim-easymotion"]')
    nmap s <Plug>(easymotion-overwin-f2)
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
        call timer_start(150, {-> matchdelete(l:m)})
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
