"==================================================
" File:         .vimrc
" Brief:        mbbill's vim config file
" Author:       Ming Bai <mbbill@gmail.com>
" Last Change:  2007-06-29 22:30:00
" Version:      7.8
" Requirement:  programs:
"                   ctags
"                   cscope
"                   astyle
"               plugins:
"                   many,see .vim/ or vimfiles/
"               fonts:
"                   Bitstream Vera Sans Mono
"                           (Need install)
"                   Fixedsys Excelsior 2.00
"                           (Linux platform)
"
" HotKey:
"               - F2    filelist(bufferlist)
"               - F3    cscope
"               - F4    taglist
"               - F11   toggle fullscreen (windows only)
" Commands:
"               - Dox:
"                   create doxygen comment
"               - ToggleSketch:
"                   toggle the sketch mode
"               - AddHeader:
"                   add a doxygen file header
"               - CPPtags:
"                   create ctags database
"               - VIMRC:
"                   edit .vimrc in a new tab
"
" Note:         - function UpdateTime() will be
"                 called everytime the file updates
"               - set locale and terminal encoding
"                 to utf-8 under linux for better
"                 performance.
"==================================================

" Variable Definition: {{{1
"--------------------------------------------------
let author='Ming Bai <mingb@cosw.com>'
let cpname='msvc'   "available compiler name is: 'msvc','mingw',''
" when using 'msvc' compiler ,please use M$ VisualStudio to export
" a makefile and rename it to Makefile or pass it by command line:
" make /f projectname.mak


" [AddHeader() add a header to the top of the file]
function! AddHeader()
    let headerstr=[]
    let headerdict={}
    let order=['\file','\brief','\author','\date',' ','\note','\bug']
    let headerdict[order[0]]=expand("%:t")
    let headerdict[order[1]]=inputdialog("Input the brief of this file: (<=35 characters)")
    let headerdict[order[2]]=g:author
    let headerdict[order[3]]=strftime("%Y-%m-%d %H:%M:%S")
    let headerdict[order[4]]=''
    let headerdict[order[5]]='some notes'
    let headerdict[order[6]]='no bug'
    let headerstr+=["\/\*\*"]
    for i in order
        let headerstr+=[printf(" \* %s",printf("%-14s%-s",i,headerdict[i]))]
    endfor
    let headerstr+=[" \*\/"]
    call append(0,headerstr)
    call setpos(".",[0,1,1,"off"])
endfunction


" [UpdateTime() Update the timestamp in the header]
function! UpdateTime()
    for i in range(1,10)
        let tmp=getline(i)
        let time=strftime("%Y-%m-%d %H:%M:%S")
        if match(tmp,'\d\{4}-\d\{2}-\d\{2}\ \d\{2}:\d\{2}:\d\{2}')>=0
            let tmp=substitute(tmp,'\d\{4}-\d\{2}-\d\{2}\ \d\{2}:\d\{2}:\d\{2}',time,"g")
            silent call setline(i,tmp)
            break
        endif
    endfor
endfunction

" [SetupCompiler() Sets up the compiler environment]
function! SetupCompiler(name)
    if a:name=='msvc'
        compiler! msvc
        set shellpipe=>%s\ 2>&1
        set makeef=
    elseif a:name=='mingw'
        set makeprg=mingw32-make
        set shellpipe=>%s\ 2>&1
        set makeef=
    endif
        set autowrite
endfunction

" [Set up cscope environment]
function! SetupCscope()
    if has("cscope")
        set csprg=cscope
        set cscopequickfix=c-,d-,e-,f-,g-,i-,s-,t-
        set nocscopetag
        set cscopetagorder=0
        set cscopeverbose
        " add any database in current directory
        if filereadable("cscope.out")
            cs add cscope.out
            copen
        else
            let msg="Create cscope.out here?\n".getcwd()
            let result=confirm(msg,"&Yes\n&No",1,"Question")
            if result==1
                call system("cscope -b -R")
                cs add cscope.out
                copen
            endif
        endif
    endif
endfunction

" [Doxygen comment for functions]
function! DoxFunctionComment()
    mark d
    exec "normal O/**".repeat("-",30)."\<cr>".'\brief   ...'
    let l:synopsisLine=line(".")
    let l:synopsisCol=col(".")-2
    let l:nextParamLine=l:synopsisLine+1
    exec "normal a\<cr>\<cr>".'This function ...'."\<cr>\<bs>"."/"
    exec "normal `d"
    let l:line=getline(line("."))
    let l:startPos=match(l:line, "(")
    let l:identifierRegex='\i\+[[:space:][\]]*[,)]'
    let l:matchIndex=match(l:line,identifierRegex,l:startPos)
    let l:foundParam=0
    while l:matchIndex >= 0
        let l:foundParam=1
        exec "normal ".(l:matchIndex + 1)."|"
        let l:param=expand("<cword>")
        exec l:nextParamLine
        exec "normal O".'\param   '.l:param."   ..."
        let l:nextParamLine=l:nextParamLine+1
        exec "normal `d"
        let l:startPos=(l:matchIndex+strlen(l:param)+1)
        let l:matchIndex=match(l:line,identifierRegex,l:startPos)
    endwhile
    exec l:nextParamLine
    exec 'normal O\return  ...'
    exec l:synopsisLine
    exec "normal ".l:synopsisCol."|"
endfunction

" [Highlight column matching { } pattern]
let s:hlflag=0
function! ColumnHighlight()
    let c=getline(line('.'))[col('.') - 1]
    if c=='{' || c=='}'
        set cuc
        let s:hlflag=1
    else
        if s:hlflag==1
            set nocuc
            let s:hlflag=0
        endif
    endif
endfunction

" [Delete abbrvation tail character]
"function! Eatchar(pat)
"    let c = nr2char(getchar())
"    return (c =~ a:pat) ? '' : c
"endfunction

" [Let the same line combine together]
function! UniqueLine() range
    let l1 = a:firstline
    let l2 = a:lastline
    while l1<=l2
        call cursor(l1,1)
        let lineCount=0
        let lineData=getline(l1)
        if lineData==''
            execute l1." d"
            let l2-=1
        else
            let lineDataEsc=escape(lineData,'\\/.*$^~[]')
            while search('^'.lineDataEsc.'$','c',l2)>0
                execute "d"
                let l2-=1
                let lineCount+=1
            endwhile
            let lineData=lineCount."\t".lineData
            call append(l1-1,[lineData])
            let l2+=1
            let l1+=1
        endif
    endwhile
endfunction

" [AutoComplete functions]
let s:min_len = 2
fun! AutoComplete()
    let length = strlen(matchstr(getline('.')[:col('.')-2],'\w*$'))
    if length != s:min_len
        return ''
    else
        return "\<c-x>\<c-n>\<c-p>"
    endif
endfun
fun! DoAutoComplete()
    let letter = char2nr("a")
    while letter <= char2nr("z")
        execute "inoremap <buffer>" nr2char(letter) nr2char(letter) . "<c-r>=AutoComplete()<CR>"
        let letter = letter + 1
    endwhile
    let letter = char2nr("A")
    while letter <= char2nr("Z")
        execute "inoremap <buffer>" nr2char(letter) nr2char(letter) . "<c-r>=AutoComplete()<CR>"
        let letter = letter + 1
    endwhile
endfun
fun! StopAutoComplete()
    let letter = char2nr("a")
    while letter <= char2nr("z")
        execute "silent! iunmap <buffer>" nr2char(letter)
        let letter = letter + 1
    endwhile
    let letter = char2nr("A")
    while letter <= char2nr("Z")
        execute "silent! iunmap <buffer>" nr2char(letter)
        let letter = letter + 1
    endwhile
endfun

" Options: {{{1
"--------------------------------------------------
" [enable vim extensions to vi]
" This options will reset some options like 'formatoptions"
" those who will be changed when reloading this file,
" and when loading the .vimrc,nocompatible is always set
"set nocompatible

" [platform specific options]
if has("win32")
    set encoding=utf-8
    setglobal fenc=cp936
    set langmenu=zh_CN.utf-8 "this must be set before syntax on
    set termencoding=cp936
    set fileencodings=ucs-bom,cp936,gb18030,utf-8,big5,iso-8859-1
    "set fileformats=dos,unix,mac
    set guifont=Terminus:h12:cANSI,Bitstream_Vera_Sans_Mono:i:h10.5,Fixedsys:h11
    set guifontwide=NSimSun:h11
    nnoremap <F11> :simalt ~x \| simalt ~r<cr>
elseif has("unix")
    set encoding=utf-8
    setglobal fenc=utf-8
    set langmenu=zh_CN.utf-8 "this must be set before syntax on
    set termencoding=utf-8
    set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,iso-8859-1
    set fileformats=unix,dos,mac
    set guifont=Bitstream\ Vera\ Sans\ Mono\ Oblique\ 10.5,Fixedsys\ Excelsior\ 2.00\ 11
    set guifontwide=NSimSun\ 11
else
    set encoding=utf-8
endif

" [gui and color options]
if has("gui_running")
    colorscheme desertEx
    set hlsearch
    set mousemodel=popup
    set columns=130
    set lines=45
    set helplang=cn
    language message zh_CN.utf-8 "en_US.ISO_8859-1
    syntax on
elseif &t_Co >2
    set helplang=en
    set hlsearch
    language message en_US.ISO_8859-1
    syntax on
endif

" [compiler options]
if exists("cpname")
    call SetupCompiler(g:cpname)
endif

" [common options]
set autoindent
set smartindent
set ambiwidth=double
set noautoread
set backspace=indent,eol,start
set completeopt=menuone
set display=lastline,uhex
set fillchars=vert:\|,fold:-
set formatoptions+=Mmn
set guioptions=egmrt "no toolbar(T)
"set guitablabel=%f "see error-file-format
set guitablabel=%{tabpagenr()}.%t\ %m
set ignorecase smartcase
set incsearch
set laststatus=2
set linespace=1
set mouse=a mousemodel=popup
set nobackup
set number
set numberwidth=2
set previewheight=8
set report=2
set ruler
set scroll=8
set selection=inclusive
set selectmode=""
set splitright
set showcmd
set statusline=%f%m\ \[%{&ff}:%{&fenc}:%Y]\ %{getcwd()}%=(%b,0x%B)(%l\/%L\|%c%V)%P%<
set undolevels=1000
set updatetime=500
set virtualedit=block
set whichwrap+=<,>,[,]
set wildmenu
set winaltkeys=no
set wrap

" [tab stop options]
set tabstop=4
set shiftwidth=4
set softtabstop=0
set expandtab
set smarttab

" [diff options]
set diffopt=filler,vertical

" [plugin options]
let netrw_longlist = 1  "netrw
let Tlist_File_Fold_Auto_Close = 1    "taglist
let Tlist_Use_Right_Window = 1
let winManagerWindowLayout = 'FileExplorer'  "winmanager
let g:fencview_autodetect = 0  "disable fencview_autodetect
let g:load_doxygen_syntax = 1 "doxygen syntax support.
let g:qb_hotkey = '<s-space>'

" VimExplorer configuration
let g:VEConf_fileHotkey = {}
let g:VEConf_fileHotkey.quitVE = 'qq'
let g:VEConf_treeHotkey = {}
let g:VEConf_treeHotkey.quitVE = 'qq'
"let g:VEConf_recyclePath = 'c:\aa\'
if has('win32')
    let g:VEConf_systemEncoding = 'cp936'
endif


" Autocommands: {{{1
"--------------------------------------------------
" [Set up autocommands]
if has("autocmd") && !exists("autocommands_loaded")
    let autocommands_loaded=1
    filetype plugin indent on
    autocmd BufWritePre *.h,*.c,*.cpp,*.vim :call UpdateTime()
    autocmd BufWritePre *.h,*.c,*.cpp,*.vim :silent! %s/\s\+$//g
    autocmd CursorMoved * call ColumnHighlight()
    "autocmd BufReadPost * call DoWordComplete()
    autocmd BufReadPost * call DoAutoComplete()
    autocmd BufReadPost quickfix  setlocal nobuflisted

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    autocmd BufReadPost *
                \ if line("'\"") > 0 && line("'\"") <= line("$") |
                \   exe "normal! g`\"" |
                \ endif
endif



" Key Maps: {{{1
"--------------------------------------------------
" [Copy and cut in visual mode; Paste in insert mode]
inoremap    <C-V>   <C-R>+
"inoremap    <S-Insert>   <C-R>+
xnoremap    <c-c>   "+y
xnoremap    <c-x>   "+x
xnoremap    <c-y>   "ny
nnoremap    <c-p>   "np

" [Saving, also in Insert mode]
inoremap    <c-s>   <c-o>:update<cr>
nnoremap    <c-s>   :update<cr>
xnoremap    <c-s>   <c-c>:update<cr>

" [Select all]
nnoremap    <c-a>   ggVG

" [Next buffer]
nnoremap    <c-_>   :bnext<cr>

" [Switch tab pages]
nnoremap    <c-h>   gT
nnoremap    <c-l>   gt

" [Scroll]
nnoremap    <c-j>   <c-e>
nnoremap    <c-k>   <c-y>

" [Scroll up and down in Quickfix]
nnoremap    <c-n>   :cn<cr>
nnoremap    <c-b>   :cp<cr>

" [Cscope hot keys]
nnoremap    gnc     :cs find c <c-r>=expand("<cword>")<cr><cr>
nnoremap    gnd     :cs find d <c-r>=expand("<cword>")<cr><cr>
nnoremap    gne     :cs find e <c-r>=expand("<cword>")<cr><cr>
nnoremap    gnf     :cs find f <c-r>=expand("<cfile>")<cr><cr>
nnoremap    gng     :cs find g <c-r>=expand("<cword>")<cr><cr>
nnoremap    gni     :cs find i ^<c-r>=expand("<cfile>")<cr>$<cr>
nnoremap    gns     :cs find s <c-r>=expand("<cword>")<cr><cr>
nnoremap    gnt     :cs find t <c-r>=expand("<cword>")<cr><cr>

" [Preview and switch tags]
nnoremap    <space> <c-w>}
nnoremap    <m-space> <c-w>g}
nnoremap    <m-]>   :tn<cr>
nnoremap    <m-[>   :tp<cr>

" [Basically you press * or # to search for the current selection !! Really useful]
vnoremap    <silent> *  y/<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>
vnoremap    <silent> #  y?<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>

" [Alt-... to mark and jump]
xmap        <m-m>   \m
nmap        <m-m>   \m
nmap        <m-n>   \/
nmap        <m-b>   \?

" [CTRL-hjkl to browse command history and move the cursor]
cnoremap    <c-k>   <up>
"cnoremap    <c-j>   <down>  "conflict with Visvim.dll for VC6
cnoremap    <c-h>   <left>
cnoremap    <c-l>   <right>

" [CTRL-hjkl to move the cursor in insert mode]
inoremap    <m-k>   <c-k>
inoremap    <c-k>   <up>
inoremap    <c-j>   <down>
inoremap    <c-h>   <left>
inoremap    <c-l>   <right>

" [Easy indent in visual mode]
xnoremap    <   <gv
xnoremap    >   >gv

" [Search and Complete]
"cnoremap    <m-n>   <cr>/<c-r>=histget('/',-1)<cr>
cnoremap    <m-i>   <c-r>=tolower(substitute(getline('.')[(col('.')-1):],'\W.*','','g'))<cr>

" [Quick write and quit]
nnoremap    <m-w>   :write<cr>
nnoremap    <m-q>   :quit<cr>

" [Diff mode maps]
nnoremap    du      :diffupdate<cr>
xnoremap    <m-o>   :diffget<cr>
xnoremap    <m-p>   :diffput<cr>

" [Up down move]
nnoremap    j       gj
nnoremap    k       gk
nnoremap    gj      j
nnoremap    gk      k

" [Misc]
nnoremap    J       gJ
nnoremap    gJ      J
nnoremap    -       _
nnoremap    _       -

" [F2 to toggle the winmanager]
nnoremap    <F2>    :WMToggle<cr>

" [F3 to start cscope session]
nnoremap    <F3>    :call SetupCscope()<cr>

" [F4 to toggle the taglist]
nnoremap    <F4>    :TlistToggle<cr>

" [Jump to position by the length under cursor]
nnoremap <silent> <F5> "ly2l:call cursor(0,('0x'.@l)*2+col('.')+2)<cr>
nnoremap <silent> <S-F5> "ly4l:call cursor(0,('0x'.@l)*2+col('.')+4)<cr>

" [comment out current line]
nnoremap    <F12>   I/*<esc>A*/<esc>


" Abbreviations: [no use when using code_complete plugin] {{{1
"--------------------------------------------------
"iabbrev     //a     /**< */<left><left><left>
"iabbrev     //b     /* */<left><left><left>
"iabbrev     //c     /*======== ========*/<esc>10<left>i
"iabbrev     #f      #ifndef  <C-R>=GetFileName()<cr><cr>#define  <C-R>
"                    \=GetFileName()<cr><cr><cr><cr><cr>#endif  /*<C-R>
"                    \=GetFileName()<cr>*/<esc>
"iabbrev     #d      #define<C-R>=Eatchar('\s')<cr>
"iabbrev     #i      #include<C-R>=Eatchar('\s')<cr>
"iabbrev     xtime   <C-R>=strftime("%Y-%m-%d %H:%M:%S")<cr><C-R>=Eatchar('\s')<cr>
"iabbrev     if(     if(<Esc>mxa)<cr>{<cr>}<Esc>`xa<C-R>=Eatchar('\s')<cr>
"iabbrev     for(    for(<Esc>mxa)<cr>{<cr>}<Esc>`xa<C-R>=Eatchar('\s')<cr>


" Commands: {{{1
"--------------------------------------------------
command!    ToggleSketch     call ToggleSketch()
command!    AddHeader        call AddHeader()
command!    Dox              call DoxFunctionComment()
command!    RemoveComments   %s/\/\*\_.\{-}\*\///g
command!    CPPtags          !ctags -R --c++-kinds=+p --c-kinds=+p --fields=+iaS --extra=+q .
command!    VIMRC            tabedit $VIMRUNTIME/../.vimrc
command!    -range UniqueLine     <line1>,<line2>call UniqueLine()
command!    ASTYLE           !astyle --mode=c --style=ansi --indent=spaces=4 --indent-switches --indent-preprocessor %
command!    -range=% Uniq3          <line1>,<line2>g/^\%<<line2>l\(.*\)\n\1$/d
command!    -range=% -nargs=? Nl    <line1>,<line2>s/^/\=printf("%"."<args>"."d ",line(".")-<line1> + 1)/
command!    DiffOrig         vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis


" Menus: {{{1
"--------------------------------------------------
menu        &Misc.Add\ Header                     :AddHeader<cr>
menu        &Misc.Add\ Doxygen\ Comment           :Dox<cr>
menu        &Misc.Remove\ Comments                :RemoveComments<cr>
menu        &Misc.-sep1-                          :
menu        &Misc.Create\ ctags                   :CPPtags<cr>
menu        &Misc.Astyle_format                   :ASTYLE<cr>
menu        &Misc.Unique\ lines                   :UniqueLine<cr>
menu        &Misc.Edit\ vimrc                     :VIMRC<cr>
menu        &Misc.-sep2-                          :
menu        &Misc.Utilities.Calendar              :Calendar<cr>
menu        &Misc.Utilities.Color\ Selector       :ColorSel<cr>
menu        &Misc.Utilities.Renamer               :Renamer<cr>
menu        &Misc.Games.Toggle\ Sketch            :ToggleSketch<cr>
menu        &Misc.Games.Matrix\ ScreenSaver       :Matrix<cr>
menu        &Misc.Games.Tetris                    :Tetris<cr>
menu        &Misc.Convert.GoSimplifiedChinese     :GoSimplifiedChinese<cr>
menu        &Misc.Convert.GoTraditionalChinese    :GoTraditionalChinese<cr>
menu        &Misc.Convert.Convert\ to\ HTML       :TOhtml<cr>
menu        &Misc.Convert.Convert\ to\ ANSI       :TOansi<cr>
menu        &Misc.Convert.ScreenShot              :ScreenShot<cr>
menu        &Misc.Convert.Text\ to\ HTML          :Text2Html<cr>
menu        &Misc.Convert.Diff\ to\ HTML          :Diff2Html<cr>

"python << EOS
"import pyvim
"
"# buffer explorer
"from pyvimex import pvBufferExplorer
"tabBufEx = pvBufferExplorer.Application()
"tabBufEx.start()
"
"# file explorer
"from pyvimex import pvFileExplorer
"fileEx = pvFileExplorer.Application()
"fileEx.start()
"
"EOS


" vim: set ft=vim ff=unix fdm=marker :
