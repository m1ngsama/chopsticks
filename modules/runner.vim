" runner.vim — project-aware run and task helpers

function! s:RunnerSpecs() abort
    return [
        \ {'ft': 'python', 'cmd': 'python3', 'run': 'python3 %s',
        \  'label': 'python file'},
        \ {'ft': 'javascript', 'cmd': 'node', 'run': 'node %s',
        \  'label': 'javascript file'},
        \ {'ft': 'typescript', 'cmd': 'npx', 'run': 'npx ts-node %s',
        \  'label': 'typescript file'},
        \ {'ft': 'go', 'cmd': 'go', 'run': 'go run %s',
        \  'label': 'go file'},
        \ {'ft': 'rust', 'cmd': 'cargo', 'run': 'cargo run',
        \  'label': 'rust crate'},
        \ {'ft': 'sh', 'cmd': 'bash', 'run': 'bash %s',
        \  'label': 'shell file'},
        \ {'ft': 'c', 'cmd': 'gcc', 'run': 'gcc temporary binary',
        \  'label': 'c file'},
        \ {'ft': 'lua', 'cmd': 'lua', 'run': 'lua %s',
        \  'label': 'lua file'},
        \ {'ft': 'ruby', 'cmd': 'ruby', 'run': 'ruby %s',
        \  'label': 'ruby file'},
        \ {'ft': 'perl', 'cmd': 'perl', 'run': 'perl %s',
        \  'label': 'perl file'},
        \ ]
endfunction

function! s:RunnerForFiletype(filetype) abort
    for l:runner in s:RunnerSpecs()
        if get(l:runner, 'ft', '') ==# a:filetype
            return copy(l:runner)
        endif
    endfor
    return {}
endfunction

function! s:SupportedFiletypes() abort
    let l:filetypes = []
    for l:runner in s:RunnerSpecs()
        call add(l:filetypes, get(l:runner, 'ft', ''))
    endfor
    return join(l:filetypes, ', ')
endfunction

function! s:FallbackRunMapSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'lhs': '<Space>rr', 'key': 'SPC rr', 'text': 'ChopsticksRun'},
            \ {'lhs': '<Space>rt', 'key': 'SPC rt', 'text': 'ChopsticksRunTask'},
            \ {'lhs': '<Space>rl', 'key': 'SPC rl', 'text': 'ChopsticksRunLast'},
            \ ]
    endif
    return [
        \ {'lhs': ',cr', 'key': ',cr', 'text': 'ChopsticksRun'},
        \ {'lhs': ',ct', 'key': ',ct', 'text': 'ChopsticksRunTask'},
        \ {'lhs': ',cR', 'key': ',cR', 'text': 'ChopsticksRunLast'},
        \ ]
endfunction

function! s:FallbackRunKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
        \ ? ['SPC rr', 'SPC rt', 'SPC rl']
        \ : [',cr', ',ct', ',cR']
endfunction

function! s:RunMapSpecs() abort
    let l:fallback = s:FallbackRunMapSpecs()
    let l:specs = []
    call extend(l:specs, ChopsticksKeymapContractSpecsOr('project_run',
        \ [l:fallback[0]]))
    call extend(l:specs, ChopsticksKeymapContractSpecsOr(
        \ 'project_task_picker', [l:fallback[1]]))
    call extend(l:specs, ChopsticksKeymapContractSpecsOr(
        \ 'project_run_last', [l:fallback[2]]))
    return l:specs
endfunction

function! s:RunKey() abort
    let l:fallback = get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC rr' : ',cr'
    return get(ChopsticksKeymapContractKeysOr('project_run',
        \ s:FallbackRunKeys()), 0, l:fallback)
endfunction

function! s:TaskPickerKey() abort
    let l:fallback = get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC rt' : ',ct'
    return get(ChopsticksKeymapContractKeysOr('project_task_picker',
        \ [l:fallback]), 0, l:fallback)
endfunction

function! s:LastRunKey() abort
    let l:fallback = get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC rl' : ',cR'
    return get(ChopsticksKeymapContractKeysOr('project_run_last',
        \ [l:fallback]), 0, l:fallback)
endfunction

function! s:MissingRunMaps() abort
    return ChopsticksKeymapMissingKeys(s:RunMapSpecs())
endfunction

function! s:NormalizeDir(path) abort
    let l:path = fnamemodify(empty(a:path) ? getcwd() : a:path, ':p')
    let l:path = substitute(l:path, '/\+$', '', '')
    return empty(l:path) ? '/' : l:path
endfunction

function! s:ProjectRoot() abort
    let l:start = expand('%:p')
    let l:dir = empty(l:start)
        \ ? getcwd()
        \ : (isdirectory(l:start) ? l:start : fnamemodify(l:start, ':h'))
    let l:dir = s:NormalizeDir(l:dir)
    let l:markers = ['.git', 'package.json', 'Makefile', 'makefile',
        \ 'Cargo.toml', 'go.mod']

    while 1
        for l:marker in l:markers
            let l:path = l:dir . '/' . l:marker
            if filereadable(l:path) || isdirectory(l:path)
                return l:dir
            endif
        endfor
        let l:parent = s:NormalizeDir(fnamemodify(l:dir, ':h'))
        if l:parent ==# l:dir
            break
        endif
        let l:dir = l:parent
    endwhile
    return s:NormalizeDir(getcwd())
endfunction

function! s:Task(label, cmd, cwd, source, kind) abort
    return {
        \ 'label': a:label,
        \ 'cmd': a:cmd,
        \ 'cwd': s:NormalizeDir(a:cwd),
        \ 'source': a:source,
        \ 'kind': a:kind,
        \ }
endfunction

function! s:FileRunnerTask() abort
    let l:runner = s:RunnerForFiletype(&filetype)
    if empty(l:runner)
        return {}
    endif
    if !ChopsticksToolAvailable(get(l:runner, 'cmd', ''))
        let l:missing = copy(l:runner)
        let l:missing.missing = get(l:runner, 'cmd', '')
        return l:missing
    endif

    let l:file = expand('%:p')
    if empty(l:file)
        return {}
    endif
    let l:cwd = s:ProjectRoot()
    if get(l:runner, 'ft', '') ==# 'c'
        let l:out_path = tempname()
        let l:task = s:Task(get(l:runner, 'label', 'c file'),
            \ 'gcc -o ' . shellescape(l:out_path) . ' '
            \ . shellescape(l:file) . ' && ' . shellescape(l:out_path),
            \ fnamemodify(l:file, ':h'), 'filetype:c', 'file')
        let l:task.cleanup = l:out_path
        return l:task
    endif

    let l:run = get(l:runner, 'run', '')
    let l:cmd = stridx(l:run, '%s') >= 0
        \ ? printf(l:run, shellescape(l:file))
        \ : l:run
    return s:Task(get(l:runner, 'label', &filetype . ' file'),
        \ l:cmd, l:cwd, 'filetype:' . &filetype, 'file')
endfunction

function! s:JsonFile(path) abort
    if !exists('*json_decode') || !filereadable(a:path)
        return {}
    endif
    try
        let l:data = json_decode(join(readfile(a:path), "\n"))
    catch
        return {}
    endtry
    return type(l:data) == type({}) ? l:data : {}
endfunction

function! s:AddPackageTasks(tasks, root) abort
    let l:path = a:root . '/package.json'
    if !filereadable(l:path) || !ChopsticksToolAvailable('npm')
        return
    endif
    let l:data = s:JsonFile(l:path)
    let l:scripts = get(l:data, 'scripts', {})
    if type(l:scripts) != type({})
        return
    endif
    for l:name in ['test', 'lint', 'typecheck', 'build']
        if has_key(l:scripts, l:name)
            let l:cmd = l:name ==# 'test'
                \ ? 'npm test'
                \ : 'npm run ' . shellescape(l:name)
            call add(a:tasks, s:Task('npm ' . l:name, l:cmd, a:root,
                \ 'package.json', l:name ==# 'test' ? 'test' : 'project'))
        endif
    endfor
endfunction

function! s:MakeTargets(path) abort
    if !filereadable(a:path)
        return []
    endif
    let l:targets = []
    for l:line in readfile(a:path)
        if l:line =~# '^[A-Za-z0-9_.-]\+:'
            let l:target = matchstr(l:line, '^[A-Za-z0-9_.-]\+')
            if index(l:targets, l:target) < 0
                call add(l:targets, l:target)
            endif
        endif
    endfor
    return l:targets
endfunction

function! s:AddMakeTasks(tasks, root) abort
    let l:path = filereadable(a:root . '/Makefile')
        \ ? a:root . '/Makefile'
        \ : a:root . '/makefile'
    if !filereadable(l:path) || !ChopsticksToolAvailable('make')
        return
    endif
    let l:targets = s:MakeTargets(l:path)
    for l:target in ['test', 'lint', 'typecheck', 'build', 'run']
        if index(l:targets, l:target) >= 0
            call add(a:tasks, s:Task('make ' . l:target,
                \ 'make ' . shellescape(l:target), a:root, 'Makefile',
                \ l:target ==# 'test' ? 'test' : 'project'))
        endif
    endfor
    call add(a:tasks, s:Task('make', 'make', a:root, 'Makefile', 'project'))
endfunction

function! s:AddCargoTasks(tasks, root) abort
    if !filereadable(a:root . '/Cargo.toml') || !ChopsticksToolAvailable('cargo')
        return
    endif
    call add(a:tasks, s:Task('cargo test', 'cargo test', a:root,
        \ 'Cargo.toml', 'test'))
    call add(a:tasks, s:Task('cargo build', 'cargo build', a:root,
        \ 'Cargo.toml', 'project'))
    call add(a:tasks, s:Task('cargo run', 'cargo run', a:root,
        \ 'Cargo.toml', 'project'))
endfunction

function! s:AddGoTasks(tasks, root) abort
    if !filereadable(a:root . '/go.mod') || !ChopsticksToolAvailable('go')
        return
    endif
    let l:file = expand('%:p')
    let l:file_dir = empty(l:file) ? a:root : fnamemodify(l:file, ':h')
    call add(a:tasks, s:Task('go test ./...', 'go test ./...', a:root,
        \ 'go.mod', 'test'))
    call add(a:tasks, s:Task('go test', 'go test', l:file_dir,
        \ 'go.mod', 'test'))
    call add(a:tasks, s:Task('go run .', 'go run .', a:root,
        \ 'go.mod', 'project'))
endfunction

function! s:UniqueTasks(tasks) abort
    let l:seen = {}
    let l:tasks = []
    for l:task in a:tasks
        let l:key = get(l:task, 'cwd', '') . '|' . get(l:task, 'cmd', '')
        if has_key(l:seen, l:key)
            continue
        endif
        let l:seen[l:key] = 1
        call add(l:tasks, l:task)
    endfor
    return l:tasks
endfunction

function! s:ProjectTasks() abort
    let l:root = s:ProjectRoot()
    let l:tasks = []
    call s:AddPackageTasks(l:tasks, l:root)
    call s:AddMakeTasks(l:tasks, l:root)
    call s:AddCargoTasks(l:tasks, l:root)
    call s:AddGoTasks(l:tasks, l:root)
    return s:UniqueTasks(l:tasks)
endfunction

function! s:ContextTasks() abort
    let l:tasks = []
    let l:file = s:FileRunnerTask()
    if !empty(l:file) && !has_key(l:file, 'missing')
        call add(l:tasks, l:file)
    endif
    call extend(l:tasks, s:ProjectTasks())
    return s:UniqueTasks(l:tasks)
endfunction

function! s:BestTask() abort
    let l:tasks = s:ContextTasks()
    return empty(l:tasks) ? {} : l:tasks[0]
endfunction

function! s:SaveCurrentFile() abort
    if &buftype ==# '' && !empty(expand('%:p'))
        silent update
    endif
endfunction

function! s:RunTask(task) abort
    if empty(a:task)
        echo 'No runnable file or project task found'
        return 0
    endif

    call s:SaveCurrentFile()
    let s:last_task = copy(a:task)
    let g:chopsticks_last_run_task = copy(a:task)
    let l:cwd = get(a:task, 'cwd', getcwd())
    let l:cmd = get(a:task, 'cmd', '')
    let l:label = get(a:task, 'label', l:cmd)
    let l:save_cwd = getcwd()
    let l:lines = []
    let l:status = 0

    try
        execute 'lcd ' . fnameescape(l:cwd)
        let l:lines = systemlist(l:cmd)
        let l:status = v:shell_error
    catch
        let l:status = 1
        let l:lines = ['chopsticks run failed: ' . v:exception]
    finally
        if has_key(a:task, 'cleanup')
            call delete(get(a:task, 'cleanup', ''))
        endif
        execute 'lcd ' . fnameescape(l:save_cwd)
    endtry

    if empty(l:lines)
        call add(l:lines, 'chopsticks: ' . l:label . ' finished with no output')
    endif
    call setqflist([], 'r', {
        \ 'title': 'chopsticks: ' . l:label . ' :: ' . l:cmd,
        \ 'lines': l:lines,
        \ })
    cwindow
    if l:status
        echohl ErrorMsg
        echom 'Run failed: ' . l:label
        echohl None
        return 0
    endif
    echom 'Run passed: ' . l:label
    return 1
endfunction

function! s:RunCurrent() abort
    return s:RunTask(s:BestTask())
endfunction

function! s:RunLast() abort
    let l:last = get(g:, 'chopsticks_last_run_task', {})
    if empty(l:last)
        let l:last = get(s:, 'last_task', {})
    endif
    return s:RunTask(l:last)
endfunction

function! s:PickTask() abort
    let l:tasks = s:ContextTasks()
    if empty(l:tasks)
        echo 'No runnable file or project task found'
        return 0
    endif
    let l:lines = ['chopsticks tasks:']
    let l:index = 1
    for l:task in l:tasks
        call add(l:lines, printf('%d. %s  [%s]', l:index,
            \ get(l:task, 'label', get(l:task, 'cmd', 'task')),
            \ get(l:task, 'cmd', '')))
        let l:index += 1
    endfor
    let l:choice = inputlist(l:lines)
    if l:choice < 1 || l:choice > len(l:tasks)
        echo 'Run cancelled'
        return 0
    endif
    return s:RunTask(l:tasks[l:choice - 1])
endfunction

function! s:CurrentRunnerItem(filetype, runner, missing_maps) abort
    if !empty(a:missing_maps)
        return ChopsticksInfoDiagnosticItem('current file', 'missing',
            \ 'missing: ' . join(a:missing_maps, ', '), 'run keymap',
            \ ':ChopsticksKeymapAudit', {
            \ 'detail': 'missing project run map: ' . join(a:missing_maps, ', '),
            \ })
    endif
    if empty(a:filetype)
        return ChopsticksInfoItem('current file', 'off', 'no filetype', {
            \ 'diagnostic': 0,
            \ })
    endif
    if empty(a:runner)
        return ChopsticksInfoItem('current file', 'off',
            \ 'unsupported filetype: ' . a:filetype, {
            \ 'value': a:filetype,
            \ 'diagnostic': 0,
            \ })
    endif

    let l:cmd = get(a:runner, 'cmd', '')
    if ChopsticksToolAvailable(l:cmd)
        return ChopsticksInfoItem('current file', 'ready', l:cmd, {
            \ 'value': a:filetype,
            \ 'diagnostic': 0,
            \ })
    endif

    return ChopsticksInfoDiagnosticItem('current file', 'missing',
        \ 'missing: ' . l:cmd, a:filetype . ' runner',
        \ 'install: ' . l:cmd, {
        \ 'value': a:filetype,
        \ 'severity': 'setup',
        \ 'detail': 'missing runner command: ' . l:cmd,
        \ })
endfunction

function! s:ProjectTaskItem(tasks) abort
    if empty(a:tasks)
        return ChopsticksInfoItem('project tasks', 'off',
            \ 'no project task detected', {'diagnostic': 0})
    endif
    return ChopsticksInfoItem('project tasks', 'ready',
        \ len(a:tasks) . ' detected', {
        \ 'diagnostic': 0,
        \ 'value': len(a:tasks),
        \ })
endfunction

function! s:LastTaskItem() abort
    let l:last = get(g:, 'chopsticks_last_run_task', {})
    if empty(l:last)
        return ChopsticksInfoItem('last run', 'off', 'none yet',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoItem('last run', 'ready',
        \ get(l:last, 'label', get(l:last, 'cmd', 'task')),
        \ {'diagnostic': 0})
endfunction

function! ChopsticksRunnerInfo() abort
    let l:filetype = &filetype
    let l:runner = s:RunnerForFiletype(l:filetype)
    let l:missing_maps = s:MissingRunMaps()
    let l:run_key = s:RunKey()
    let l:project_tasks = s:ProjectTasks()
    let l:best = s:BestTask()
    return ChopsticksInfoSection('project run', {
        \ 'filetype': l:filetype,
        \ 'keymap': l:run_key,
        \ 'task_picker_keymap': s:TaskPickerKey(),
        \ 'last_keymap': s:LastRunKey(),
        \ 'supported': s:SupportedFiletypes(),
        \ 'runner': l:runner,
        \ 'best_task': l:best,
        \ 'project_tasks': l:project_tasks,
        \ 'project_task_count': len(l:project_tasks),
        \ 'missing_maps': l:missing_maps,
        \ 'details': [
        \   ChopsticksInfoDetail('keymap', l:run_key),
        \   ChopsticksInfoDetail('tasks',
        \       s:TaskPickerKey() . '/' . s:LastRunKey()),
        \   ChopsticksInfoDetail('current',
        \       empty(l:filetype) ? 'none' : l:filetype),
        \   ChopsticksInfoDetail('supported',
        \       len(s:RunnerSpecs()) . ' filetypes'),
        \ ],
        \ 'items': [
        \   s:CurrentRunnerItem(l:filetype, l:runner, l:missing_maps),
        \   s:ProjectTaskItem(l:project_tasks),
        \   s:LastTaskItem(),
        \ ],
        \ })
endfunction

function! ChopsticksRunnerTasks() abort
    return s:ContextTasks()
endfunction

command! ChopsticksRun call s:RunCurrent()
command! ChopsticksRunTask call s:PickTask()
command! ChopsticksRunLast call s:RunLast()

if g:chopsticks_space_keymaps
    nnoremap <leader>rr :ChopsticksRun<CR>
    nnoremap <leader>rt :ChopsticksRunTask<CR>
    nnoremap <leader>rl :ChopsticksRunLast<CR>
else
    nnoremap <leader>cr :ChopsticksRun<CR>
    nnoremap <leader>ct :ChopsticksRunTask<CR>
    nnoremap <leader>cR :ChopsticksRunLast<CR>
endif
