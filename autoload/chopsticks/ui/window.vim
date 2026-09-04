vim9script

# Two window helpers shared by everything that needs a throwaway buffer or a
# terminal: the cheatsheet, the Markdown help sheet, :ChopsticksHealth, the
# Glow preview, lazygit, and the plain terminal mappings.
#
# They live here because they had started to be copied. health.vim carried
# its own transcription of Scratch() when it moved out of .vimrc, and moving
# the Markdown help would have made a third. One copy keeps the buffer
# options, the q/Esc mappings, and the terminal's split geometry identical
# everywhere, which is what makes these read as one editor rather than
# several features that each grew their own window.

# A read-only, unlisted buffer holding fixed text, closed with q or Esc.
export def Scratch(name: string, lines: list<string>)
  botright new
  execute 'file ' .. fnameescape(name)
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber signcolumn=no
  setlocal modifiable
  silent :%delete _
  setline(1, lines)
  setlocal nomodifiable nomodified
  nnoremap <silent><buffer> q :close<CR>
  nnoremap <silent><buffer> <Esc> :close<CR>
  normal! gg
enddef

# A terminal running `command`, or the shell when it is empty. A command
# terminal closes itself when the command exits; a shell stays.
export def Terminal(command: list<string>, position: string)
  if !has('terminal')
    echohl ErrorMsg
    echomsg 'chopsticks: this Vim has no +terminal'
    echohl None
    return
  endif
  if position ==# 'tab'
    tabnew
  else
    # Through :execute because Vim9 reads the leading 12 of `botright 12new`
    # as a range and refuses it (E1050).
    execute 'botright 12new'
  endif
  if empty(command)
    term_start(&shell, {curwin: 1})
  else
    term_start(command, {curwin: 1, term_finish: 'close'})
  endif
  startinsert
enddef
