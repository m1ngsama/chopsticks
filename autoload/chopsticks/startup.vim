vim9script

# Separate from the dashboard module on purpose. VimEnter needs both of these on
# every start, and reaching into the dashboard for them would source its
# rendering and action code even on the common start that has a file argument
# and wants no dashboard -- the laziness the autoload split exists for.

# Idempotent: VimEnter calls it on every start, and the dashboard footer calls
# it again in case a dashboard renders before VimEnter fires.
export def CaptureMs()
  if !exists('g:chopsticks_startup_ms')
    g:chopsticks_startup_ms = exists('*reltimefloat')
      ? reltimefloat(reltime(g:chopsticks_startup_started_at)) * 1000
      : str2float(reltimestr(reltime(g:chopsticks_startup_started_at))) * 1000
  endif
enddef

# No file arguments, and the buffer Vim made for us is still the untouched
# unnamed one.
export def MaybeOpenDashboard()
  if g:ChopsticksDashboardEnabled() && argc() == 0
      && bufname('%') ==# '' && &buftype ==# ''
      && line('$') == 1 && getline(1) ==# '' && !&modified
    chopsticks#ui#dashboard#Open()
  endif
enddef
