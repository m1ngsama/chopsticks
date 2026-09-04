vim9script

# Whether the system clipboard is wired into the unnamed registers: Vim was
# built with +clipboard and 'clipboard' already contains 'unnamedplus' (set
# earlier in .vimrc, gated on g:chopsticks_system_clipboard and platform
# desktop detection).
#
# Returns number, not bool. Callers compare this against a Number produced by
# legacy-script && expressions (e.g. tests/ui.vim's assert_equal against
# has('clipboard') && ...), and Vim's assert_equal() does not treat 0/1 and
# v:false/v:true as equal, so a bool return would fail that assertion even
# though the value is "the same".
export def Enabled(): number
  return has('clipboard')
    && index(split(&clipboard, ','), 'unnamedplus') >= 0 ? 1 : 0
enddef
