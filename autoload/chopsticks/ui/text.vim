vim9script

export def Truncate(text: string, width: number): string
  if width <= 0
    return ''
  elseif strwidth(text) <= width
    return text
  elseif width == 1
    return '…'
  endif
  var result = ''
  var index = 0
  while index < strchars(text)
    var character = strcharpart(text, index, 1)
    if strwidth(result .. character .. '…') > width
      break
    endif
    result ..= character
    index += 1
  endwhile
  return result .. '…'
enddef
