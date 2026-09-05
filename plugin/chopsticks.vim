vim9script

# Never :source this file from .vimrc. It lives under plugin/, so Vim sources
# it again once .vimrc finishes; re-sourcing resets the script-local scope the
# `import autoload` bindings live in, and the guard below then skips the import
# lines, leaving every shim to fail E1001 at call time.
#
# For the same reason .vimrc cannot call these globals from its own top level:
# this file has not loaded yet, so the call fails E117. It reaches modules
# there by classic dotted name (chopsticks#ui#icons#Get()), which resolves
# against 'runtimepath' on reference. Prefer that; a shim is for names
# something outside Chopsticks depends on -- tests/ui.vim, 'statusline',
# 'tabline', a user command.
#
# Shims return number, not bool. Legacy callers compare against the 0/1 legacy
# operators produce, and v:true/v:false do not equal those under assert_equal()
# or ==#.

if exists('g:loaded_chopsticks')
  finish
endif
g:loaded_chopsticks = true

import autoload 'chopsticks/clipboard.vim'
import autoload 'chopsticks/session.vim'
import autoload 'chopsticks/health.vim'
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/theme.vim'
import autoload 'chopsticks/ui/dashboard.vim'

def g:ChopsticksSystemClipboardEnabled(): number
  return clipboard.Enabled()
enddef

def g:ChopsticksIcon(name: string): string
  return icons.Get(name)
enddef

def g:ChopsticksIconsEnabled(): number
  return icons.Enabled()
enddef

def g:ChopsticksTransparencyEnabled(): number
  return theme.TransparencyEnabled()
enddef

def g:ChopsticksSessionPath(): string
  return session.Path()
enddef

# find, explorer, actions, health and dashboard reach session.vim through this
# and ChopsticksSessionPath() rather than importing it.
def g:ChopsticksProjectRoot(): string
  return session.ProjectRoot()
enddef

def g:ChopsticksHealthLines(): list<string>
  return health.Lines()
enddef

command! -bar ChopsticksSessionSave session.Save()
command! -bar -bang ChopsticksSessionLoad session.Load(<bang>0)
command! ChopsticksHealth health.Show()
command! ChopsticksDashboard dashboard.Open()
command! ChopsticksIconsToggle icons.Toggle()
command! ChopsticksTransparencyToggle theme.ToggleTransparency()
command! -nargs=1 -complete=color ChopsticksTheme theme.Set(<q-args>)
