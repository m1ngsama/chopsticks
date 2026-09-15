vim9script

export def CaptureMs()
  if !exists('g:chopsticks_startup_ms')
    g:chopsticks_startup_ms = reltimefloat(reltime(g:chopsticks_startup_started_at)) * 1000
  endif
enddef

export def MaybeOpenDashboard()
  if argc() == 0
      && bufname('%') ==# '' && &buftype ==# ''
      && line('$') == 1 && getline(1) ==# '' && !&modified
    chopsticks#ui#dashboard#Open()
  endif
enddef
