vim9script

var glyphs = {
  'search': '',
  'new_file': '',
  'grep': '',
  'recent': '',
  'config': '',
  'session': '',
  'quit': '',
  'file': '',
  'folder_open': '',
  'git_branch': '',
  'git_add': '',
  'git_change': '',
  'git_delete': '',
  'error': '',
  'warning': '',
  'info': '',
  'modified': '●',
  'readonly': '',
  'spell': '󰓆',
  'words': '',
  'wrap': '󰖶',
  'startup': '',
  'marker': '',
  'save': '',
  'clipboard': '',
  'preview': '',
  'group_help': '',
  'group_link': '',
  'group_home': '',
  'group_find': '',
  'group_buffer': '󰓩',
  'group_window': '',
  'group_file': '󰈔',
  'group_git': '',
  'group_code': '',
  'group_check': '󰒡',
  'group_run': '',
  'group_term': '',
  'group_toggle': '',
  'group_edit': '',
  'group_nav': '',
  'group_markdown': '',
  'group_table': '',
  'group_quit': '',
  }
var group_glyphs = {
  'Essentials': 'group_home', 'Fast find': 'group_find',
  'Buffers': 'group_buffer', 'Windows': 'group_window',
  'Files': 'group_file', 'Search': 'group_find', 'Quit': 'group_quit',
  'Git': 'group_git', 'Code': 'group_code',
  'Diagnostics': 'group_check', 'Run': 'group_run',
  'Terminal': 'group_term', 'Tabs': 'group_buffer',
  'Toggles': 'group_toggle', 'Editing': 'group_edit',
  'Navigation': 'group_nav', 'Markdown': 'group_markdown',
  'Table': 'group_table',
  'Start here': 'startup',
  'Writing': 'group_edit', 'Structure': 'group_nav',
  'Links': 'group_link',
  }

export def Get(name: string): string
  return get(glyphs, name, '')
enddef

export def Group(group: string): string
  return Get(get(group_glyphs, group, ''))
enddef

const ACTION_RULES = [
  ['git', 'group_git'],
  ['\<save\|\<write\>', 'save'],
  ['heading\|outline\|table of contents\|fold', 'group_nav'],
  ['table', 'group_table'],
  ['find\|search\|grep', 'group_find'],
  ['window\|split', 'group_window'],
  ['\<buffer\|\<tabs\?\>', 'group_buffer'],
  ['file\|tree\|explor', 'group_file'],
  ['terminal\|shell', 'group_term'],
  ['toggle', 'group_toggle'],
  ['lint\|diagnostic\|error', 'group_check'],
  ['\<run\>\|\<test\|\<build\>\|\<make\>', 'group_run'],
  ['format\|align\|indent', 'group_edit'],
  ['copy\|paste\|clipboard\|yank', 'clipboard'],
  ['preview\|browser\|render', 'preview'],
  ['help\|cheatsheet', 'group_help'],
]

export def Action(description: string, group: string): string
  for [pattern, name] in ACTION_RULES
    if description =~? pattern
      return Get(name)
    endif
  endfor
  var fallback = Group(group)
  return empty(fallback) ? '·' : fallback
enddef

var file_icon_cache = {}

export def FileIcon(path: string): string
  var key = empty(path) ? '[No Name]' : path
  if !has_key(file_icon_cache, key)
    if empty(globpath(&runtimepath, 'autoload/nerdfont.vim'))
      file_icon_cache[key] = Get('file')
    else
      try
        file_icon_cache[key] = nerdfont#find(key, isdirectory(key))
      catch
        file_icon_cache[key] = Get('file')
      endtry
    endif
  endif
  var icon = file_icon_cache[key]
  return empty(icon) ? '' : icon .. ' '
enddef
