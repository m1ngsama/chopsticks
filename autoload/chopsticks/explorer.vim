vim9script

var directory_startup_opened = false

def ExplorerWindow(): number
  for window in getwininfo()
    if window.tabnr == tabpagenr()
        && index(['fern', 'netrw'], getbufvar(window.bufnr, '&filetype')) >= 0
      return window.winid
    endif
  endfor
  return 0
enddef

export def FernAvailable(): bool
  return exists(':Fern') == 2
enddef

def PathInside(path_value: string, directory_value: string): bool
  var path = resolve(fnamemodify(path_value, ':p'))
  var directory = resolve(fnamemodify(directory_value, ':p'))
  path = substitute(path, '/\+$', '', '')
  directory = substitute(directory, '/\+$', '', '')
  return path ==# directory || stridx(path, directory .. '/') == 0
enddef

export def Toggle(directory_arg: string)
  if FernAvailable()
    var directory = fnamemodify(directory_arg, ':p')
    var command = 'Fern ' .. fnameescape(directory)
      .. ' -drawer -toggle -width=' .. g:fern#drawer_width
    var current = expand('%:p')
    if filereadable(current) && PathInside(current, directory)
      command ..= ' -reveal=' .. fnameescape(current)
    endif
    execute command
    return
  endif
  var explorer = ExplorerWindow()
  if explorer != 0
    var origin = win_getid()
    if win_gotoid(explorer)
      close
    endif
    if origin != explorer && win_id2win(origin) > 0
      win_gotoid(origin)
    endif
    return
  endif
  execute 'Lexplore ' .. fnameescape(directory_arg)
enddef

export def FernSetup()
  setlocal nonumber norelativenumber signcolumn=no winfixwidth cursorline
  nmap <buffer><silent><expr> <Plug>(chopsticks-fern-toggle-node)
    \ fern#smart#leaf(
    \ "\<Plug>(fern-action-open)",
    \ "\<Plug>(fern-action-expand:stay)",
    \ "\<Plug>(fern-action-collapse)")
  nmap <silent><buffer> <CR> <Plug>(chopsticks-fern-toggle-node)
  nmap <silent><buffer> l <Plug>(chopsticks-fern-toggle-node)
  nmap <buffer><silent><expr> <Plug>(chopsticks-fern-parent-or-collapse)
    \ fern#smart#leaf(
    \ "\<Plug>(fern-action-focus:parent)",
    \ "\<Plug>(fern-action-focus:parent)",
    \ "\<Plug>(fern-action-collapse)")
  nmap <silent><buffer> h <Plug>(chopsticks-fern-parent-or-collapse)
  nmap <silent><buffer> o <Plug>(fern-action-open)
  nmap <silent><buffer> s <Plug>(fern-action-open:split)
  nmap <silent><buffer> v <Plug>(fern-action-open:vsplit)
  nmap <silent><buffer> t <Plug>(fern-action-open:tabedit)
  nmap <silent><buffer> N <Plug>(fern-action-new-path)
  nmap <silent><buffer> r <Plug>(fern-action-rename)
  nmap <silent><buffer> x <Plug>(fern-action-mark:toggle)
  nmap <silent><buffer> . <Plug>(fern-action-hidden:toggle)
  nmap <silent><buffer> R <Plug>(fern-action-reload:all)
  nnoremap <silent><buffer> q :close<CR>
  nnoremap <silent><buffer> <Esc> :close<CR>
  try
    glyph_palette#apply()
  catch /^Vim\%((\a\+)\)\=:E117/
  endtry
enddef

export def Root()
  Toggle(g:ChopsticksProjectRoot())
enddef

export def Here()
  if &filetype ==# 'fern'
    Toggle(getcwd())
    return
  endif
  Toggle(empty(expand('%:p')) ? getcwd() : expand('%:p:h'))
enddef

export def MaybeOpenDirectory()
  if directory_startup_opened || argc() != 1
      || !isdirectory(argv(0)) || &modified
    return
  endif
  var directory = fnamemodify(argv(0), ':p')
  if !isdirectory(expand('%:p'))
    return
  endif
  directory_startup_opened = true
  var directory_buffer = bufnr('%')
  silent keepalt enew
  execute 'lcd ' .. fnameescape(directory)
  if directory_buffer != bufnr('%') && bufexists(directory_buffer)
    execute 'silent! bwipeout ' .. directory_buffer
  endif
  Toggle(directory)
enddef
