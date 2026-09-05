vim9script

g:LspAddServer([{
  name: 'bash-language-server',
  filetype: ['sh'],
  path: exepath('bash-language-server'),
  args: ['start'],
}])
