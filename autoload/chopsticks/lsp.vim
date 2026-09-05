vim9script

# Every entry point here is guarded on yegappan/lsp: without it no server is
# registered, no buffer gains LSP mappings, and Tab falls back to whatever
# omni-completion the filetype already had.

import autoload 'chopsticks/keys.vim'

# A server covering two filetypes gets one lang/ file, named for the first.
const ALIASES = {cpp: 'c', javascript: 'typescript'}
var registered: dict<bool> = {}

# g:LspAddServer() freezes each server's omni-completion flag from the options
# in force when it runs, and a FileType fires before the plugin's own LspSetup
# event does, so Ensure() calls this too. Guarded rather than assumed, because
# either caller can reach it with no plugin loaded.
export def Options()
  if !exists('*g:LspOptionsSet')
    return
  endif
  g:LspOptionsSet({
    autoComplete: false,
    omniComplete: true,
    ignoreMissingServer: true,
    showInlayHints: true,
    semanticHighlight: true,
    aleSupport: true,
    autoHighlightDiags: !g:chopsticks_is_remote,
    outlineOnRight: true,
  })
enddef

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
  Options()
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

# Applied by .vimrc's `User LspAttached` autocommand, so a file type with no
# server never gains keys that would do nothing. The cheatsheet entries are
# registered here for the same reason; 'n*' marks them buffer-local.
#
# A <Cmd> mapping's right-hand side is never :def-compiled, so naming a :Lsp*
# command here is safe where naming it in a function body would not be.
export def Maps()
  if !exists('*g:LspAddServer')
    return
  endif
  nnoremap <silent><buffer> gd <Cmd>LspGotoDefinition<CR>
  nnoremap <silent><buffer> gr <Cmd>LspShowReferences<CR>
  nnoremap <silent><buffer> gI <Cmd>LspGotoImpl<CR>
  nnoremap <silent><buffer> gy <Cmd>LspGotoTypeDef<CR>
  nnoremap <silent><buffer> K <Cmd>LspHover<CR>
  nnoremap <silent><buffer> [d <Cmd>LspDiag prev<CR>
  nnoremap <silent><buffer> ]d <Cmd>LspDiag next<CR>
  nnoremap <silent><buffer> <leader>ca <Cmd>LspCodeAction<CR>
  nnoremap <silent><buffer> <leader>cr <Cmd>LspRename<CR>
  nnoremap <silent><buffer> <leader>cf <Cmd>LspFormat<CR>
  # ':', not '<Cmd>': only the former picks up the '<,'> range, and without a
  # range :LspFormat formats the whole document instead of the selection.
  xnoremap <silent><buffer> <leader>cf :LspFormat<CR>
  nnoremap <silent><buffer> <leader>co <Cmd>LspDocumentSymbol<CR>
  nnoremap <silent><buffer> <leader>cS <Cmd>LspSymbolSearch<CR>
  nnoremap <silent><buffer> <leader>cl <Cmd>LspOutline<CR>
  nnoremap <silent><buffer> <leader>ci <Cmd>LspShowAllServers<CR>
  for item in [
      [['c', 'a'], 'Code action'],
      [['c', 'f'], 'Format document'],
      [['c', 'i'], 'Registered LSP servers'],
      [['c', 'l'], 'Code outline'],
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
  # &omnifunc rather than a plugin check: it is what <C-x><C-o> will actually
  # call, set by the LSP client on an attached buffer and by a filetype plugin
  # otherwise, and empty where neither has anything to offer.
  if AfterWhitespace() || empty(&omnifunc)
    return "\<Tab>"
  endif
  return "\<C-x>\<C-o>"
enddef

export def CompletionBackTab(): string
  return pumvisible() ? "\<C-p>" : "\<C-h>"
enddef
