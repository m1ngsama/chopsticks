vim9script

const SESSION_DIR = expand('~/.vim/.sessions/')

export def ProjectRoot(): string
  var directory = empty(expand('%:p')) ? getcwd() : expand('%:p:h')
  while directory !=# '/'
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
  echo 'session saved: ' .. Root()
  if Modified() > 0
    Warn(Modified() .. ' modified buffer(s) are not stored in the session')
  endif
enddef

export def Load(force: bool)
  if !filereadable(Path())
    Warn('no session for ' .. Root())
  elseif !force && Modified() > 0
    Warn(printf('refusing to restore with %d modified listed buffer(s); '
      .. 'write them or use :ChopLoad! to load anyway', Modified()))
  else
    execute 'cd ' .. fnameescape(Root())
    execute 'silent source ' .. fnameescape(Path())
    echo 'session restored: ' .. Root()
  endif
enddef
