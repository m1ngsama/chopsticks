vim9script

# syncInit for the same reason as gopls: rust-analyzer indexes the crate before
# it can answer anything.
g:LspAddServer([{
  name: 'rust-analyzer',
  filetype: ['rust'],
  path: exepath('rust-analyzer'),
  args: [],
  syncInit: true,
}])
