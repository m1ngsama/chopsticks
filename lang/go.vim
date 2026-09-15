vim9script

g:LspAddServer([{
  name: 'gopls',
  filetype: ['go'],
  path: exepath('gopls'),
  args: ['serve'],
  syncInit: true,
}])
