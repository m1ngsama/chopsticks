vim9script

g:LspAddServer([{
  name: 'rust-analyzer',
  filetype: ['rust'],
  path: exepath('rust-analyzer'),
  args: [],
  syncInit: true,
}])
