vim9script

# The record of what is bound -- catalogue, which-key tree, cheatsheet -- not
# the bindings themselves. .vimrc keeps the four helpers that create mappings
# and calls in here. They could move now that their right-hand sides are dotted
# names rather than <SID>; they stay because which key does what is
# configuration and reads better beside the 85 bindings that use them.

import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/window.vim'

# Cheatsheet section order. A group with no entries is skipped, so this can
# list groups that only appear under some configurations.
const GROUP_ORDER = [
  'Essentials', 'Fast find', 'Buffers', 'Windows', 'Files', 'Search', 'Quit',
  'Git', 'Code', 'Diagnostics', 'Run', 'Terminal', 'Tabs', 'Toggles',
  'Editing', 'Navigation', 'Markdown',
]

var catalog: list<dict<string>> = []
var catalog_index: dict<number> = {}

export def Group(group: string): string
  var icon = icons.Group(group)
  return '+' .. (empty(icon) ? '' : icon .. ' ') .. group
enddef

# Keyed on mode plus keys, so re-registering a key replaces its entry rather
# than listing it twice: some keys are registered again with a different
# description once the plugin backing them turns out to be installed.
export def Catalog(group: string, mode: string, keys: string, description: string)
  var id = mode .. "\n" .. keys
  var entry = {
    group: group,
    mode: mode,
    keys: keys,
    description: description,
  }
  if has_key(catalog_index, id)
    catalog[catalog_index[id]] = entry
  else
    catalog_index[id] = len(catalog)
    add(catalog, entry)
  endif
enddef

export def LeaderLabel(parts: list<string>): string
  var tokens = []
  for token in parts
    if token ==# '<Space>'
      add(tokens, 'SPC ')
    elseif token ==# '<Tab>'
      add(tokens, 'TAB ')
    elseif token ==# '<Bar>'
      add(tokens, '|')
    else
      add(tokens, token)
    endif
  endfor
  return 'SPC ' .. trim(join(tokens, ''))
enddef

# A node already present as a plain description string becomes a group
# dictionary, so registering 'SPC g' after 'SPC g s' cannot lose the subtree.
export def WhichKeyAdd(parts: list<string>, group: string, description: string)
  if empty(parts)
    return
  endif
  var node = g:which_key_map
  if len(parts) > 1
    for index in range(0, len(parts) - 2)
      var key = parts[index]
      if !has_key(node, key) || type(node[key]) != type({})
        node[key] = {'name': Group(group)}
      elseif !has_key(node[key], 'name')
        node[key].name = Group(group)
      endif
      node = node[key]
    endfor
  endif
  node[parts[len(parts) - 1]] = description
enddef

# Module state outlives a .vimrc re-source where the script-local list it
# replaced did not, so a reload would otherwise keep entries for keys the new
# configuration no longer binds.
export def Reset()
  catalog = []
  catalog_index = {}
enddef

export def Lines(): list<string>
  var lines = [
    'chopsticks ' .. g:chopsticks_version .. ' cheatsheet',
    '',
    'SPC = Leader   , = Markdown LocalLeader',
    'Pause after SPC or , for the contextual key guide.',
    'Use / to search this sheet, n/N to move, and q to close.',
    'Modes: n normal · x visual · i insert · t terminal · * buffer-local',
  ]
  for group in GROUP_ORDER
    var entries = filter(copy(catalog), (_, entry) => entry.group ==# group)
    if empty(entries)
      continue
    endif
    extend(lines, ['', group])
    for entry in entries
      add(lines, printf('  %-15s %-2s  %s',
        entry.keys, entry.mode, entry.description))
    endfor
  endfor
  return lines
enddef

# Modern which-key treats a group icon and its label as one semantic unit.
# The Vim port's stock syntax only accepts ASCII immediately after '+', so
# teach it to include our optional Nerd Font prefix.
# The pattern goes through a variable and :execute because a Vim9 line that
# begins with '/' is read as a range, not as a :syntax argument (E1050).
export def Setup()
  var pattern = ' +\%(\S\+\s\+\)\?[0-9A-Za-z_\/-]\+\%(\s\+[0-9A-Za-z_\/-]\+\)*'
  silent! syntax clear WhichKeyGroup
  execute 'syntax match WhichKeyGroup /' .. pattern .. '/'
enddef

export def Show()
  window.Scratch('[chopsticks-cheatsheet]', Lines())
  setlocal filetype=chopsticks-cheatsheet cursorline
enddef
