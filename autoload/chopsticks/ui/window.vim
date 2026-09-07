vim9script

# One copy, because these had started to be transcribed per feature. The
# cheatsheet, Markdown help, :ChopHealth, Glow, lazygit and the terminal
# mappings all come through here so their windows stay identical.

# A popup rather than a split, drawn with the border the finder already uses,
# so the two reading surfaces of this configuration look like one thing.
#
# A split could be searched with /, which a popup cannot be, so this filters as
# you type -- and keeps a section heading whenever any of its rows survive,
# which / never did. Typing filters, so the close keys are the finder's own
# set rather than q, which is a character you might want to search for.
const BORDER = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const CLOSE = ["\<Esc>", "\<C-c>", "\<C-g>", "\<C-q>"]
const SCROLL = {
  "\<Down>": 1, "\<C-e>": 1, "\<Up>": -1, "\<C-y>": -1,
  "\<PageDown>": 10, "\<PageUp>": -10,
  "\<ScrollWheelDown>": 3, "\<ScrollWheelUp>": -3,
  }

var state: dict<any> = {}

export def Filtered(lines: list<string>, query: string): list<string>
  if empty(query)
    return lines
  endif
  var pattern = '\c' .. escape(query, '\.*$^~[]')
  var kept: list<string> = []
  var heading = ''
  for line in lines
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
  return empty(kept) ? ['', '  no key matches ' .. query] : kept
enddef

def Render()
  popup_settext(state.id, Filtered(state.lines, state.query))
  popup_setoptions(state.id, {
    title: empty(state.query)
      ? printf(' %s ', state.title)
      : printf(' %s · %s ', state.title, state.query),
    firstline: 1,
    })
enddef

def Filter(id: number, key: string): bool
  if index(CLOSE, key) >= 0
    popup_close(id)
    return true
  elseif key ==# "\<BS>" || key ==# "\<C-h>"
    state.query = strcharpart(state.query, 0, strchars(state.query) - 1)
    Render()
    return true
  elseif key ==# "\<C-u>"
    state.query = ''
    Render()
    return true
  elseif SCROLL->has_key(key)
    var top = popup_getoptions(id).firstline + SCROLL[key]
    var last = line('$', id)
    popup_setoptions(id, {firstline: max([1, min([top, last])])})
    return true
  elseif key =~# '^[[:print:]]$'
    state.query ..= key
    Render()
    return true
  endif
  return true
enddef

# Named for what it replaced: one read-only report, shown the same way
# wherever it comes from.
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
  state = {lines: body, query: '', title: title, id: 0}
  state.id = popup_create(body, {
    title: ' ' .. title .. ' ',
    border: [1, 1, 1, 1],
    borderchars: BORDER,
    padding: [0, 1, 0, 1],
    minwidth: 40,
    maxwidth: float2nr(&columns * 0.86),
    maxheight: float2nr(&lines * 0.82),
    scrollbar: true,
    mapping: false,
    filter: Filter,
    filtermode: 'a',
    })
  if !empty(filetype)
    setbufvar(winbufnr(state.id), '&filetype', filetype)
  endif
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
