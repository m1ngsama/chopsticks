vim9script

# One copy, because these had started to be transcribed per feature. The
# cheatsheet, Markdown help, :ChopHealth, Glow, lazygit and the terminal
# mappings all come through here so their windows stay identical.

# A popup rather than a split, drawn with the border the finder already uses,
# so the two reading surfaces of this configuration look like one thing.
#
# It reads before it searches. Typing filtered on every key once, which meant
# j -- the first thing a Vim user presses -- searched for the letter j and
# emptied the panel. Navigation is the default and / starts a search, the way
# every other read-only window in Vim behaves.
const BORDER = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const CLOSE = ["\<Esc>", "\<C-c>", "\<C-g>", "\<C-q>", 'q']

# Keys the sheet prints as words. Anything else in a key column is taken
# literally, and a row whose column does not resolve to a real mapping is not
# something <CR> can press -- see Press().
const NAMED = {
  'SPC': "\<Space>", 'TAB': "\<Tab>", 'Esc': "\<Esc>", 'CR': "\<CR>",
  }

var state: dict<any> = {}

# The lines before the first blank one. Kept through a query, because the
# syntax file's line anchors are measured from it.
def Legend(lines: list<string>): number
  var height = 0
  while height < len(lines) && !empty(lines[height])
    height += 1
  endwhile
  return height
enddef

export def Filtered(lines: list<string>, query: string): list<string>
  if empty(query)
    return lines
  endif
  var head = Legend(lines)
  var pattern = '\c' .. escape(query, '\.*$^~[]')
  var kept: list<string> = []
  var heading = ''
  for line in lines[head : ]
    if line !~# '^\s'
      # A heading, or a blank line: held back until a row under it matches, so
      # a query never leaves a section title standing on its own.
      if !empty(line)
        heading = line
      endif
      continue
    endif
    if line =~# pattern
      if !empty(heading)
        kept->extend(['', heading])
        heading = ''
      endif
      kept->add(line)
    endif
  endfor
  # slice(), not [0 : head - 1], which with no legend is [0 : -1] -- everything.
  return slice(lines, 0, head)
    + (empty(kept) ? ['', '  no key matches ' .. query] : kept)
enddef

# The key column of a row, as keystrokes. Returns an empty string for a row
# that names alternatives (Fern h / l), a family (; f b l r h) or anything
# else that is not one sequence to press.
export def Keystrokes(row: string): string
  var column = matchstr(row, '^\s\+\zs.\{-}\ze\s\{2,}')
  # Drop the row icon; every key the sheet prints is ASCII, so a non-ASCII
  # run can only be the glyph.
  column = substitute(column, '^[^\x00-\x7F]\+\s*', '', '')
  if empty(column) || column =~# '/'
    return ''
  endif
  var keys = ''
  for token in split(column)
    if NAMED->has_key(token)
      keys ..= NAMED[token]
    elseif token =~# '^Ctrl-.$'
      keys ..= eval('"\<C-' .. token[5] .. '>"')
    elseif token =~# '^Alt-.$'
      keys ..= eval('"\<M-' .. token[4] .. '>"')
    elseif token =~# '^[[:print:]]\+$'
      keys ..= token
    else
      return ''
    endif
  endfor
  return keys
enddef

def Press()
  var row = getbufline(winbufnr(state.id), line('.', state.id))
  var keys = empty(row) ? '' : Keystrokes(row[0])
  # Checked against the mappings rather than trusted: it is what rejects the
  # teaching rows, whose key column reads as a family and not a sequence.
  if empty(keys) || empty(maparg(keys, 'n'))
    return
  endif
  popup_close(state.id)
  feedkeys(keys, 'm')
enddef

def Move(delta: number)
  var last = line('$', state.id)
  var target = max([1, min([line('.', state.id) + delta, last])])
  win_execute(state.id, 'call cursor(' .. target .. ', 1)')
enddef

# The first row, not the first line: a heading or a blank under the cursor
# line reads as a selection of nothing.
def FirstEntry(): number
  var found = match(getbufline(winbufnr(state.id), 1, '$'), '^\s\+\S')
  return found < 0 ? 1 : found + 1
enddef

def Render()
  popup_settext(state.id, Filtered(state.lines, state.query))
  popup_setoptions(state.id, {title: Title()})
  win_execute(state.id, 'call cursor(' .. FirstEntry() .. ', 1)')
enddef

def Title(): string
  if state.searching
    return printf(' %s · /%s ', state.title, state.query)
  endif
  return empty(state.query)
    ? printf(' %s ', state.title)
    : printf(' %s · %s ', state.title, state.query)
enddef

def Searching(id: number, key: string): bool
  if key ==# "\<CR>"
    state.searching = false
  elseif key ==# "\<Esc>" || key ==# "\<C-c>"
    state.searching = false
    state.query = ''
    Render()
    return true
  elseif key ==# "\<BS>" || key ==# "\<C-h>"
    state.query = strcharpart(state.query, 0, strchars(state.query) - 1)
    Render()
    return true
  elseif key ==# "\<C-u>"
    state.query = ''
    Render()
    return true
  elseif key =~# '^[[:print:]]$'
    state.query ..= key
    Render()
    return true
  endif
  popup_setoptions(id, {title: Title()})
  return true
enddef

def Filter(id: number, key: string): bool
  if state.searching
    return Searching(id, key)
  endif
  var height = popup_getpos(id).core_height
  if state.pending ==# 'g'
    state.pending = ''
    if key ==# 'g'
      win_execute(id, 'call cursor(1, 1)')
      return true
    endif
  endif
  if index(CLOSE, key) >= 0
    popup_close(id)
  elseif key ==# '/'
    state.searching = true
    state.query = ''
    popup_setoptions(id, {title: Title()})
  elseif key ==# 'g'
    state.pending = 'g'
  elseif key ==# 'G'
    win_execute(id, 'call cursor(' .. line('$', id) .. ', 1)')
  elseif key ==# "\<CR>"
    Press()
  elseif key ==# 'j' || key ==# "\<Down>" || key ==# "\<C-e>"
    Move(1)
  elseif key ==# 'k' || key ==# "\<Up>" || key ==# "\<C-y>"
    Move(-1)
  elseif key ==# "\<C-d>" || key ==# "\<PageDown>"
    Move(height / 2)
  elseif key ==# "\<C-u>" || key ==# "\<PageUp>"
    Move(-height / 2)
  elseif key ==# "\<ScrollWheelDown>"
    Move(3)
  elseif key ==# "\<ScrollWheelUp>"
    Move(-3)
  endif
  return true
enddef

# A report writes its own title as the first line and a blank after it. That
# was the only place to put it in a split; the popup has a border to carry it,
# and repeating it inside would say the same thing twice.
def Titled(name: string, lines: list<string>): list<any>
  if len(lines) > 1 && !empty(lines[0]) && empty(lines[1])
    return [lines[0], lines[2 : ]]
  endif
  return [substitute(name, '^\[chopsticks-\|\]$', '', 'g'), lines]
enddef

export def Scratch(name: string, lines: list<string>, filetype = '')
  var [title, body] = Titled(name, lines)
  state = {lines: body, query: '', title: title, id: 0,
    searching: false, pending: ''}
  state.id = popup_create(body, {
    title: ' ' .. title .. ' ',
    border: [1, 1, 1, 1],
    borderchars: BORDER,
    padding: [0, 1, 0, 1],
    minwidth: 40,
    maxwidth: float2nr(&columns * 0.86),
    maxheight: float2nr(&lines * 0.82),
    cursorline: true,
    scrollbar: true,
    mapping: false,
    filter: Filter,
    filtermode: 'a',
    })
  # Before the filetype, which sources the syntax file that reads it.
  setbufvar(winbufnr(state.id), 'chopsticks_legend', Legend(body))
  if !empty(filetype)
    setbufvar(winbufnr(state.id), '&filetype', filetype)
  endif
  # PopupSelected is the finder's too; remapped window-locally, not globally.
  win_execute(state.id, 'setlocal winhighlight=PopupSelected:ChopPanelCursor')
  win_execute(state.id, 'call cursor(' .. FirstEntry() .. ', 1)')
enddef

export def Terminal(command: list<string>, position: string)
  if !has('terminal')
    echohl ErrorMsg
    echomsg 'chopsticks: this Vim has no +terminal'
    echohl None
    return
  endif
  if position ==# 'tab'
    tabnew
  else
    # Through :execute because Vim9 reads the leading 12 of `botright 12new`
    # as a range and refuses it (E1050).
    execute 'botright 12new'
  endif
  if empty(command)
    term_start(&shell, {curwin: 1})
  else
    term_start(command, {curwin: 1, term_finish: 'close'})
  endif
  startinsert
enddef
