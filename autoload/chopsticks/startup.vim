vim9script

# Startup timing.
#
# .vimrc records g:chopsticks_startup_started_at in its very first lines, so
# the figure covers everything. This module turns that origin into
# g:chopsticks_startup_ms, once.
#
# It is deliberately its own module rather than part of the dashboard, even
# though the dashboard footer is what displays the number. .vimrc arranges
# for the measurement to be taken at VimEnter whether or not a dashboard is
# ever opened, and calling into the dashboard module to do it would source
# the whole dashboard at every startup, which is exactly the laziness the
# autoload split exists to get.

# Set g:chopsticks_startup_ms from the recorded origin, unless it is already
# set. Idempotent by design: VimEnter calls it on every start, and the
# dashboard footer calls it again in case a dashboard is rendered before
# VimEnter has fired.
export def CaptureMs()
  if !exists('g:chopsticks_startup_ms')
    g:chopsticks_startup_ms = exists('*reltimefloat')
      ? reltimefloat(reltime(g:chopsticks_startup_started_at)) * 1000
      : str2float(reltimestr(reltime(g:chopsticks_startup_started_at))) * 1000
  endif
enddef

# Whether this start should land on the dashboard rather than an empty
# buffer: no file arguments, and the buffer Vim created for us is still the
# untouched, unnamed one.
#
# The decision lives here, not in the dashboard module, purely so the
# dashboard stays lazy. This module is already loaded at VimEnter for the
# timer above, and these checks are a handful of option and buffer reads.
# Asking the dashboard module to decide would source all of its rendering,
# cursor-locking, and item-action code on every single start, including the
# overwhelmingly common one where a file argument means no dashboard is
# wanted at all.
export def MaybeOpenDashboard()
  if g:ChopsticksDashboardEnabled() && argc() == 0
      && bufname('%') ==# '' && &buftype ==# ''
      && line('$') == 1 && getline(1) ==# '' && !&modified
    chopsticks#ui#dashboard#Open()
  endif
enddef
