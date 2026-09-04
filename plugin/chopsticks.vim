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
# ChopsticksIconsEnabled() and ChopsticksIcon() are the current examples:
# .vimrc calls both at top level to build g:fern#renderer, g:ale_sign_error,
# and friends.
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

def g:ChopsticksSystemClipboardEnabled(): number
  return clipboard.Enabled()
enddef
