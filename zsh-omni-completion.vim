" FUNCTION: ZshComplete()
" The main function of this plugin (assigned to the `omnifunc` set option) that
" has the main task to perform the omni-completion, i.e.: to return the list of
" matches to the text before the cursor.
function ZshComplete(findstart, base)
    if a:findstart
        let result = CompleteZshFunctions(1, a:base)
        let result = CompleteZshParameters(1, a:base)
    else
        " Prepare the buffer contents for processing, if needed (i.e.: on every
        " N-th call, when only also the processing is being done).
        if s:call_count % 5 == 0
            let b:zv_all_buffers_lines = getbufline(bufnr(), 1,"$")
        endif
        let result = CompleteZshFunctions(0, a:base)
        let result += CompleteZshParameters(0, a:base)
        let s:call_count += 1
        call sort(result)
    endif
    return result
endfunction

" FUNCTION: CompleteZshFunctions()
" The function is a complete-function which returns matching Zsh-function names.
function CompleteZshFunctions(findstart, base)
    if a:findstart
        let l:line = getbufline(bufnr(), line("."))
    else
        let l:line = b:zv_curline
    endif

    let l:line_bits = split(l:line[0],'\v[[:space:]\[\]\{\}\(\);\|\&\#\%\=\^!\*\<\>]')
    let l:line_bits = len(l:line_bits) >= 1 ? l:line_bits : [len(l:line[0]) > 0 ? (l:line[0])[len(l:line[0])-1] : ""]

    " First call — basically return 0. Additionally (it's unused value),
    " remember the current column.
    if a:findstart
        let b:zv_compl_1_start = strridx(l:line[0], l:line_bits[-1])
        let b:zv_compl_1_start += l:line_bits[-1] =~ '^[[:space:]]$' ? 1 : 0
        return l:line_bits[-1] =~ '\v^[[:space:]]*$' ? -3 : b:zv_compl_1_start
    else
        " Retrieve the complete list of Zsh functions in the buffer on every
        " N-th call.
        if s:call_count % 5 == 0
            call s:gatherFunctionNames()
        endif

        " Detect the matching function names and store them for the returning.
        let l:result = []
        let l:line_bits[-1] = l:line_bits[-1] =~ '^[[:space:]]$' ? '' : l:line_bits[-1]
        for l:func_name in b:zv_functions
            if l:func_name =~# '^' . s:quote(l:line_bits[-1]) . '.*'
                call add(l:result, l:func_name)
            endif
        endfor

        return l:result
    endif
endfunction

" FUNCTION: CompleteZshParameters()
" The function is a complete-function which returns matching Zsh-parameter names.
function CompleteZshParameters(findstart, base)
    if a:findstart
        let l:line = getbufline(bufnr(), line("."))
        " Remember the line, because when this function returns 0 then in the
        " next call to this function the getbufline() will return an empty
        " string, which is very weird…
        let b:zv_curline = l:line
    else
        let l:line = b:zv_curline
    endif

    let l:line_bits = split(l:line[0],'\v[[:space:]\[\]\{\}\(\);\|\&\#\%\=\^!\*\<\>]')
    let l:line_bits = len(l:line_bits) >= 1 ? l:line_bits : [len(l:line[0]) > 0 ? (l:line[0])[len(l:line[0])-1] : ""]

    " First call — basically return 0. Additionally (it's unused value),
    " remember the current column.
    if a:findstart
        let b:zv_compl_2_start = strridx(l:line[0], l:line_bits[-1])
        let b:zv_compl_2_start += l:line_bits[-1] =~ '^[[:space:]]$' ? 1 : 0
        return l:line_bits[-1] =~ '\v^[[:space:]]*$' ? -3 : b:zv_compl_2_start
    else
        " Retrieve the complete list of Zshell parameters in the buffer on every
        " N-th call.
        if s:call_count % 5 == 0
            call s:gatherParameterNames()
        endif

        " Detect the matching Zsh parameter names and store them for the
        " returning.
        let l:result = []
        let l:line_bits[-1] = l:line_bits[-1] =~ '^[[:space:]]$' ? '' : l:line_bits[-1]
        for l:param_name in b:zv_parameters
            if l:param_name =~# '^' . s:quote(l:line_bits[-1]). '.*'
                call add(l:result, l:param_name)
            endif
        endfor

        return l:result
    endif
endfunction

" FUNCTION: s:gatherFunctionNames()
" Buffer-contents processor for Zsh *function* names. Stores all the detected
" Zsh function names in the list b:zv_parameters.
function s:gatherFunctionNames()
    " Prepare/zero the buffer variable.
    let b:zv_functions = []

    " Iterate over the lines in the buffer searching for a function name.
    for l:line in b:zv_all_buffers_lines
        if l:line =~# '\v^((function[[:space:]]+[^[:space:]]+[[:space:]]*(\(\)|))|([^[:space:]]+[[:space:]]*\(\)))[[:space:]]*(\{|)[[:space:]]*$'
            let l:line = split(l:line)[0]
            let l:line = substitute(l:line,"()","","g")
            call add(b:zv_functions, l:line)
        endif
    endfor

    " Uniqify the resulting list of Zsh function names. The uniquification
    " requires also sorting the input list.
    call uniq(sort(b:zv_functions))
endfunction

" FUNCTION: s:gatherParameterNames()
" Buffer-contents processor for Zsh *parameter* names. Stores all the detected
" Zsh parameter names in the list b:zv_parameters.
function s:gatherParameterNames()
    " Prepare/zero the buffer variable.
    let b:zv_parameters = []

    " Iterate over the lines in the buffer searching for a Zsh parameter name.
    for l:line in b:zv_all_buffers_lines
        if l:line =~# '\v\$(\{|)([#+^=~]{1,2}){0,1}(\([a-zA-Z0-9_:@%.\|;#~]+\)){0,1}#{0,1}[a-zA-Z0-9_]+'
            let l:param = substitute(l:line, '\v.*\$(\{|)([#+^=~]{1,2}){0,1}(\([a-zA-Z0-9_:@%.\|;#~]+\)){0,1}#{0,1}([a-zA-Z0-9_]+).*','\4',"g")
            call add(b:zv_parameters, l:param)
        endif
    endfor

    " Uniqify the resulting list of Zsh parameter names. The uniquification
    " requires also sorting the input list.
    call uniq(sort(b:zv_parameters))
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

let s:call_count = 0
set omnifunc=ZshComplete

" vim:set ft=vim tw=80 et sw=4 sts=4 foldmethod=syntax:
