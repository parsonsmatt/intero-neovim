scriptencoding utf-8
"""""""""""
" Targets:
"
" This file contains functions for working with the Intero load targets. A
" target is something like a library, executable, benchmark, or test suite
" component of a Haskell package.
"""""""""""

if (!exists('g:intero_load_targets'))
    " A list of load targets.
    let g:intero_load_targets = []
endif

" Attempt to set the load targets. When passed an empty array, this uses the
" targets as given by `stack ide targets`.
function! intero#targets#set_load_targets(targets) abort
    if len(a:targets) == 0
        let g:intero_load_targets = intero#targets#load_targets_from_stack()
        return g:intero_load_targets
    endif

    " if stack targets are empty, then we are not in a stack project.
    " attempting to set the targets will cause the build command to fail.
    let l:stack_targets = intero#targets#load_targets_from_stack()
    if empty(l:stack_targets)
        let g:intero_load_targets = []
        return g:intero_load_targets
    endif

    let l:valid_target_dict = {}
    " we are in a stack project, and there are desired targets. validate that
    " they are contained inside the stack load targets
    for l:target in a:targets
        if index(l:stack_targets, l:target) == -1
            " Interpret this as a regex and add all matching targets to the
            " list.
            let l:matches = filter(copy(l:stack_targets), 'v:val =~ l:target')
            for l:match in l:matches
                let l:valid_target_dict[l:match] = 1
            endfor
        else
            let l:valid_target_dict[l:target] = 1
        endif
    endfor

    let g:intero_load_targets = keys(l:valid_target_dict)
    return g:intero_load_targets
endfunction

function! intero#targets#enable_all_targets() abort
    call intero#targets#set_load_targets([])
endfunction

function! intero#targets#get_load_targets() abort
    return g:intero_load_targets
endfunction

function! intero#targets#load_targets_as_string() abort
    return join(intero#targets#get_load_targets(), ' ')
endfunction

function! intero#targets#load_targets_from_stack() abort
    return systemlist('stack ide targets')
endfunction

function! intero#targets#prompt_for_targets() abort
    let l:stack_targets = intero#targets#load_targets_from_stack()
    let l:current_targets = deepcopy(g:intero_load_targets)

    " Construct the target list.
    " type is: [{'target': target name, 'selected': bool}]
    let l:prompt = 'Toggle the target by entering the number and pressing Enter (enter with nothing confirms the current selection)'
    let l:target_list = s:create_initial_target_list()

    " Render the target list
    let l:menu = [l:prompt] + s:render_target_list(l:target_list)

    let l:selected = 1

    let l:selected = inputlist(l:menu)

    " l:selected of 0 means that the user didn't select anything, so we
    " are done here and can return.
    while l:selected > 0 && l:selected < len(l:target_list) + 1
        " because the prompt is given in the inputlist, we have to substract one to
        " the index that was given to select the appropriate index.
        let l:actual_selected = l:selected - 1
        let l:is_selected = l:target_list[l:actual_selected]['selected']
        let l:target_list[l:actual_selected]['selected'] = ! l:is_selected

        let l:menu = [l:prompt] + s:render_target_list(l:target_list)
        let l:selected = inputlist(l:menu)
    endwhile

    " Now that the while loop has exited, we need to enable or disable the
    " targets as appropriate.
    return map(filter(l:target_list, "v:val['selected']"), "v:val['target']")
endfunction

" Returns a list of available targets, along with whether or not they're
" currently selected.
" Type: () -> [{'target': string, 'selected': bool, 'index': int}]
function! s:create_initial_target_list() abort
    let l:stack_targets = intero#targets#load_targets_from_stack()
    let l:current_targets = deepcopy(g:intero_load_targets)

    let l:target_list = []
    let l:index = 1
    for l:target in l:stack_targets
        let l:selected = index(l:current_targets, l:target) >= 0 ? 1 : 0
        call add(l:target_list, {
            \ 'target': l:target,
            \ 'selected': l:selected,
            \ 'index': l:index,
            \ })
        let l:index += 1
    endfor

    return l:target_list
endfunction

" Type: [{'target': string, 'selected': bool, 'index': int}] -> [string]
function! s:render_target_list(target_list) abort
    let l:ret = []
    for l:target in a:target_list
        call add(l:ret, s:render_target(l:target))
    endfor
    return l:ret
endfunction

" Type: {'target': string, 'selected': bool} -> string
function! s:render_target(target) abort
    let l:selchar = a:target['selected'] ? ' ✔ ' : '   '
    let l:index = printf('%3d. ', a:target['index'])
    return l:selchar . l:index . a:target['target']
endfunction



" vim: set ts=4 sw=4 et fdm=marker:
