vim9script

export def Enabled(): number
  return has('clipboard') && index(split(&clipboard, ','),
    has('unnamedplus') ? 'unnamedplus' : 'unnamed') >= 0 ? 1 : 0
enddef
