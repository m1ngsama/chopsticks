vim9script

# The file tree drawer: Fern when it is installed, netrw's :Lexplore
# otherwise, behind the same keys either way.
#
# Fern's own actions are <Plug> mappings, so the buffer-local mappings below
# stay `nmap` to <Plug> targets rather than becoming <ScriptCmd> — they are
# not calls into this module at all.

import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/switch.vim'

const IS_WINDOWS = has('win32') || has('win64')

# Set once, the first time a directory argument is turned into a drawer, so
# that reopening a buffer later does not re-trigger the startup behaviour.
#
# Module state outlives a `:source $MYVIMRC`, where the script-local flag it
# replaced did not. Re-sourcing therefore no longer re-arms this, which is
# the more defensible behaviour anyway: the directory argument belongs to
# the Vim session that started, not to the last time the config was reloaded.
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

# g:chopsticks_use_fern is never normalised by .vimrc, so it holds whatever
# the user assigned. Read through switch.Truthy(): a Vim9 && raises E1135 on
# a String and E1023 on a Number that is not 0 or 1, where legacy coerced --
# and a throw here escapes Toggle(), so SPC e would error out instead of
# falling back to netrw. health.vim reads the same switch the same way.
export def FernAvailable(): bool
  return switch.Truthy(get(g:, 'chopsticks_use_fern', 1)) && exists(':Fern') == 2
enddef

# Whether `path` is `directory` or sits under it. Compares resolved paths, so
# a symlinked project root still matches its own files. Windows compares
# case-insensitively and normalises separators first.
def PathInside(path_value: string, directory_value: string): bool
  var path = resolve(fnamemodify(path_value, ':p'))
  var directory = resolve(fnamemodify(directory_value, ':p'))
  if IS_WINDOWS
    path = substitute(path, '\\', '/', 'g')
    directory = substitute(directory, '\\', '/', 'g')
    path = substitute(path, '/\+$', '', '')
    directory = substitute(directory, '/\+$', '', '')
    return path ==? directory
      || stridx(tolower(path), tolower(directory .. '/')) == 0
  endif
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
    # Reveal the current file in the tree, but only when it is actually
    # inside the directory being opened.
    if filereadable(current) && PathInside(current, directory)
      command ..= ' -reveal=' .. fnameescape(current)
    endif
    execute command
    return
  endif
  var explorer = ExplorerWindow()
  if explorer != 0
    # netrw has no toggle, so closing is done by hand, returning to the
    # window the user was in rather than wherever closing left the cursor.
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
  # Match the reversible node interaction used by mature file trees: the same
  # key opens a file, expands a closed directory, and collapses an open
  # directory. expand:stay keeps the cursor on the directory so the second
  # press can close it again.
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
    try
      glyph_palette#apply()
    catch /^Vim\%((\a\+)\)\=:E117/
    endtry
  endif
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

# `vim some/directory` should land in a drawer over an empty buffer rather
# than in netrw's own listing. Runs from BufEnter because the directory
# buffer does not exist yet at VimEnter.
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
