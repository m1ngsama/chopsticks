" Guards against a silent Vim9script trap.
"
" In Vim9script a bare function name refers to the SCRIPT-local function, so
" exists('*FugitiveHead') asks whether this file defines FugitiveHead and
" answers 0 however many plugins define the global. Nothing errors and
" nothing compiles differently -- the guarded feature simply never turns on.
" Three guards in this repository were stuck false that way, and only one of
" them had a test that noticed.
"
" A global from a plugin, or one of ours defined in .vimrc, must be spelled
" exists('*g:Name'). Builtins are exempt, because they are not script-level
" names in the first place. So is any autoload-style name containing '#',
" whose lookup Vim defers either way.
"
" Run with -u NONE so that the only functions in existence are builtins:
" that is precisely the exemption this check needs to recognise.

" Before anything with a line continuation in it. This runs under -u NONE,
" which leaves Vim in compatible mode, and 'cpoptions' then contains C --
" which disables continuations and made every one below a syntax error.
set cpoptions&vim

let s:root = $CHOPSTICKS_ROOT
let s:failures = []

function! s:IsBuiltin(name) abort
    return index(getcompletion(a:name, 'function'), a:name . '(') >= 0
endfunction

" A bare name is one starting with a letter or underscore and running to the
" closing quote. 'g:Name' fails to match because ':' ends the run before the
" quote, and 'ale#statusline#Count' fails for the same reason at '#' -- which
" is how both exempt spellings are skipped without naming them.
function! s:BareNames(line) abort
    let l:names = []
    for l:quote in ["'", '"']
        let l:pattern = 'exists(' . l:quote . '\*\zs[A-Za-z_][A-Za-z0-9_]*\ze'
            \ . l:quote
        let l:start = 0
        while 1
            let l:found = matchstrpos(a:line, l:pattern, l:start)
            if l:found[1] < 0
                break
            endif
            call add(l:names, l:found[0])
            let l:start = l:found[2]
        endwhile
    endfor
    return l:names
endfunction

for s:path in sort(glob(s:root . '/autoload/**/*.vim', 0, 1)
    \ + glob(s:root . '/plugin/*.vim', 0, 1))
    let s:lines = readfile(s:path)
    " Legacy files are exempt: there a bare name IS the global one.
    if empty(s:lines) || s:lines[0] !~# '^vim9script\>'
        continue
    endif
    let s:number = 0
    for s:line in s:lines
        let s:number += 1
        if s:line =~# '^\s*#'
            continue
        endif
        for s:name in s:BareNames(s:line)
            if s:IsBuiltin(s:name)
                continue
            endif
            call add(s:failures, printf(
                \ '%s:%d: exists(''*%s'') is always false in Vim9script; '
                \ . 'write exists(''*g:%s'')',
                \ substitute(s:path, '^' . escape(s:root, '\') . '/', '', ''),
                \ s:number, s:name, s:name))
        endfor
    endfor
endfor

if !empty(s:failures)
    call writefile(s:failures, $CHOPSTICKS_ERRORS)
    cquit
endif
qall!
