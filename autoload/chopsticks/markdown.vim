vim9script

# Markdown and prose editing: the buffer setup applied to a Markdown file,
# the lighter setup for plain text and commit messages, and the commands
# behind the LocalLeader mappings.
#
# Reached from .vimrc's FileType autocommands by the classic dotted name.
# The buffer-local mappings this module creates use <ScriptCmd> rather than
# <SID>, because <SID> in a mapping cannot reach a Vim9 module's
# script-local functions.

import autoload 'chopsticks/ui/window.vim'
import autoload 'chopsticks/ui/bufferline.vim'

export def ToggleConceal()
  &l:conceallevel = &l:conceallevel == 0 ? 2 : 0
  echo 'Markdown conceal: ' .. (&l:conceallevel ? 'ON' : 'OFF')
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

# Save the clipboard's PNG beside the document and insert a link to it.
# Refuses rather than overwrites when the target name is taken, and cleans up
# a partial file when pngpaste finds no image on the clipboard.
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

export def Help()
  window.Scratch('[chopsticks-markdown]', [
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
  ])
enddef

# Vim recomputes the break indent while laying out every wrapped screen line,
# so one very long line degrades far worse than linearly: a 1 MiB single-line
# Markdown file turns a single redraw into tens of seconds. The file-size
# guard elsewhere does not catch this, because the cost follows line length
# rather than total bytes. Drop the option on buffers that contain such a
# line. Detection itself has to stay cheap, because this runs for every
# buffer that reaches a window. A virtual-column search is not an option:
# computing screen columns over an enormous line is slower than the problem
# it looks for.
def HasLongLine(): bool
  var lines = line('$')
  if lines <= 0
    return false
  endif
  # Constant time, and decisive for the case that actually degrades: a buffer
  # that is mostly one very long line.
  var bytes = line2byte(lines + 1)
  if bytes > 0 && bytes / lines > g:chopsticks_long_line_threshold
    return true
  endif
  # Exact, but only for buffers small enough that walking them costs well
  # under a millisecond, so this guard never shows up in a startup budget.
  # Larger buffers keep the constant-time answer above.
  if lines > 2000
    return false
  endif
  return max(mapnew(range(1, lines), (_, l) => col([l, '$'])))
    > g:chopsticks_long_line_threshold
enddef

export def GuardLongLines()
  if !exists('+breakindent') || g:chopsticks_long_line_threshold <= 0
    return
  endif
  if HasLongLine()
    setlocal nobreakindent
  endif
enddef

export def Setup()
  setlocal wrap linebreak breakindent textwidth=0 colorcolumn=0
  setlocal norelativenumber nolist signcolumn=auto foldlevel=99
  &l:conceallevel = g:chopsticks_markdown_conceal ? 2 : 0
  if g:chopsticks_markdown_spell
    setlocal spell spelllang=en_us,cjk
  else
    setlocal nospell
  endif
  if exists(':Pencil') == 2
    pencil#init({wrap: 'soft'})
    &l:conceallevel = g:chopsticks_markdown_conceal ? 2 : 0
  endif

  # Each block below is guarded on the plugin that provides it, so the same
  # document behaves sensibly with any subset of them installed.
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

# Plain text, commit messages, and mail get the wrapping but not the
# Markdown-specific mappings or conceal handling.
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

# Both Limelight invocations go through :execute. Vim9 resolves a command
# name when the :def is compiled, exactly as it resolves a plain function
# name, so naming an optional plugin's command directly makes this module
# fail to compile wherever that plugin is absent (E476) -- the exists()
# guard never runs, because compilation happens first. The same rule is why
# statusline.vim reaches FugitiveHead() through call().
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
