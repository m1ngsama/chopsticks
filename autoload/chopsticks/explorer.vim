vim9script

import autoload 'chopsticks/session.vim'
import autoload 'chopsticks/ui/icons.vim'

var directory_startup_opened = false

def PathInside(path_value: string, directory_value: string): bool
  var [path, directory] = [path_value, directory_value]->mapnew((_, value) =>
    resolve(fnamemodify(value, ':p'))->substitute('\\', '/', 'g')->substitute('/\+$', '', ''))
  if has('win32')
    [path, directory] = [tolower(path), tolower(directory)]
  endif
  return path ==# directory || stridx(path, directory .. '/') == 0
enddef

def Toggle(directory_arg: string)
  var directory = fnamemodify(directory_arg, ':p')
  var command = 'Fern ' .. fnameescape(directory)
    .. ' -drawer -toggle -width=' .. g:fern#drawer_width
  var current = expand('%:p')
  if filereadable(current) && PathInside(current, directory)
    command ..= ' -reveal=' .. fnameescape(current)
  endif
  execute command
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
  if icons.Enabled()
    glyph_palette#apply()
  endif
enddef

export def Root()
  Toggle(session.ProjectRoot())
enddef

export def Here()
  Toggle(&buftype ==# '' && !empty(expand('%:p')) ? expand('%:p:h') : getcwd())
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
