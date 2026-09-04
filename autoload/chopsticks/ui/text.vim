vim9script

# Display-width text helpers shared by more than one interface module.
#
# Truncate() lives here rather than in either caller because the dashboard and
# the statusline both need it: the dashboard trims its logo, item labels, and
# footer, and the statusline and buffer tabline trim file names and buffer
# labels. Keeping one copy keeps their ellipsis behaviour identical, which is
# what makes the two surfaces look like one design.

# Trim text to fit `width` display columns, appending an ellipsis when
# anything was removed. Width is measured with strwidth(), so double-width
# characters and the ellipsis itself are counted as they actually render;
# a naive strlen()-based trim would overflow the column budget for CJK text
# and for the Nerd Font glyphs the dashboard and statusline both use.
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
