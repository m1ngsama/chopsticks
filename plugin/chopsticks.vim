vim9script

# Public interface. Every Chopsticks* global is declared here and delegates to
# an autoload module, which Vim does not read until the first call. Names in
# this file are a contract: tests/ui.vim asserts them, and 'statusline' and
# 'tabline' evaluate two of them on every redraw.

import autoload 'chopsticks/clipboard.vim'

def g:ChopsticksSystemClipboardEnabled(): number
  return clipboard.Enabled()
enddef
