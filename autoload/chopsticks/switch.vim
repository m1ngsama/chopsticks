vim9script

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
