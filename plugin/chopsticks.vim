vim9script

# Public interface. Every Chopsticks* global is declared here and delegates to
# an autoload module, which Vim does not read until the first call. Names in
# this file are a contract: tests/ui.vim asserts them, and 'statusline' and
# 'tabline' evaluate two of them on every redraw.
#
# .vimrc is sourced before this file. Vim's automatic plugin-loading pass
# runs only after the user's vimrc finishes, and .vimrc has to add this
# repository's own directory to 'runtimepath' from inside itself before that
# pass runs, just so it can find this file at all. A Chopsticks* global that
# .vimrc calls at its own script top level — not from inside a function,
# autocommand, or mapping — cannot be moved behind this shim without also
# moving that call site, or startup fails with E117 (unknown function) at
# the point .vimrc reaches it, before this file has ever loaded.
# ChopsticksIconsEnabled() and ChopsticksIcon() are exactly that: .vimrc
# calls both at top level to build g:fern#renderer, g:ale_sign_error, and
# friends. It reaches the icon and theme modules there through Vim's classic
# dotted autoload name instead (chopsticks#ui#icons#..., which resolves
# against 'runtimepath' the moment it is referenced, with no shim and no
# `import` needed) rather than through the g:ChopsticksIcon()-style globals
# declared below; see .vimrc's own comment next to those call sites for why.
# An earlier version of this file instead had .vimrc `:source` this file
# itself, early, so those globals would already exist by the time .vimrc's
# top level reached them: that broke `import autoload` for every shim below,
# not just the icon/theme ones, because a Vim9 script's lazily-imported
# autoload bindings do not survive being sourced by a nested `:source` from
# inside another script's own execution (verified against Vim 9.2; reached
# from an entirely separate, later script, calling the importing script's
# own exported def failed with E1001 "variable not found"). Whatever calls
# a Chopsticks* global from .vimrc's own top level, in some later task, needs
# the classic dotted name too — not this trick.
#
# Shims declared here return `number`, not Vim9 `bool`, wherever a caller in
# tests/ui.vim or .vimrc compares the result against a value produced by
# legacy script: legacy `&&`, `||`, and comparison operators return Number
# 0/1, Vim9's v:true/v:false do not compare equal to 0/1 under
# assert_equal() or ==#, and returning bool where a legacy caller expects
# Number silently breaks that comparison. Check every caller's usage before
# picking a return type; do not default to bool just because Vim9 prefers
# it. See autoload/chopsticks/clipboard.vim for the worked example.

if exists('g:loaded_chopsticks')
  finish
endif
g:loaded_chopsticks = true

import autoload 'chopsticks/clipboard.vim'
import autoload 'chopsticks/session.vim'
import autoload 'chopsticks/health.vim'
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/theme.vim'

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

# .vimrc's own fern, fzf, and terminal helpers need the same project-root
# resolution session.vim itself uses, outside any session action. .vimrc
# cannot reach an autoload module with a Vim9 `import` statement (see
# .vimrc's own comment on this, next to its ChopsticksProjectRoot() call
# sites): vimlint's legacy-script parser does not understand that syntax, so
# this shim exists to give .vimrc a plain global call instead, the same way
# it already reaches ChopsticksIconsEnabled() and
# ChopsticksSystemClipboardEnabled(). tests/ui.vim's
# s:AssertPublicInterface() asserts this global exists, same as the others.
def g:ChopsticksProjectRoot(): string
  return session.ProjectRoot()
enddef

def g:ChopsticksHealthLines(): list<string>
  return health.Lines()
enddef

command! -bar ChopsticksSessionSave session.Save()
command! -bar -bang ChopsticksSessionLoad session.Load(<bang>0)
command! ChopsticksHealth health.Show()
command! ChopsticksIconsToggle icons.Toggle()
command! ChopsticksTransparencyToggle theme.ToggleTransparency()
command! -nargs=1 -complete=color ChopsticksTheme theme.Set(<q-args>)
