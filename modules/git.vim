" git.vim — Fugitive mappings, GitGutter config, conflict navigation

" ── GitGutter ───────────────────────────────────────────────────────────────

let g:gitgutter_sign_added            = '+'
let g:gitgutter_sign_modified         = '~'
let g:gitgutter_sign_removed          = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '~'

" ── Fugitive ────────────────────────────────────────────────────────────────

if exists('g:plugs["vim-fugitive"]')
    nnoremap <leader>gs :Git status<CR>
    nnoremap <leader>gc :Git commit<CR>
    nnoremap <leader>gp :Git push<CR>
    nnoremap <leader>gl :Git pull<CR>
    nnoremap <leader>gd :Gdiffsplit<CR>
    nnoremap <leader>gb :Git blame<CR>
endif

" ── Conflict Navigation ────────────────────────────────────────────────────

nnoremap <silent> ]x /^\(<<<<<<<\\|=======\\|>>>>>>>\)<CR>
nnoremap <silent> [x ?^\(<<<<<<<\\|=======\\|>>>>>>>\)<CR>
