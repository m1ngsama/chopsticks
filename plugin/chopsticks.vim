vim9script

if exists('g:loaded_chopsticks')
  finish
endif
g:loaded_chopsticks = true

import autoload 'chopsticks/clipboard.vim'
import autoload 'chopsticks/session.vim'
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/dashboard.vim'

def g:ChopsticksSystemClipboardEnabled(): number
  return clipboard.Enabled()
enddef

def g:ChopsticksIcon(name: string): string
  return icons.Get(name)
enddef

def g:ChopsticksSessionPath(): string
  return session.Path()
enddef

def g:ChopsticksProjectRoot(): string
  return session.ProjectRoot()
enddef

command! -bar ChopSave session.Save()
command! -bar -bang ChopLoad session.Load(<bang>0)
command! ChopDash dashboard.Open()
