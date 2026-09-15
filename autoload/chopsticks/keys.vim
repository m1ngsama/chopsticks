vim9script

import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/window.vim'

const GROUP_ORDER = [
  'Essentials', 'Fast find', 'Buffers', 'Windows', 'Files', 'Search', 'Quit',
  'Git', 'Code', 'Diagnostics', 'Run', 'Terminal', 'Tabs', 'Toggles',
  'Editing', 'Navigation', 'Writing', 'Structure', 'Links', 'Table',
]

export const MARKDOWN_GROUPS = ['Writing', 'Structure', 'Links', 'Table']

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
  ]

var catalog: list<dict<string>> = []
var catalog_index: dict<number> = {}

def StarterCoverage(): list<string>
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

export def Reset()
  catalog = []
  catalog_index = {}
enddef

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

def Heading(group: string): string
  var icon = icons.Group(group)
  return empty(icon) ? group : icon .. '  ' .. group
enddef

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

export def Sheet(groups: list<string>): list<string>
  return Rendered(Sections(groups))
enddef

def Lines(): list<string>
  var sections: list<dict<any>> = [{group: 'Start here', entries: STARTERS}]
  sections->extend(Sections(GROUP_ORDER))
  return [
    'chopsticks cheatsheet',
    '',
    'SPC = Leader   , = Markdown LocalLeader',
    'Pause after SPC or , for the contextual key guide.',
    'j k Ctrl-d gg G move · / searches · CR presses the key · q closes.',
    'Modes: n normal · x visual · i insert · t terminal · * buffer-local',
    ] + Rendered(sections)
enddef

export def Setup()
  var pattern = ' +\%(\S\+\s\+\)\?[0-9A-Za-z_\/-]\+\%(\s\+[0-9A-Za-z_\/-]\+\)*'
  silent! syntax clear WhichKeyGroup
  execute 'syntax match WhichKeyGroup /' .. pattern .. '/'
enddef

export def Show()
  window.Scratch('[chopsticks-cheatsheet]', Lines(), 'chopsticks-cheatsheet')
enddef
