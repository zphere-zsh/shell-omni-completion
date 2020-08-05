" FUNCTION: ZshOmniComplBufInit()
" A function that's called when the buffer is loaded and its filetype is known.
" It initializes the omni completion for the buffer.
function ZshOmniComplBufInit()
    let b:zoc_call_count = 0
    let [ b:zoc_last_fccount, b:zoc_last_pccount, b:zoc_last_kccount ] = [ [-1], [-1], [-1] ]
    let b:zoc_last_ccount_vars = [ b:zoc_last_fccount, b:zoc_last_pccount, b:zoc_last_kccount ]
    if &ft == 'zsh'
        setlocal omnifunc=ZshComplete
    endif
endfunction

" FUNCTION: ZshComplete()
" The main function of this plugin (assigned to the `omnifunc` set option) that
" has the main task to perform the omni-completion, i.e.: to return the list of
" matches to the text before the cursor.
function ZshComplete(findstart, base)
    if a:findstart
        let three_results = [ CompleteZshFunctions(1, a:base),
                    \ CompleteZshParameters(1, a:base),
                    \ CompleteZshArrayAndHashKeys(1, a:base) ]
        let result = max( three_results )
        let winner = index( three_results, result )
        " Restart the cyclic renewal of the database variables from the point
        " where the specific object-kind completion finished the cycle in the
        " previous call to ZshComplete.
        let b:zoc_call_count = (b:zoc_last_ccount_vars[winner])[0] + 1
    else
        " Prepare the buffers' contents for processing, if needed (i.e.: on every
        " N-th call, when only also the processing-sequence is being initiated).
        "
        " The update of this buffer-lines cache is synchronized with the other
        " processings, i.e.: it depends on the local (to the buffer) call count
        " of the plugin, however the storage variable is s: -session, to limit the
        " memory usage.
        if b:zoc_call_count % 5 == 0
            let s:zoc_all_buffers_lines = []
            for bufnum in range(last_buffer_nr()+1)
                if buflisted(bufnum)
                    let s:zoc_all_buffers_lines += getbufline(bufnum, 1,"$")
                endif
            endfor
        endif

        let result = []

        if b:zoc_compl_functions_start >= 0 
                let b:zoc_last_fccount[0] = b:zoc_call_count
                let result += CompleteZshFunctions(0, a:base)
        endif

        if b:zoc_compl_parameters_start >= 0 
                let b:zoc_last_pccount[0] = b:zoc_call_count
                let result += CompleteZshParameters(0, a:base)
        endif

        if b:zoc_compl_arrays_keys_start >= 0 
                let b:zoc_last_kcount[0] = b:zoc_call_count
                let result += CompleteZshArrayAndHashKeys(0, a:base)
        endif

        call uniq(sort(result))
    endif
    return result
endfunction

" FUNCTION: CompleteZshFunctions()
" The function is a complete-function which returns matching Zsh-function names.
function CompleteZshFunctions(findstart, base)
    let [l:line_bits,l:line] = s:getPrecedingBits(a:findstart)
    " First call — basically return 0. Additionally (it's unused value),
    " remember the current column.
    if a:findstart
        if l:line_bits[-1] =~ '\v([\$\[]|^[[:space:]]*$)'
            let b:zoc_compl_functions_start = -3
        else
            let b:zoc_compl_functions_start = strridx(l:line, l:line_bits[-1])
            " Support the from-void text completing. It's however disabled on
            " the upper level.
            let b:zoc_compl_functions_start += l:line_bits[-1] =~ '^[[:space:]]$' ? 1 : 0
        endif
        return b:zoc_compl_functions_start
    else
        " Detect the matching Zsh function names and return them.
        return s:completeKeywords(g:ZOC_FUNC, line_bits)
    endif
endfunction

" FUNCTION: CompleteZshParameters()
" The function is a complete-function which returns matching Zsh-parameter names.
function CompleteZshParameters(findstart, base)
    let [l:line_bits,l:line] = s:getPrecedingBits(a:findstart)

    " First call — basically return 0. Additionally (it's unused value),
    " remember the current column.
    if a:findstart
        if l:line_bits[-1] !~ '\v\$'
            let b:zoc_compl_parameters_start = -3
        else
            let b:zoc_compl_parameters_start = strridx(l:line, l:line_bits[-1])
            let b:zoc_compl_parameters_start = b:zoc_compl_parameters_start + stridx(l:line[b:zoc_compl_parameters_start:],'$')
            " Support the from-void text completing. It's however disabled on
            " the upper level.
            let b:zoc_compl_parameters_start += l:line_bits[-1] =~ '^[[:space:]]$' ? 1 : 0
        endif
        return b:zoc_compl_parameters_start
    else
        " Detect the matching Zsh parameter names and return them.
        return s:completeKeywords(g:ZOC_PARAM, line_bits)
    endif
endfunction

" FUNCTION: CompleteZshArrayAndHashKeys()
" The function is a complete-function which returns matching Zsh-parameter names.
function CompleteZshArrayAndHashKeys(findstart, base)
    let [line_bits,line] = s:getPrecedingBits(a:findstart)

    " First call — basically return 0. Additionally (it's unused value),
    " remember the current column.
    if a:findstart
        if l:line_bits[-1] !~ '\v[a-zA-Z0-9_]+\[[^\]]+\]'
            let b:zoc_compl_arrays_keys_start = -3
        else
            let b:zoc_compl_arrays_keys_start = strridx(l:line, l:line_bits[-1])
            let b:zoc_compl_arrays_keys_start = b:zoc_compl_arrays_keys_start + stridx(l:line[b:zoc_compl_arrays_keys_start:],'[') + 1
            " Support the from-void text completing. It's however disabled on
            " the upper level.
            let b:zoc_compl_arrays_keys_start += l:line_bits[-1] =~ '^[[:space:]]$' ? 1 : 0
        endif
        return b:zoc_compl_arrays_keys_start
    else
        " Detect the matching arrays' and hashes' keys and return them.
        return s:completeKeywords(g:ZOC_KEY, line_bits)
    endif
endfunction

" FUNCTION: CompleteZshArrayAndHashKeys()
" A general-purpose, variadic backend function, which obtains the request on the
" type of the keywords (functions, parameters or array keys) to complete and
" performs the operation. 
function s:completeKeywords(id, line_bits)
    " Retrieve the complete list of Zsh functions in the buffer on every
    " N-th call.
    if (b:zoc_call_count == 0) || ((b:zoc_call_count - a:id + 2) % 10 == 0)
        call s:gatherFunctions[a:id]()
    endif

    " Ensure that the buffer-variables exist
    let to_declare = filter([ "zoc_functions", "zoc_parameters", "zoc_array_and_hash_keys" ], '!exists("b:".v:val)')
    for bufvar in to_declare | let b:[bufvar] = [] | endfor
    let gatherVariables = [ b:zoc_functions, b:zoc_parameters, b:zoc_array_and_hash_keys ]

    " Detect the matching Zsh-object names and store them for returning.
    let result = []
    let a:line_bits[-1] = a:line_bits[-1] =~ '^[[:space:]]$' ? '' : a:line_bits[-1]

    if a:id == g:ZOC_PARAM && a:line_bits[-1] =~ '\v^\$.*'
        let a:line_bits[-1] = (a:line_bits[-1])[1:]
        let pfx='$'
    else
        let pfx=''
    endif

    for the_key in gatherVariables[a:id] 
        if the_key =~# '^' . s:quote(a:line_bits[-1]). '.*'
            call add(result, pfx.the_key)
        endif
    endfor

    return result
endfunction

" FUNCTION: s:gatherFunctionNames()
" Buffer-contents processor for Zsh *function* names. Stores all the detected
" Zsh function names in the list b:zoc_parameters.
function s:gatherFunctionNames()
    " Prepare/zero the buffer variable.
    let b:zoc_functions = []

    " Iterate over the lines in the buffer searching for a function name.
    for l:line in s:zoc_all_buffers_lines
        if l:line =~# '\v^((function[[:space:]]+[^[:space:]]+[[:space:]]*(\(\)|))|([^[:space:]]+[[:space:]]*\(\)))[[:space:]]*(\{|)[[:space:]]*$'
            let l:line = split(l:line)[0]
            let l:line = substitute(l:line,"()","","g")
            call add(b:zoc_functions, l:line)
        endif
    endfor

    " Uniqify the resulting list of Zsh function names. The uniquification
    " requires also sorting the input list.
    call uniq(sort(b:zoc_functions))
endfunction

" FUNCTION: s:gatherParameterNames()
" Buffer-contents processor for Zsh *parameter* names. Stores all the detected
" Zsh parameter names in the list b:zoc_parameters.
function s:gatherParameterNames()
    " Prepare/zero the buffer variable.
    let b:zoc_parameters = []

    " Iterate over the lines in the buffer searching for a Zsh parameter name.
    for l:line in s:zoc_all_buffers_lines
        if l:line =~# '\v\$(\{|)([#+^=~]{1,2}){0,1}(\([a-zA-Z0-9_:@%.\|;#~]+\)){0,1}#{0,1}[a-zA-Z0-9_]+'
            let l:param = substitute(l:line, '\v.*\$(\{|)([#+^=~]{1,2}){0,1}(\([a-zA-Z0-9_:@%.\|;#~]+\)){0,1}#{0,1}([a-zA-Z0-9_]+).*','\4',"g")
            call add(b:zoc_parameters, l:param)
        endif
    endfor

    " Uniqify the resulting list of Zsh parameter names. The uniquification
    " requires also sorting the input list.
    call uniq(sort(b:zoc_parameters))
endfunction

" FUNCTION: s:gatherArrayAndHashKeys()
" Buffer-contents processor for Zsh *parameter* names. Stores all the detected
" Zsh parameter names in the list b:zoc_parameters.
function s:gatherArrayAndHashKeys()
    " Prepare/zero the buffer variable.
    let b:zoc_array_and_hash_keys = []

    " Iterate over the lines in the buffer searching for a Zsh parameter name.
    for line in s:zoc_all_buffers_lines
        let idx=0
        let idx = match(line, '\v[a-zA-Z0-9_]+\[[^\]]+\]', idx)
        while idx >= 0
            let res_list = matchlist(line, '\v[a-zA-Z0-9_]+\[([^\]]+)\]', idx)
            call add(b:zoc_array_and_hash_keys, res_list[1])
            let idx = match(line, '\v[a-zA-Z0-9_]+\[[^\]]+\]', idx+len(res_list[1])+2)
        endwhile
    endfor

    " Uniqify the resulting list of Zsh parameter names. The uniquification
    " requires also sorting the input list.
    call uniq(sort(b:zoc_array_and_hash_keys))
endfunction

" FUNCTION: s:quote()
" A function which quotes the regex-special characters with a backslash, which
" makes them inactive, literal characters in the very-magic mode (… =~ " '\v…').
function s:quote(str)
    return substitute(
                \     substitute(
                \        substitute(
                \            substitute(
                \                substitute(
                \                    substitute(
                \                        substitute(
                \                            a:str,
                \                            "\v\\\\","\\\\", "g"
                \                        ), '\v\{','\{', "g"
                \                    ), '\v\]','\]', "g"
                \                ), '\v\[','\[', "g"
                \            ), '\v\*','\*', "g"
                \        ),'\v\+','\+', "g"
                \     ),'\v\.','\.', "g"
                \ )
endfunction

" The idea of this completion plugin is the following:
" - SomeTextSomeText SomeOtherText
"   ……………………↑ <the cursor>.
" What will be completed, will be:
" - the matching keywords (functions, parameters, etc.) that match:
"   SomeTextSomeText,
" - so the completion takes the whole part in which the cursor currently is
"   being located, not only the preceding part.
function s:getPrecedingBits(findstart)
    if a:findstart
        let l:line = getbufline(bufnr(), line("."))[0]
        let b:zoc_curline = l:line
        let l:curs_col = col(".")
        let b:zoc_cursor_col = l:curs_col 
    else
        let l:line = b:zoc_curline
        let l:curs_col = b:zoc_cursor_col
    endif

    let l:line_bits = split(l:line,'\v[[:space:]\[\]\{\}\(\);\|\&\#\%\=\^!\*\<\>\"'."\\'".']')
    let l:line_bits = len(l:line_bits) >= 1 ? l:line_bits : [len(l:line) > 0 ? (l:line)[len(l:line)-1] : ""]

    if len(l:line_bits) > 1
        " Locate the *active*, *hot* bit in which the cursor is being placed.
        let l:count = len(l:line_bits)
        let l:work_line = l:line
        for l:bit in reverse(copy(l:line_bits))
            let l:idx = strridx(l:work_line, l:bit)
            if l:idx <= l:curs_col - 2
                " Return a sublist with the preceding elements up to the active,
                " *hot* bit.
                return [l:line_bits[0:l:count], l:line]
            endif
            let l:work_line = l:work_line[0:l:idx-1]
            let l:count -= 1
        endfor
    endif
    return [l:line_bits, l:line]
endfunction

"""""""""""""""""" THE SCRIPT BODY

let s:gatherFunctions = [ function("s:gatherFunctionNames"),
            \ function("s:gatherParameterNames"),
            \ function("s:gatherArrayAndHashKeys") ]

augroup ZshOmniComplInitGroup
    au FileType * call ZshOmniComplBufInit()
augroup END

let [ g:ZOC_FUNC, g:ZOC_PARAM, g:ZOC_KEY ] = [ 0, 1, 2 ]

"""""""""""""""""" UTILITY FUNCTIONS

function! Mapped(fn, l)
    let new_list = deepcopy(a:l)
    call map(new_list, string(a:fn) . '(v:val)')
    return new_list
endfunction

function! Filtered(fn, l)
    let new_list = deepcopy(a:l)
    call filter(new_list, string(a:fn) . '(v:val)')
    return new_list
endfunction

function! FilteredNot(fn, l)
    let new_list = deepcopy(a:l)
    call filter(new_list, '!'.string(a:fn) . '(v:val)')
    return new_list
endfunction

function CreateEmptyList(name)
    eval("let ".a:name." = []")
endfunction

" vim:set ft=vim tw=80 et sw=4 sts=4 foldmethod=syntax:
