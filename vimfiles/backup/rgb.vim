"------------------------------------------------------------
" Description: Color test for rgb.txt
" Usage: source this file
" Command: BackColor, accept a color used as background color
"          exmaple :BackColor Sea<TAB> (this will try to complete the input)
" Usage:
"       example
"           :RGB
"           :BackColor gray20
"------------------------------------------------------------


command! -complete=customlist,ColorComplete -nargs=? BackColor call UserInput(<f-args>)
command!    -nargs=0 RGB        call Colorize()
command!    -nargs=0 RGBInvert  call ColorizeInvert()

let s:digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

function! MakeRgb(rgbs)
    let l:r = Dec2Hex(str2nr(a:rgbs[0]))
    let l:g = Dec2Hex(str2nr(a:rgbs[1]))
    let l:b = Dec2Hex(str2nr(a:rgbs[2]))
    return "#" . l:r . l:g . l:b
endfunction

function! ReverseRgb(rgbs)
    let l:r = Dec2Hex(255 - str2nr(a:rgbs[0]))
    let l:g = Dec2Hex(255 - str2nr(a:rgbs[1]))
    let l:b = Dec2Hex(255 - str2nr(a:rgbs[2]))
    return "#" . l:r . l:g . l:b
endfunction

function! Dec2Hex(num)
    return s:digits[a:num / 16] . s:digits[a:num % 16]
endfunction

function! ColorizeInvert()
    if expand("%:t") != "rgb.txt"
        " hope we can catch some error
        echoerr "This file is not rgb.txt"
        return
    endif
    let l:i = 2
    let l:lastline = line("$")
    while l:i <= l:lastline
        let l:theline = getline(l:i)
        " a color definition has the format:
        " 119 136 153		LightSlateGray
        let l:rgbs = split(strpart(l:theline, 0, 11), '\s\+')
        let l:fgrgb = MakeRgb(l:rgbs)
        if exists("s:rgb_color_test_bgcolor")
            let l:bgrgb = s:rgb_color_test_bgcolor
        else
            let l:bgrgb = ReverseRgb(l:rgbs)
        endif

        let l:cname = strpart(l:theline, 13)
        exe 'syn match rgbColor' . l:i . ' "' . l:theline . '"'
        exe 'highlight rgbColor' . l:i . ' gui=None guifg=' . l:bgrgb . ' guibg=' . l:fgrgb

        let l:i = l:i + 1
    endwhile
endfunction

function! Colorize()
    if expand("%:t") != "rgb.txt"
        " hope we can catch some error
        echoerr "This file is not rgb.txt"
        return
    endif
    let l:i = 2
    let l:lastline = line("$")
    while l:i <= l:lastline
        let l:theline = getline(l:i)
        " a color definition has the format:
        " 119 136 153		LightSlateGray
        let l:rgbs = split(strpart(l:theline, 0, 11), '\s\+')
        let l:fgrgb = MakeRgb(l:rgbs)
        if exists("s:rgb_color_test_bgcolor")
            let l:bgrgb = s:rgb_color_test_bgcolor
        else
            let l:bgrgb = ReverseRgb(l:rgbs)
        endif

        let l:cname = strpart(l:theline, 13)
        exe 'syn match rgbColor' . l:i . ' "' . l:theline . '"'
        exe 'highlight rgbColor' . l:i . ' gui=None guifg=' . l:fgrgb . ' guibg=' . l:bgrgb

        let l:i = l:i + 1
    endwhile
endfunction

function! UserInput(...)
    if a:0 != 0
        let l:c = Validate(a:1)
        if l:c != ''
            let s:rgb_color_test_bgcolor = l:c
        else
            unlet! s:rgb_color_test_bgcolor
        endif
    else
        unlet! s:rgb_color_test_bgcolor
    endif

    call Colorize()
endfunction

function! Validate(color)
    if strlen(a:color) > 0
        if a:color =~? '\m^#[0-9a-f]\{6}$'
            return a:color
        else
            let l:i = search('\d\s\+' . a:color, 'wcn')
            if l:i > 0
                return MakeRgb(split(strpart(getline(l:i), 0, 11), '\s\+'))
            endif
        endif
    endif

    echo 'Invalid color'
    return ''
endfunction

function! ColorComplete(A, L, P)
    let l:comp = matchstr(a:L, '\w\+\s\+\zs.\{}\ze')
    let l:words = split(l:comp, ' ')
    let l:cur = len(l:words)
    "echoerr l:cur
    let l:cand = []
    let l:i = 2
    let l:lastline = line("$")
    while l:i <= l:lastline
        let l:theline = getline(l:i)
        let l:cname = strpart(l:theline, 13)
        if match(l:cname, '\C'.l:comp) == 0
            let l:parts = split(l:cname, ' ')
            let l:alt = join(l:parts[l:cur-1:], ' ')
            call add(l:cand, l:alt)
        endif

        let l:i = l:i + 1
    endwhile
    return l:cand
endfunction
