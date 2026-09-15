vim9script

const BORDER = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const CLOSE = ["\<Esc>", "\<C-c>", "\<C-g>", "\<C-q>", 'q']

const NAMED = {
  'SPC': "\<Space>", 'TAB': "\<Tab>", 'Esc': "\<Esc>", 'CR': "\<CR>",
  }

var state: dict<any> = {}

def Legend(lines: list<string>): number
  var height = 0
  while height < len(lines) && !empty(lines[height])
    height += 1
  endwhile
  return height
enddef

def Filtered(lines: list<string>, query: string): list<string>
  if empty(query)
    return lines
  endif
  var head = Legend(lines)
  var pattern = '\c' .. escape(query, '\.*$^~[]')
  var kept: list<string> = []
  var heading = ''
  for line in lines[head : ]
    if line !~# '^\s'
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
  return slice(lines, 0, head)
    + (empty(kept) ? ['', '  no key matches ' .. query] : kept)
enddef

def Keystrokes(row: string): string
  var column = matchstr(row, '^\s\+\zs.\{-}\ze\s\{2,}')
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

def Titled(name: string, lines: list<string>): list<any>
  if len(lines) > 1 && !empty(lines[0]) && empty(lines[1])
    return [lines[0], lines[2 : ]]
  endif
  return [substitute(name, '^\[chopsticks-\|\]$', '', 'g'), lines]
enddef

def Bounds(): dict<number>
  return {maxwidth: float2nr(&columns * 0.86), maxheight: float2nr(&lines * 0.82)}
enddef

export def Fit()
  if !empty(state) && !empty(popup_getpos(state.id))
    popup_setoptions(state.id, Bounds())
  endif
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
    cursorline: true,
    scrollbar: true,
    wrap: false,
    mapping: false,
    filter: Filter,
    filtermode: 'a',
    }->extend(Bounds()))
  setbufvar(winbufnr(state.id), 'chopsticks_legend', Legend(body))
  if !empty(filetype)
    setbufvar(winbufnr(state.id), '&filetype', filetype)
  endif
  if exists('+winhighlight')
    win_execute(state.id, 'setlocal winhighlight=PopupSelected:ChopPanelCursor')
  endif
  win_execute(state.id, 'call cursor(' .. FirstEntry() .. ', 1)')
enddef

export def Terminal(command: list<string>, position: string)
  if !empty(command) && !executable(command[0])
    echohl WarningMsg
    echomsg 'chopsticks: ' .. command[0] .. ' is not installed'
    echohl None
    return
  endif
  if position ==# 'tab'
    tabnew
  else
    botright :12new
  endif
  term_start(empty(command) ? &shell : command, {curwin: 1, term_finish: 'close'})
  startinsert
enddef
