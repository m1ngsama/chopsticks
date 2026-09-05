vim9script

# Number, not bool: tests/ui.vim compares this against a legacy && expression,
# and assert_equal() does not treat v:true as equal to 1.
export def Enabled(): number
  return has('clipboard')
    && index(split(&clipboard, ','), 'unnamedplus') >= 0 ? 1 : 0
enddef
