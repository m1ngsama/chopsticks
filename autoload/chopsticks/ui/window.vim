vim9script

# One copy, because these had started to be transcribed per feature. The
# cheatsheet, Markdown help, :ChopsticksHealth, Glow, lazygit and the terminal
# mappings all come through here so their windows stay identical.

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
