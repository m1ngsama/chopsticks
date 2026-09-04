vim9script

# The key catalogue and the which-key tree.
#
# This module owns the RECORD of what is bound: the catalogue every mapping
# registers into, the which-key nested dictionary, and the rendered
# cheatsheet. It does not own the bindings themselves.
#
# .vimrc keeps the four helpers that actually create mappings — LeaderN,
# LeaderX, DirectN, DirectX — and they call into here. That split is forced
# rather than chosen. Those helpers `:execute` a `:nnoremap` whose
# right-hand side contains `<SID>`, and Vim expands `<SID>` in a mapping to
# the script ID of whatever script runs the :nnoremap. Moving them here
# would silently rewrite every one of those mappings to point at a function
# in THIS script, which does not exist. The bindings and their right-hand
# sides also read as configuration: which key does what is the part a person
# edits, and it belongs beside the functions those keys call.

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

# A group's which-key label: its icon, when icons are on, then its name.
export def Group(group: string): string
  var icon = icons.Group(group)
  return '+' .. (empty(icon) ? '' : icon .. ' ') .. group
enddef

# Record one binding. Keyed on mode plus keys so that re-registering the same
# key replaces its entry instead of listing it twice — which matters because
# some keys are registered again under a different description once the
# plugin that backs them turns out to be installed.
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

# Render a leader sequence the way the cheatsheet shows it: 'SPC g s'.
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

# Insert a binding into g:which_key_map, creating any intermediate group
# nodes it passes through. A node that already exists as a plain description
# string is replaced by a group dictionary, so registering 'SPC g' after
# 'SPC g s' cannot lose the subtree.
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

# Clear the catalogue. .vimrc calls this beside its own reset of
# g:which_key_map, so that re-sourcing .vimrc rebuilds both records from
# scratch instead of leaving entries for keys the new configuration no
# longer binds. Module state outlives a .vimrc re-source; the script-local
# list this replaced did not.
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

# The cheatsheet itself, as a scratch buffer. Its own filetype so a
# colorscheme can highlight the key columns, and 'cursorline' because the
# sheet is read by scanning down it.
export def Show()
  window.Scratch('[chopsticks-cheatsheet]', Lines())
  setlocal filetype=chopsticks-cheatsheet cursorline
enddef
