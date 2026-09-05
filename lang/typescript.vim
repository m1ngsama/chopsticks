vim9script

g:LspAddServer([{
  name: 'typescript-language-server',
  filetype: ['typescript', 'javascript'],
  path: exepath('typescript-language-server'),
  args: ['--stdio'],
}])
