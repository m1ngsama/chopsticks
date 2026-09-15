vim9script

export def CaptureMs()
  if !exists('g:chopsticks_startup_ms')
    g:chopsticks_startup_ms = exists('*reltimefloat')
      ? reltimefloat(reltime(g:chopsticks_startup_started_at)) * 1000
      : str2float(reltimestr(reltime(g:chopsticks_startup_started_at))) * 1000
  endif
enddef

export def MaybeOpenDashboard()
  if g:ChopsticksDashboardEnabled() && argc() == 0
      && bufname('%') ==# '' && &buftype ==# ''
      && line('$') == 1 && getline(1) ==# '' && !&modified
    chopsticks#ui#dashboard#Open()
  endif
enddef
