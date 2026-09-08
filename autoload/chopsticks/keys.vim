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

# What to learn first. Not the fifteen most useful keys -- the four prefixes
# the rest hangs off, which is the part a list of individual keys hides.
#
# Each row also names the keys it stands for, written the way the sheet prints
# them, so the suite can check that this block still describes keys that are
# really bound. It has to run where the plugins are: the ; row teaches the
# finder, which is not bound at all without one.
const STARTERS = [
  {keys: '; f b l r h', mode: 'n', covers: [';f', ';b', ';l', ';r', ';h'],
   description: 'Find fast: files, buffers, this file, project, help'},
  {keys: 'SPC', mode: 'n', covers: ['SPC e', 'SPC ?'],
   description: 'Everything else, by category -- hold it to see the menu'},
  {keys: 's h j k l', mode: 'n', covers: ['sh', 'sj', 'sk', 'sl'],
   description: 'Move between windows; then s or v to split, q to close'},
  {keys: ',', mode: 'n*', covers: [',?'],
   description: 'Markdown actions, in a Markdown file -- hold it too'},
  {keys: 'Ctrl-s', mode: 'n/i/x', covers: ['Ctrl-s'],
   description: 'Save, from any mode'},
  {keys: 'SPC e', mode: 'n', covers: ['SPC e'],
   description: 'Show or hide the file tree'},
  {keys: 'SPC h', mode: 'n', covers: ['SPC h'],
   description: 'Health report: what is installed and what is missing'},
  ]

var catalog: list<dict<string>> = []
var catalog_index: dict<number> = {}

# Exported for the suite, which asserts that every key a starter row claims to
# teach is really bound.
export def StarterCoverage(): list<string>
  var covered: list<string> = []
  for starter in STARTERS
    extend(covered, starter.covers)
  endfor
  return covered
enddef

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

# Three keys that do one thing were three rows that said the same sentence,
# with nothing to say which to learn. They become one row: the fewest
# keystrokes leads, the rest follow the description in brackets, so searching
# the sheet for any of them still lands on it.
#
# Keyed on mode as well as description, because `SPC y` in normal and visual
# mode share both a key and a sentence and are not aliases of each other.
# Only within a group: `,z` and `SPC z` are the same action, and the reason
# `,z` is filed under Markdown is that this is where someone looks for it.
def Merged(entries: list<dict<string>>): list<dict<string>>
  var order: list<string> = []
  var clusters: dict<list<dict<string>>> = {}
  for entry in entries
    var id = entry.mode .. "\n" .. entry.description
    if !clusters->has_key(id)
      clusters[id] = []
      order->add(id)
    endif
    clusters[id]->add(entry)
  endfor
  var merged: list<dict<string>> = []
  for id in order
    var cluster = clusters[id]
    if len(cluster) == 1
      merged->add(cluster[0])
      continue
    endif
    # Fewest keystrokes leads, but a key the Start here block teaches leads
    # over a shorter one that it does not: \ reaches the buffer list in one
    # stroke where ;b takes two, and promoting it would leave the sheet
    # recommending a key against the block above it. Stable otherwise, so
    # equal ranks keep the order they were registered in.
    var taught = StarterCoverage()
    var Rank = (keys: string): number =>
      (index(taught, keys) >= 0 ? 0 : 1000) + strwidth(keys)
    var keys = mapnew(cluster, (_, entry) => entry.keys)
    var sorted = sort(copy(keys), (a, b) => Rank(a) - Rank(b))
    merged->add({
      keys: sorted[0],
      mode: cluster[0].mode,
      description: printf('%s  (%s)', cluster[0].description,
        join(sorted[1 : ], ', ')),
      })
  endfor
  return merged
enddef

# The same glyph the key guide puts on the same group, so the two surfaces
# stop looking like two programs. Empty in ASCII mode, where the heading is
# the plain word it always was.
def Heading(group: string): string
  var icon = icons.Group(group)
  return empty(icon) ? group : icon .. '  ' .. group
enddef

# By display width: printf's %-Ns counts characters, not the glyph's cells.
def IconCell(icon: string, width: number): string
  return width == 0 ? '' : icon .. repeat(' ', width - strwidth(icon) + 1)
enddef

def Sections(groups: list<string>): list<dict<any>>
  var sections: list<dict<any>> = []
  for group in groups
    var entries = filter(copy(catalog), (_, entry) => entry.group ==# group)
    if !empty(entries)
      sections->add({group: group, entries: Merged(entries)})
    endif
  endfor
  return sections
enddef

# Measured, not fixed at 15 and 2: `n/i/x` is five wide and overflowed a
# two-wide field, pushing that row's description out of the column. One
# column of slack past the longest entry also keeps both separators at two
# spaces or more, which is what syntax/chopsticks-cheatsheet.vim finds the
# fields by -- so widening this cannot silently uncolour them. Measured over
# the sections asked for, so the Markdown panel is not padded to the full
# sheet's widest key.
def Rendered(sections: list<dict<any>>): list<string>
  var rows: list<dict<string>> = []
  for section in sections
    for entry in section.entries
      rows->add({
        group: section.group,
        icon: icons.Action(entry.description, section.group),
        keys: entry.keys,
        mode: entry.mode,
        description: entry.description,
        })
    endfor
  endfor
  if empty(rows)
    return []
  endif
  var icon_width = max(mapnew(rows, (_, row) => strwidth(row.icon)))
  var key_width = max(mapnew(rows, (_, row) => strwidth(row.keys))) + 1
  var mode_width = max(mapnew(rows, (_, row) => strwidth(row.mode))) + 1
  var format = printf('  %%s%%-%ds %%-%ds %%s', key_width, mode_width)
  var lines: list<string> = []
  var heading = ''
  for row in rows
    if row.group !=# heading
      heading = row.group
      extend(lines, ['', Heading(heading)])
    endif
    add(lines, printf(format, IconCell(row.icon, icon_width),
      row.keys, row.mode, row.description))
  endfor
  return lines
enddef

export def Lines(): list<string>
  var sections: list<dict<any>> = [{group: 'Start here', entries: STARTERS}]
  sections->extend(Sections(GROUP_ORDER))
  return [
    'chopsticks ' .. g:chopsticks_version .. ' cheatsheet',
    '',
    'SPC = Leader   , = Markdown LocalLeader',
    'Pause after SPC or , for the contextual key guide.',
    'j k Ctrl-d gg G move · / searches · CR presses the key · q closes.',
    'Modes: n normal · x visual · i insert · t terminal · * buffer-local',
    ] + Rendered(sections)
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
  window.Scratch('[chopsticks-cheatsheet]', Lines(), 'chopsticks-cheatsheet')
enddef
