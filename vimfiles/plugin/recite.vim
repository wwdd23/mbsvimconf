

function! GenRandom(range)
    let time = reltimestr(reltime())
    let ms = matchstr(time,'\..*$')
    let ms = ms[1:]
    let ms = ms[5].ms[4].ms[3].ms[2].ms[1].ms[0]
    let result = ms*a:range/1000000
    return result
endfunction


function! NextSentense()
    if s:index >= len(s:recited)
        let next = GenRandom(s:len)
        let s:recited += [next]
    endif
    let s:index = s:index + 1
    let s:status = 0
    call ShowSentense()
endfunction

function! PreviousSentense()
    if s:index > 1
        let s:index = s:index - 1
        let s:status = 0
        call ShowSentense()
    endif
endfunction

function! ShowSentense()
    if len(s:recited) == 0
        return
    endif
    setlocal noreadonly
    setlocal modifiable
    silent normal! ggdG
    if s:status == 0
        call append(0," ".s:dict[s:recited[s:index-1]*2+1].'~')
        let s:status = 1
    else
        call append(0," ".s:dict[s:recited[s:index-1]*2])
        call append(0,'>')
        call append(0," ".s:dict[s:recited[s:index-1]*2+1].'~')
        let s:status = 0
    endif
    setlocal readonly
    setlocal nomodifiable
endfunction

function! StartRecite()
    let s:raw = getline(0,999999)
    let s:dict = []
    for s:line in s:raw
       if match(s:line,'^\s*$') != -1
           continue
       else
           let s:dict += [s:line]
       endif
    endfor

    let s:len = len(s:dict) / 2
    let s:index = 0
    let s:recited = []
    let s:status = 0

    nmap <buffer> j :call NextSentense()<cr>
    nmap <buffer> k :call PreviousSentense()<cr>
    nmap <buffer> <space> :call ShowSentense()<cr>

    setlocal lbr
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nobuflisted
    setlocal nonumber
    setlocal filetype=help

    call NextSentense()

endfunction

nnoremap <c-F12> :call StartRecite()<cr>

