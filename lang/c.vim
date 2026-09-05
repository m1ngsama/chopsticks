vim9script

g:LspAddServer([{
  name: 'clangd',
  filetype: ['c', 'cpp'],
  path: exepath('clangd'),
  args: ['--background-index'],
}])
