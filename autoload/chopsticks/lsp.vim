vim9script

# Guarded on the plugin that provides each piece: without vim-lsp and
# asyncomplete, Tab is an ordinary Tab and the buffer gains no LSP mappings.

import autoload 'chopsticks/keys.vim'

# A server covering two filetypes gets one lang/ file, named for the first.
const ALIASES = {cpp: 'c', javascript: 'typescript'}
var registered: dict<bool> = {}

export def Ensure(ft: string)
  if empty(ft)
    return
  endif
  var name = ALIASES->get(ft, ft)
  if registered->has_key(name)
    return
  endif
  # Marked before the source, so a filetype with no lang/ file costs one
  # dictionary lookup for the rest of the session instead of a globpath.
  registered[name] = true
  if !exists('*g:LspAddServer')
    return
  endif
  var found = globpath(&runtimepath, $'lang/{name}.vim', false, true)
  if !empty(found)
    execute 'source' fnameescape(found[0])
  endif
enddef

export def Registered(): list<string>
  # keys() would resolve to the keys.vim import in this script, not the
  # builtin; items() is unshadowed.
  return sort(registered->items()->mapnew((_, v) => v[0]))
enddef

# Applied by .vimrc's `User lsp_buffer_enabled` autocommand, so a file type with
# no server never gains keys that would do nothing. The cheatsheet entries are
# registered here for the same reason; 'n*' marks them buffer-local.
export def Maps()
  if !exists('*lsp#complete')
    return
  endif
  setlocal omnifunc=lsp#complete
  nmap <silent><buffer> gd <Plug>(lsp-definition)
  nmap <silent><buffer> gr <Plug>(lsp-references)
  nmap <silent><buffer> gI <Plug>(lsp-implementation)
  nmap <silent><buffer> gy <Plug>(lsp-type-definition)
  nmap <silent><buffer> K <Plug>(lsp-hover)
  nmap <silent><buffer> [d <Plug>(lsp-previous-diagnostic)
  nmap <silent><buffer> ]d <Plug>(lsp-next-diagnostic)
  nmap <silent><buffer> <leader>ca <Plug>(lsp-code-action)
  nmap <silent><buffer> <leader>cr <Plug>(lsp-rename)
  nmap <silent><buffer> <leader>cf <Plug>(lsp-document-format)
  xmap <silent><buffer> <leader>cf <Plug>(lsp-document-range-format)
  nmap <silent><buffer> <leader>co <Plug>(lsp-document-symbol-search)
  nmap <silent><buffer> <leader>cS <Plug>(lsp-workspace-symbol-search)
  nnoremap <silent><buffer> <leader>ci :LspStatus<CR>
  for item in [
      [['c', 'a'], 'Code action'],
      [['c', 'f'], 'Format document'],
      [['c', 'i'], 'LSP status'],
      [['c', 'o'], 'Document symbols'],
      [['c', 'r'], 'Rename symbol'],
      [['c', 'S'], 'Workspace symbols'],
  ]
    keys.WhichKeyAdd(item[0], 'Code', item[1])
    keys.Catalog('Code', 'n*', keys.LeaderLabel(item[0]), item[1])
  endfor
  for item in [
      ['gd', 'Go to definition'], ['gr', 'Find references'],
      ['gI', 'Go to implementation'], ['gy', 'Go to type definition'],
      ['K', 'Hover documentation'],
      ['[d / ]d', 'Previous / next LSP diagnostic'],
  ]
    keys.Catalog('Code', 'n*', item[0], item[1])
  endfor
enddef

# strpart(), not str[i]. col() is a byte offset, and Vim9 str[i] takes character
# i where legacy took byte i; with a multibyte character before the cursor the
# Vim9 form reads past the end and returns '', matching no whitespace, so Tab
# would complete where it used to indent. strpart() is byte-based in both.
def AfterWhitespace(): bool
  var column = col('.') - 1
  return column == 0 || strpart(getline('.'), column - 1, 1) =~# '\s'
enddef

# Reached from an <expr> mapping by dotted name: <SID> in a mapping cannot
# resolve a Vim9 module's functions.
export def CompletionTab(): string
  if pumvisible()
    return "\<C-n>"
  endif
  if AfterWhitespace() || !exists('*asyncomplete#force_refresh')
    return "\<Tab>"
  endif
  return asyncomplete#force_refresh()
enddef

export def CompletionBackTab(): string
  return pumvisible() ? "\<C-p>" : "\<C-h>"
enddef
