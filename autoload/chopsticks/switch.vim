vim9script

# Vim9 does not coerce the way legacy script did: E1023 on a Number that is not
# 0 or 1, E1135 on a String, E1030 comparing a String to a Number. Several
# g:chopsticks_* switches never pass through .vimrc's s:ResolveSwitch() and hold
# whatever the user assigned, so reading one directly aborts the function
# mid-way, after any side effects it already had. These restore the legacy
# coercion at the boundary.

# '0' and 'no' are both false, '2abc' is true. Not non-emptiness: !empty('no')
# would disagree.
export def Truthy(value: any): bool
  return type(value) == v:t_string ? str2nr(value) != 0 : !!value
enddef

export def Number(value: any, fallback: number): number
  if type(value) == v:t_number
    return value
  elseif type(value) == v:t_string
    return str2nr(value)
  elseif type(value) == v:t_float
    return float2nr(value)
  endif
  return fallback
enddef
