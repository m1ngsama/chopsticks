vim9script

# Language-server keys and the insert-mode completion keys.
#
# Everything here is guarded on the plugin that provides it. vim-lsp defines
# lsp#complete() and the <Plug>(lsp-...) mappings; asyncomplete defines
# force_refresh(). With neither installed, Tab is an ordinary Tab and the
# buffer simply has no LSP mappings.

import autoload 'chopsticks/keys.vim'

# Buffer-local LSP mappings, applied by .vimrc's `User lsp_buffer_enabled`
# autocommand once a server has actually attached to the buffer -- so a file
# type with no server never gains keys that would do nothing.
#
# The cheatsheet entries are registered here rather than beside the other
# bindings because they only exist for buffers a server attached to; the 'n*'
# mode marker is what tells the reader they are buffer-local.
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

# True when there is nothing but whitespace behind the cursor, where Tab
# should indent rather than complete.
#
# strpart(), not str[i]. col() is a BYTE offset, and the two dialects index
# strings differently: legacy str[i] takes byte i, Vim9 str[i] takes
# character i. With a multibyte character before the cursor the Vim9 form
# reads past the end and returns an empty string, which matches no
# whitespace, so Tab would open the completion menu where it used to indent.
# strpart() is byte-based in both.
def AfterWhitespace(): bool
  var column = col('.') - 1
  return column == 0 || strpart(getline('.'), column - 1, 1) =~# '\s'
enddef

# Tab cycles the completion menu when one is open, indents at the start of a
# line, and otherwise asks asyncomplete for candidates. Reached from an
# <expr> mapping by its dotted name: <SID> in a mapping cannot resolve a
# Vim9 module's functions.
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
