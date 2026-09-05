vim9script

# syncInit because gopls resolves the module graph during initialize, and an
# async init lets the first request arrive before it is ready.
g:LspAddServer([{
  name: 'gopls',
  filetype: ['go'],
  path: exepath('gopls'),
  args: ['serve'],
  syncInit: true,
}])
