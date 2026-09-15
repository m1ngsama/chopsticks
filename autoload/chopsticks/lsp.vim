vim9script

import autoload 'chopsticks/keys.vim'

const ALIASES = {cpp: 'c', javascript: 'typescript'}
var registered: dict<bool> = {}

export def Options()
  g:LspOptionsSet({
    autoComplete: false,
    omniComplete: true,
    ignoreMissingServer: true,
    showInlayHints: true,
    semanticHighlight: true,
    aleSupport: true,
    outlineOnRight: true,
    vsnipSupport: true,
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
  registered[name] = true
  Options()
  var found = globpath(&runtimepath, $'lang/{name}.vim', false, true)
  if !empty(found)
    execute 'source' fnameescape(found[0])
  endif
enddef

export def Maps()
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

def AfterWhitespace(): bool
  var column = col('.') - 1
  return column == 0 || strpart(getline('.'), column - 1, 1) =~# '\s'
enddef

def SnippetReady(direction: number): bool
  return vsnip#jumpable(direction) || (direction > 0 && vsnip#expandable())
enddef

export def SnippetAdvance(direction: number)
  if direction > 0 && vsnip#expandable()
    vsnip#expand()
    return
  endif
  var session = vsnip#get_session()
  if !empty(session)
    session.jump(direction)
  endif
enddef

def SnippetKeys(direction: number): string
  return SnippetReady(direction)
    ? $"\<Esc>:call chopsticks#lsp#SnippetAdvance({direction})\<CR>"
    : ''
enddef

export def SelectTab(direction: number): string
  var advance = SnippetKeys(direction)
  return !empty(advance) ? advance : (direction > 0 ? "\<Tab>" : "\<S-Tab>")
enddef

export def CompletionTab(): string
  if pumvisible()
    return "\<C-n>"
  endif
  var snippet = SnippetKeys(1)
  if !empty(snippet)
    return snippet
  endif
  if AfterWhitespace() || empty(&omnifunc)
    return "\<Tab>"
  endif
  return "\<C-x>\<C-o>"
enddef

export def CompletionBackTab(): string
  if pumvisible()
    return "\<C-p>"
  endif
  var snippet = SnippetKeys(-1)
  if !empty(snippet)
    return snippet
  endif
  return "\<C-h>"
enddef
