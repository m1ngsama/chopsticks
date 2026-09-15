vim9script

import autoload 'chopsticks/ui/window.vim'
import autoload 'chopsticks/keys.vim'
import autoload 'chopsticks/ui/bufferline.vim'

export def ToggleConceal()
  &l:conceallevel = &l:conceallevel == 0 ? 2 : 0
  echo 'Markdown conceal: ' .. (&l:conceallevel != 0 ? 'ON' : 'OFF')
enddef

export def Glow()
  if executable('glow') != 1
    echohl WarningMsg
    echomsg 'chopsticks: install glow for terminal Markdown preview'
    echohl None
    return
  endif
  if empty(expand('%:p'))
    echohl WarningMsg
    echomsg 'chopsticks: save the Markdown file before previewing it'
    echohl None
    return
  endif
  silent update
  window.Terminal(['glow', '-p', expand('%:p')], 'split')
enddef

export def PasteImage(requested_name: string)
  if executable('pngpaste') != 1
    echohl WarningMsg
    echomsg 'chopsticks: Markdown image paste needs pngpaste (brew install pngpaste)'
    echohl None
    return
  endif
  if empty(expand('%:p'))
    echohl WarningMsg
    echomsg 'chopsticks: save the Markdown file before pasting an image'
    echohl None
    return
  endif
  var name = empty(requested_name)
    ? 'image-' .. strftime('%Y%m%d-%H%M%S') : requested_name
  name = substitute(name, '[/\\:[:cntrl:]]', '-', 'g')
  if name !~? '\.png$'
    name ..= '.png'
  endif
  var relative_dir = 'assets'
  var absolute_dir = expand('%:p:h') .. '/' .. relative_dir
  var absolute_path = absolute_dir .. '/' .. name
  if filereadable(absolute_path)
    echohl ErrorMsg
    echomsg 'chopsticks: image already exists: ' .. absolute_path
    echohl None
    return
  endif
  mkdir(absolute_dir, 'p')
  system(shellescape(exepath('pngpaste')) .. ' ' .. shellescape(absolute_path))
  if v:shell_error != 0 || !filereadable(absolute_path)
    silent! delete(absolute_path)
    echohl ErrorMsg
    echomsg 'chopsticks: clipboard does not contain a PNG image'
    echohl None
    return
  endif
  var alt = fnamemodify(name, ':r')
  var link = '![' .. alt .. '](' .. relative_dir .. '/' .. name .. ')'
  if empty(getline('.'))
    setline('.', link)
  else
    append('.', link)
    normal! j
  endif
  echo 'saved: ' .. relative_dir .. '/' .. name
enddef

export def Help()
  var sheet = [
    'chopsticks Markdown',
    '',
    ', = Markdown LocalLeader   * = only in a Markdown buffer',
    'j k Ctrl-d gg G move · / searches · CR presses the key · q closes.',
  ]
  sheet->extend(keys.Sheet(keys.MARKDOWN_GROUPS))
  window.Scratch('[chopsticks-markdown]', sheet, 'chopsticks-cheatsheet')
enddef

const THRESHOLD = 4096

def HasLongLine(): bool
  var lines = line('$')
  if lines <= 0
    return false
  endif
  var bytes = line2byte(lines + 1)
  if bytes > 0 && bytes / lines > THRESHOLD
    return true
  endif
  if lines > 2000
    return false
  endif
  return max(mapnew(range(1, lines), (_, l) => col([l, '$']))) > THRESHOLD
enddef

export def GuardLongLines()
  if !exists('+breakindent')
    return
  endif
  if HasLongLine()
    setlocal nobreakindent
  endif
enddef

export def Setup()
  setlocal wrap linebreak breakindent textwidth=0 colorcolumn=0
  setlocal norelativenumber nolist signcolumn=auto foldlevel=99
  setlocal spell spelllang=en_us,cjk
  if exists(':Pencil') == 2
    pencil#init({wrap: 'soft'})
  endif
  setlocal conceallevel=0

  if !empty(maparg('<Plug>(bullets-newline)', 'i'))
    imap <silent><buffer> <CR> <Plug>(bullets-newline)
    nmap <silent><buffer> o <Plug>(bullets-newline)
    nmap <silent><buffer> gN <Plug>(bullets-renumber)
    xmap <silent><buffer> gN <Plug>(bullets-renumber)
    nmap <silent><buffer> <localleader>x <Plug>(bullets-toggle-checkbox)
  endif
  if exists(':Toc') == 2
    nnoremap <silent><buffer> <localleader>o :Toc<CR>
    nnoremap <silent><buffer> <localleader>O :InsertToc 3<CR>
  endif
  if exists(':TableModeToggle') == 2
    nnoremap <silent><buffer> <localleader>tt :TableModeToggle<CR>
    nnoremap <silent><buffer> <localleader>tr :TableModeRealign<CR>
    xnoremap <silent><buffer> <localleader>tc :Tableize<CR>
  endif
  if exists(':PrevimOpen') == 2
    nnoremap <silent><buffer> <localleader>p :PrevimOpen<CR>
  endif
  if exists(':Goyo') == 2
    nnoremap <silent><buffer> <localleader>z :Goyo<CR>
  endif
  nnoremap <silent><buffer> <localleader>? <ScriptCmd>Help()<CR>
  nnoremap <silent><buffer> <localleader>s :setlocal spell! spell?<CR>
  nnoremap <silent><buffer> <localleader>c <ScriptCmd>ToggleConceal()<CR>
  nnoremap <silent><buffer> <localleader>g <ScriptCmd>Glow()<CR>
  nnoremap <silent><buffer> <localleader>i :MdPaste<CR>
  if exists(':WhichKey') == 2
    nnoremap <silent><buffer> <localleader> :<C-u>WhichKey ','<CR>
    xnoremap <silent><buffer> <localleader> :<C-u>WhichKeyVisual ','<CR>
  endif
  if exists(':ALELint') == 2
    nnoremap <silent><buffer> <localleader>l :ALELint<CR>
    nnoremap <silent><buffer> <localleader>f :ALEFix<CR>
  endif
  GuardLongLines()
enddef

export def ProseSetup()
  setlocal wrap linebreak breakindent textwidth=0 colorcolumn=0
  setlocal norelativenumber
  if exists(':Pencil') == 2
    pencil#init({wrap: 'soft'})
  endif
  if &filetype ==# 'gitcommit' || &filetype ==# 'mail'
    setlocal spell spelllang=en_us,cjk
  endif
  GuardLongLines()
enddef

export def GoyoEnter()
  if &filetype =~# '^\%(markdown\|text\|gitcommit\)$' && exists(':Limelight') == 2
    silent execute 'Limelight'
  endif
  setlocal wrap linebreak
  bufferline.Refresh()
enddef

export def GoyoLeave()
  if exists(':Limelight') == 2
    silent! execute 'Limelight!'
  endif
  bufferline.Refresh()
enddef
