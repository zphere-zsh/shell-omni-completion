
function ZshComplete(findstart, base)
    if a:findstart
        let result = CompleteZshFunctions(1, a:base)
        let result = CompleteZshParameters(1, a:base)
    else
        let result = CompleteZshFunctions(0, a:base)
        let result += CompleteZshParameters(0, a:base)
        let s:call_count += 1
        call sort(result)
    endif
    return result
endfunction

" The function completes Zsh function names.
function CompleteZshFunctions(findstart, base)
    if a:findstart
        let l:line = getbufline(bufnr(), line("."))
    else
        let l:line = b:zv_curline
    endif
    let l:bits = split(l:line[0])
    let l:result = []

    if a:findstart
        let b:zv_compl_1_start = col(".")
        return 0
    else
        if s:call_count % 5 == 0
            call s:gatherFunctionNames()
        endif

        for l:line in b:zv_functions
            if l:line =~# '^' . s:quote(len(l:bits) >= 1 ? l:bits[-1] : "") . '.*'
                call add(l:result, l:line)
            endif
        endfor

        return l:result
    endif
endfunction

" The function completes Zsh function names.
function CompleteZshParameters(findstart, base)
    if a:findstart
        let l:line = getbufline(bufnr(), line("."))
        " Remember the line, because when this function returns
        " 0 then the next call to the getbufline() will return an
        " empty string, which is very weird…
        let b:zv_curline = l:line
    else
        let l:line = b:zv_curline
    endif
 
    let l:bits = split(l:line[0])
    let l:result = []

    if a:findstart
        let b:zv_compl_2_start = stridx(l:line[0], len(l:bits) >= 1 ? l:bits[-1] : "" )
        return b:zv_compl_2_start
    else
    echo a:base
    sleep 1
        if s:call_count % 5 == 0
            call s:gatherParameterNames()
        endif

        for l:line in b:zv_parameters
            if l:line =~# '^' . s:quote(len(l:bits) >= 1 ? l:bits[-1] : "") . '.*'
                call add(l:result, l:line)
            endif
        endfor

        return l:result
    endif
endfunction

function s:gatherFunctionNames()
    let l:all_lines = getbufline(bufnr(), 1,"$")
    let b:zv_functions = []
    " Iterate over the lines in the buffer searching for a function name
    for l:line in l:all_lines
        if l:line =~# '\v^((function[[:space:]]+[^[:space:]]+[[:space:]]*(\(\)|))|([^[:space:]]+[[:space:]]*\(\)))[[:space:]]*(\{|)[[:space:]]*$'
            let l:line = split(l:line)[0]
            let l:line = substitute(l:line,"()","","g")
            call add(b:zv_functions, l:line)
        endif
    endfor
endfunction

function s:gatherParameterNames()
    let l:all_lines = getbufline(bufnr(), 1,"$")
    let b:zv_parameters = []
    " Iterate over the lines in the buffer searching for a function name
    for l:line in l:all_lines
        if l:line =~# '\v\$(\{|)([#+^=~]{1,2}){0,1}(\([a-zA-Z0-9_:@%.\|;#~]+\)){0,1}#{0,1}[a-zA-Z0-9_]+'
            let l:param = substitute(l:line, '\v.*\$(\{|)([#+^=~]{1,2}){0,1}(\([a-zA-Z0-9_:@%.\|;#~]+\)){0,1}#{0,1}([a-zA-Z0-9_]+).*','\4',"g")
            call add(b:zv_parameters, l:param)
        endif
    endfor
endfunction

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
