vim9script

const SESSION_DIR = expand('~/.vim/.sessions/')

export def ProjectRoot(): string
  var directory = &buftype ==# '' && !empty(expand('%:p')) ? expand('%:p:h') : getcwd()
  while directory !=# fnamemodify(directory, ':h')
    if !empty(getftype(directory .. '/.git'))
      return directory .. '/'
    endif
    directory = fnamemodify(directory, ':h')
  endwhile
  return getcwd() .. '/'
enddef

def Root(): string
  return resolve(get(b:, 'chopsticks_project_root', ProjectRoot()))
enddef

export def Path(): string
  return SESSION_DIR .. substitute(Root(), '/', '%', 'g') .. '.vim'
enddef

def Modified(): number
  return len(getbufinfo({buflisted: 1})->filter((_, b) => b.changed))
enddef

def Warn(message: string)
  echohl WarningMsg
  echomsg 'chopsticks: ' .. message
  echohl None
enddef

export def Save()
  if &filetype ==# 'chopsticks-dashboard'
    Warn('open a project buffer before saving a session')
    return
  endif
  mkdir(SESSION_DIR, 'p', 0o700)
  execute 'silent mksession! ' .. fnameescape(Path())
  if Modified() > 0
    Warn('session saved without ' .. Modified() .. ' unsaved buffer(s)')
  else
    echo 'session saved: ' .. fnamemodify(Root(), ':t')
  endif
enddef

export def Load(force: bool)
  if !filereadable(Path())
    Warn('no session for ' .. fnamemodify(Root(), ':t'))
  elseif !force && Modified() > 0
    Warn(Modified() .. ' unsaved buffer(s): write them or :ChopLoad!')
  else
    var root = Root()
    execute 'silent source ' .. fnameescape(Path())
    silent execute 'cd ' .. fnameescape(root)
    echo 'session restored: ' .. fnamemodify(root, ':t')
  endif
enddef
