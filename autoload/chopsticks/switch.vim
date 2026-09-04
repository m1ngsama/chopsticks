vim9script

# Reading g:chopsticks_* values the way legacy script did.
#
# Most switches are normalised by .vimrc's own s:ResolveSwitch(), which turns
# 'auto' into 0 or 1 before anything reads them. Several are not:
# g:chopsticks_use_fern, g:chopsticks_markdown_conceal,
# g:chopsticks_markdown_spell, and g:chopsticks_long_line_threshold are plain
# get(g:, ...) defaults, so they hold whatever the user assigned.
#
# That was harmless while every reader was legacy script. Legacy `if`, `&&`,
# `||` and `?:` coerce anything to a boolean, and legacy arithmetic coerces a
# numeric string. Vim9 does neither: it raises E1023 on a Number that is not
# 0 or 1, E1135 on a String, and E1030 comparing a String to a Number. So a
# user value that used to work now aborts the function reading it, mid-way,
# after any side effects it already had.
#
# These two helpers put the legacy coercion back at the boundary, so a module
# can read a user switch without inheriting that failure mode.

# Legacy truthiness. A String is true exactly when str2nr() of it is nonzero,
# which is what legacy `if` did -- so '0' and 'no' are both false, and '2abc'
# is true. Note this is NOT non-emptiness: !empty('no') would disagree.
export def Truthy(value: any): bool
  return type(value) == v:t_string ? str2nr(value) != 0 : !!value
enddef

# Legacy numeric reading, for a switch compared against a number rather than
# tested for truth. A String goes through str2nr() and a Float through
# float2nr(), as legacy arithmetic did; anything else falls back rather than
# throwing.
export def Number(value: any, fallback: number): number
  if type(value) == v:t_number
    return value
  elseif type(value) == v:t_string
    return str2nr(value)
  elseif type(value) == v:t_float
    # Legacy arithmetic accepted a Float and truncated it; falling back here
    # would silently disable whatever the number gates.
    return float2nr(value)
  endif
  return fallback
enddef
