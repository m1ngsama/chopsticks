vim9script

# The buffer-local mappings here use <ScriptCmd>, not <SID>: <SID> in a mapping
# cannot reach a Vim9 module's script-local functions.

import autoload 'chopsticks/ui/window.vim'
import autoload 'chopsticks/switch.vim'
import autoload 'chopsticks/ui/bufferline.vim'

export def ToggleConceal()
  &l:conceallevel = &l:conceallevel == 0 ? 2 : 0
  # != 0, not a bare truthiness test: 'conceallevel' is 2 here and Vim9 refuses
  # any Number but 0 or 1 in a boolean position (E1023).
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

# Refuses rather than overwrites a taken name, and cleans up the partial file
# when pngpaste finds no image.
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
  var relative_dir = g:chopsticks_markdown_image_dir
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

# Bound to a variable rather than written as a multi-line list literal in the
# argument position: through a <ScriptCmd> mapping under the headless harness
# the literal form failed to compile with E697, though a direct call was fine.
export def Help()
  var sheet = [
    'chopsticks Markdown',
    '',
    'Writing',
    '  ,z       focus mode (Goyo + Limelight)',
    '  ,s       toggle spelling; ]s/[s navigate, z= choose',
    '  ,c       toggle syntax conceal',
    '  gqap     format paragraph; g<C-g> word count',
    '',
    'Structure',
    '  ,x       toggle task checkbox (parents follow children)',
    '  gN       renumber list',
    '  ]] / [[  next / previous heading; ]u parent heading',
    '  ,o       heading outline; ,O insert table of contents',
    '  ,tt      table mode; ,tr realign; visual ,tc tableize',
    '',
    'Links and output',
    '  gx / ge  open URL in browser / edit linked Markdown',
    '  ,p       live browser preview (Previm)',
    '  ,g       terminal preview (Glow)',
    '  ,i       paste clipboard PNG into assets/',
    '  ,l / ,f  lint now / format with Prettier',
    '',
    'Press q to close.',
  ]
  window.Scratch('[chopsticks-markdown]', sheet)
enddef

# A raw user value, never normalised, so it goes through switch.vim: comparing
# a String to a Number is E1030, on every buffer.
def Threshold(): number
  return switch.Number(g:chopsticks_long_line_threshold, 0)
enddef

# Vim recomputes the break indent for every wrapped screen line, so one very
# long line degrades far worse than linearly -- a 1 MiB single-line file turns
# a redraw into tens of seconds. Total bytes do not predict it, so the file-size
# guard elsewhere misses it. Detection runs for every buffer reaching a window
# and so must stay cheap: a virtual-column search would cost more than the
# problem it looks for.
def HasLongLine(): bool
  var lines = line('$')
  if lines <= 0
    return false
  endif
  # Constant time, and decisive for a buffer that is mostly one long line.
  var bytes = line2byte(lines + 1)
  if bytes > 0 && bytes / lines > Threshold()
    return true
  endif
  # Exact, but only where walking the buffer costs well under a millisecond.
  if lines > 2000
    return false
  endif
  return max(mapnew(range(1, lines), (_, l) => col([l, '$']))) > Threshold()
enddef

export def GuardLongLines()
  if !exists('+breakindent') || Threshold() <= 0
    return
  endif
  if HasLongLine()
    setlocal nobreakindent
  endif
enddef

export def Setup()
  setlocal wrap linebreak breakindent textwidth=0 colorcolumn=0
  setlocal norelativenumber nolist signcolumn=auto foldlevel=99
  &l:conceallevel = switch.Truthy(g:chopsticks_markdown_conceal) ? 2 : 0
  if switch.Truthy(g:chopsticks_markdown_spell)
    setlocal spell spelllang=en_us,cjk
  else
    setlocal nospell
  endif
  if exists(':Pencil') == 2
    pencil#init({wrap: 'soft'})
    &l:conceallevel = switch.Truthy(g:chopsticks_markdown_conceal) ? 2 : 0
  endif

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
  nnoremap <silent><buffer> <localleader>i :MarkdownPasteImage<CR>
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

# :execute, because Vim9 resolves a command name at :def-compile time: naming
# Limelight directly makes this module fail to compile (E476) wherever the
# plugin is absent, before the guard can run.
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
