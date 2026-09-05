vim9script

g:LspAddServer([{
  name: 'pyright',
  filetype: ['python'],
  path: exepath('pyright-langserver'),
  args: ['--stdio'],
}])
