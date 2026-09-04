vim9script

# Project sessions, backing ChopsticksSessionPath() (a documented public
# global, see plugin/chopsticks.vim) and the :ChopsticksSessionSave /
# :ChopsticksSessionLoad commands. README.md documents the security
# properties this module must preserve exactly: session files are keyed by
# resolved project root AND Vim release (so same-named projects never
# collide and an incompatible session format never overwrites a compatible
# one), POSIX writes land with private modes and a group/world-writable
# session directory or file is refused outright, every platform rejects
# non-regular session input, and a plain :ChopsticksSessionLoad refuses to
# clobber a modified listed buffer unless the bang form opts in.
#
# ProjectRoot() is exported because the file finder, the tree drawer, the
# lazygit launcher and the health report all need the same project-root
# resolution outside any session action. They reach it through the plain
# global g:ChopsticksProjectRoot() declared in plugin/chopsticks.vim rather
# than importing this module, which keeps one shared answer without four
# modules importing the session code to get it.
#
# IsWindows, NormalizeDirectory, and DirectoryFileType duplicate small,
# self-contained pieces of .vimrc's own s:is_windows / s:NormalizeDirectory /
# s:DirectoryFileType. Those stay in .vimrc because they are shared far
# beyond sessions (data-dir setup, the ALE state directory, fern discovery);
# Vim9 script-local names cannot cross files, and reaching back into .vimrc
# is not possible, so the small amount of logic actually needed here is
# reproduced instead of exported wholesale.

const IsWindows: bool = has('win32') || has('win64')

def NormalizeDirectory(value: string, fallback: string): string
  var chosen = empty(value) ? fallback : value
  var directory = simplify(fnamemodify(expand(chosen), ':p'))
  if directory !~# '[/\\]$'
    # Match the separator the path already uses. ':p' supplies one itself for
    # a directory that exists, so this runs only for one that does not, and
    # a hardcoded '/' produced 'C:\dir\name/' on Windows. .vimrc's
    # s:NormalizeDirectory() and tests/ui.vim's s:NormalizedDirectory()
    # repeat this rule and all three must agree.
    directory ..= IsWindows && directory =~# '\\' ? '\' : '/'
  endif
  return directory
enddef

def DirectoryFileType(path: string): string
  # getftype() follows a directory symlink when its name ends in a slash.
  var cleaned = substitute(path, '[/\\]$', '', '')
  if empty(cleaned)
    cleaned = path
  elseif IsWindows && cleaned =~? '^\a:$'
    cleaned ..= '/'
  endif
  return getftype(cleaned)
enddef

export def ProjectRoot(): string
  var start = empty(expand('%:p')) ? getcwd() : expand('%:p:h')
  var directory = simplify(fnamemodify(start, ':p'))
  while !empty(directory)
    var separator = directory =~# '[/\\]$' ? '' : '/'
    var marker = directory .. separator .. '.git'
    if isdirectory(marker) || filereadable(marker)
      # Directories here are canonical: absolute, simplified, and ending
      # with a separator, the shape g:chopsticks_data_dir already has.
      return NormalizeDirectory(fnamemodify(marker, ':h'), getcwd())
    endif
    var parent = fnamemodify(directory, ':h')
    if parent ==# directory || (IsWindows && parent ==? directory)
      break
    endif
    directory = parent
  endwhile
  return NormalizeDirectory(getcwd(), getcwd())
enddef

def SessionRoot(): string
  var root = get(b:, 'chopsticks_project_root', ProjectRoot())
  return resolve(fnamemodify(root, ':p'))
enddef

def SessionDigest(value: string): string
  var first = 5381
  var second = 52711
  for character in str2list(value)
    first = and(first * 33 + character, 0x7fffffff)
    second = and(second * 65599 + character, 0x7fffffff)
  endfor
  return printf('%08x%08x', first, second)
enddef

export def Path(): string
  var root = SessionRoot()
  var name = substitute(fnamemodify(root, ':t'),
    '[^A-Za-z0-9_.-]', '-', 'g')
  name = empty(name) ? 'workspace' : name
  name = strpart(name, 0, 64)
  var filename = printf('%s-%s-vim%d.vim', name,
    SessionDigest(root), v:version)
  return simplify(g:chopsticks_session_dir .. filename)
enddef

def SessionPermissionsAreSafe(path: string): bool
  if IsWindows || !exists('*getfperm')
    return true
  endif
  var permissions = getfperm(path)
  return !empty(permissions)
    && (strpart(permissions, 4, 1) !=# 'w'
      && strpart(permissions, 7, 1) !=# 'w')
enddef

def SessionDirectoryIsSafe(): bool
  return DirectoryFileType(g:chopsticks_session_dir) ==# 'dir'
    && SessionPermissionsAreSafe(g:chopsticks_session_dir)
enddef

def SessionPathIsSafe(path: string): bool
  if getftype(path) !=# 'file' || !SessionDirectoryIsSafe()
    return false
  endif
  # Windows access is governed by ACLs; its getfperm() owner/group/other
  # string is not an authority boundary. The regular-file and trusted-root
  # checks still apply there.
  return SessionPermissionsAreSafe(path)
enddef

export def Save(): void
  if &filetype ==# 'chopsticks-dashboard'
    echohl WarningMsg
    echom 'chopsticks: open a project buffer before saving a session'
    echohl None
    return
  endif
  mkdir(g:chopsticks_session_dir, 'p', 0o700)
  if DirectoryFileType(g:chopsticks_session_dir) !=# 'dir'
    echohl ErrorMsg
    echom 'chopsticks: session directory is not a regular directory'
    echohl None
    return
  endif
  if exists('*setfperm')
    setfperm(g:chopsticks_session_dir, 'rwx------')
  endif
  if !SessionDirectoryIsSafe()
    echohl ErrorMsg
    echom 'chopsticks: refusing an unsafe session directory'
    echohl None
    return
  endif
  var path = Path()
  var temporary = path .. '.tmp-' .. getpid()
  if !empty(getftype(temporary))
    echohl ErrorMsg
    echom 'chopsticks: refusing an existing session temporary path'
    echohl None
    return
  endif
  try
    execute 'silent mksession! ' .. fnameescape(temporary)
    if getftype(temporary) !=# 'file'
      throw 'temporary session is not a regular file'
    endif
    if exists('*setfperm')
      setfperm(temporary, 'rw-------')
    endif
    if (has('win32') || has('win64')) && filereadable(path)
      var backup = path .. '.bak-' .. getpid()
      if rename(path, backup) != 0
        throw 'could not stage the previous session'
      endif
      if rename(temporary, path) != 0
        rename(backup, path)
        throw 'could not move the new session into place'
      endif
      delete(backup)
    elseif rename(temporary, path) != 0
      throw 'could not move the new session into place'
    endif
    if exists('*setfperm')
      setfperm(path, 'rw-------')
    endif
  catch
    delete(temporary)
    echohl ErrorMsg
    echom 'chopsticks: could not save session: ' .. v:exception
    echohl None
    return
  endtry
  echo 'session saved: ' .. fnamemodify(path, ':t')
  var modified = getbufinfo({'buflisted': 1})
    ->filter((_, val) => get(val, 'changed', 0) != 0)
  if !empty(modified)
    echohl WarningMsg
    echom printf(
      'chopsticks: %d modified buffer(s) are not stored in the session',
      len(modified))
    echohl None
  endif
enddef

export def Load(force: bool): void
  var path = Path()
  var file_type = getftype(path)
  if empty(file_type)
    echohl WarningMsg
    echom 'chopsticks: no session for ' .. SessionRoot()
    echohl None
    return
  endif
  if file_type !=# 'file'
    echohl ErrorMsg
    echom 'chopsticks: refusing a non-regular session file'
    echohl None
    return
  endif
  if !filereadable(path)
    echohl ErrorMsg
    echom 'chopsticks: session file is not readable'
    echohl None
    return
  endif
  if !SessionPathIsSafe(path)
    echohl ErrorMsg
    echom 'chopsticks: refusing a session writable by other users'
    echohl None
    return
  endif
  var modified = getbufinfo({'buflisted': 1})
    ->filter((_, val) => get(val, 'changed', 0) != 0)
  if !force && !empty(modified)
    echohl WarningMsg
    echom printf('chopsticks: refusing to restore with %d modified listed '
      .. 'buffer(s); write them or use :ChopsticksSessionLoad! to load '
      .. 'anyway', len(modified))
    echohl None
    return
  endif
  var shortmess = &shortmess
  try
    execute 'cd ' .. fnameescape(SessionRoot())
    execute 'silent source ' .. fnameescape(path)
    echo 'session restored: ' .. fnamemodify(path, ':t')
  catch
    echohl ErrorMsg
    echom 'chopsticks: could not restore session: ' .. v:exception
    echohl None
  finally
    &shortmess = shortmess
    unlet! g:SessionLoad
  endtry
enddef
