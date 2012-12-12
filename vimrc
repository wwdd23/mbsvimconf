"==================================================
" File:         vimrc
" Author:       Ming Bai <mbbill@gmail.com>
" Install:      .vimrc(_vimrc)
"               source "path/to/this/file"
"==================================================
let $MYVIMRC=expand("<sfile>")
let s:rtp=expand("<sfile>:p:h")."/vimfiles"
if isdirectory(s:rtp)
    let &rtp=s:rtp.','.&rtp
    let &rtp=&rtp.','.s:rtp.'/bundle/csapprox/after'
    let &rtp=&rtp.','.s:rtp.'/bundle/snipmate/after'
endif


" Variable Definition: {{{1
"--------------------------------------------------
let author='Ming Bai <mbbill@gmail.com>'

" Init Pathogen, don't show errormsg if pathogen doesn't exists.
let g:pathogen_disabled = ["code_complete","echofunc"]
silent! call pathogen#infect()

" Temp folder used to store swap and undo files.
let s:vimtmp = $HOME."/.vimtmp"

" Default colorcolumn settings.
let s:cc_default = 81

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

" [Set up cscope environment]
function! ToggleCscope()
    if has("cscope")
        if cscope_connection() == 1
            cs kill -1
            cclose
            return
        endif
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
                call system("cscope -b -k -q -R")
                cs add cscope.out
                copen
            endif
        endif
    endif
endfunction

" [Doxygen comment for functions]
function! DoxFunctionComment()
    mark d
    exec "normal O/**""\<cr>".'@brief   ...'
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
        exec "normal O".'@param   '.l:param."   ..."
        let l:nextParamLine=l:nextParamLine+1
        exec "normal `d"
        let l:startPos=(l:matchIndex+strlen(l:param)+1)
        let l:matchIndex=match(l:line,identifierRegex,l:startPos)
    endwhile
    exec l:nextParamLine
    exec 'normal O@return  ...'
    exec l:synopsisLine
    exec "normal ".l:synopsisCol."|"
endfunction

" [Highlight column matching { } pattern]
let s:hlflag=0
function! ColumnHighlight()
    let c=getline(line('.'))[col('.') - 1]
    if c=='{' || c=='}'
        let &cc = s:cc_default . ',' . virtcol('.')
        let s:hlflag = 1
    else
        if s:hlflag == 1
            let &cc = s:cc_default
            let s:hlflag = 0
        endif
    endif
endfunction

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

" [Auto complete functions]
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
    for letter in (range(char2nr('a'),char2nr('z'))+range(char2nr('A'),char2nr('Z')))
        execute "inoremap <silent> <buffer>" nr2char(letter) nr2char(letter) . "<c-r>=AutoComplete()<CR>"
    endfor
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
    "set langmenu=zh_CN.utf-8 "this must be set before syntax on
    set termencoding=cp936
    set fileencodings=ucs-bom,cp936,gb18030,utf-8,big5,iso-8859-1
    "set fileformats=dos,unix,mac
    set guifont=Terminus:h12:cANSI,Consolas:h10.5:cANSI
    set guifontwide=NSimSun:h11
    nnoremap <F11> :simalt ~x \| simalt ~r<cr>
elseif has("unix")
    set encoding=utf-8
    setglobal fenc=utf-8
    "set langmenu=zh_CN.utf-8 "this must be set before syntax on
    set termencoding=utf-8
    set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,iso-8859-1
    set fileformats=unix,dos,mac
    if has("gui_gtk2")
        set guifont=DejaVu\ Sans\ Mono\ 10
    endif
else
    set encoding=utf-8
endif

" [gui and color options]
if has("gui_running")
    set langmenu=C
    set mousemodel=popup
    set columns=92
    set lines=32
else
    if &term == "xterm" || &term == "screen"
        set t_Co=256
    endif
endif

" [status line]
let g:desertEx_statusLineColor = 1  "used by desertEx
set statusline=
set statusline+=%1* "switch to User1 highlight
set statusline+=%{getcwd()}\ > "current working dir
set statusline+=%#ErrorMsg#
set statusline+=%m
set statusline+=%2* "hi user2
set statusline+=\ %F "relative path
set statusline+=%= "split left and right
set statusline+=%3*
set statusline+=\ %{&ft}:%{&ff}:%{&fenc} "file encoding
set statusline+=%4*
set statusline+=\ U+%B "value of byte under cursor
set statusline+=%5*
set statusline+=\ %P "line percentage in file
set statusline+=%< "truncate

silent! colorscheme desertEx
if v:errmsg != ""
    silent! colorscheme desert
endif
syntax on

" [common options]
language message en_US.UTF-8
set ambiwidth=double
set autoindent
set backspace=indent,eol,start
set completeopt=menuone
set display=lastline,uhex
set fillchars=vert:\|,fold:-
set formatoptions+=Mmn
set guioptions=egmrt "no toolbar(T)
set guitablabel=%t\ %m
set helplang=en
set history=200
set hlsearch
set ignorecase smartcase
set incsearch
set laststatus=2
set linespace=1
set list
set listchars=tab:\|.,trail:_
set modeline
set modelines=5
set mouse=a mousemodel=popup
set noautoread
set nobackup
set nowritebackup
set nospell
set number
set numberwidth=2
set previewheight=8
set report=2
set ruler
set scroll=8
set selection=inclusive
set selectmode=""
set shortmess+=I
set showcmd
set smartindent
set spelllang=en
set splitright
set undolevels=500
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
"set expandtab
set smarttab

" [diff options]
set diffopt=filler,vertical

" [plugin options]
let g:GetLatestVimScripts_allowautoinstall = 0
let g:fencview_autodetect = 0  "disable fencview_autodetect
let g:load_doxygen_syntax = 1 "doxygen syntax support.
let html_dynamic_folds = 1
let netrw_longlist = 1  "netrw
let g:undotree_SetFocusWhenToggle = 1
let g:clang_auto_select = 0
let g:clang_snippets = 1
let g:clang_snippets_engine = 'snipmate'

" [create temp dir if not exists]
if getftype(s:vimtmp) != "dir"
    if mkdir(s:vimtmp) == 0
        echoerr "Can not create undo directory: ".s:vimtmp
    endif
endif

" [presistent-undo]
if has("persistent_undo")
    let &undodir = s:vimtmp
    set undofile
endif

" [swap folder]
let &directory = s:vimtmp

" Autocommands: {{{1
"--------------------------------------------------
" [Set up autocommands]
if has("autocmd") && !exists("autocommands_loaded")
    let autocommands_loaded=1
    filetype plugin indent on
    
    if version >= 703
        autocmd BufReadPost *.h,*.c,*.cpp,*.vim let &cc = s:cc_default
        autocmd CursorMoved *.h,*.c,*.cpp call ColumnHighlight()
    endif

    "autocmd BufReadPost * call DoAutoComplete()
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
inoremap    <c-v>   <c-o>:set paste<cr><c-r>+<c-o>:set nopaste<cr>
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
" nnoremap    <space> <c-w>}
" nnoremap    <m-space> <c-w>g}
nnoremap    <m-]>   :tn<cr>
nnoremap    <m-[>   :tp<cr>

" [Basically you press * or # to search for the current selection !! Really useful]
vnoremap    <silent> *  y/<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>
vnoremap    <silent> #  y?<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>

" [Alt-... to mark and jump]
xmap        <m-m>   <leader>m
nmap        <m-m>   <leader>m
nmap        <m-n>   <leader>/
nmap        <m-b>   <leader>?

" [CTRL-hjkl to browse command history and move the cursor]
cnoremap    <c-k>   <up>
cnoremap    <c-j>   <down>
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

" [Browse]
let g:browsefilter="All Files   *.*"
nnoremap    B       :browse tabnew<cr>

" [easy motion]
nmap        <space> H0<leader><leader>f

" [F2 to toggle the winmanager]
nnoremap    <F2>    :NERDTreeFind<cr>

" [F3 to start cscope session]
nnoremap    <F3>    :call ToggleCscope()<cr>

" [F4 to toggle the tagbar]
nnoremap    <F4>    :TagbarToggle<cr>

" [F5 for undotree]
nnoremap    <F5>    :UndotreeToggle<cr>

" [comment out current line]
nnoremap    <F12>   I/*<esc>A*/<esc>

" [ctrl-m clang_complete]
nnoremap    <c-m>   :call g:ClangUpdateQuickFix()<cr>
inoremap    <c-d>   <c-x><c-u>


" Commands: {{{1
"--------------------------------------------------
command!    AddHeader        call AddHeader()
command!    Dox              call DoxFunctionComment()
command!    CPPtags          !ctags -R --c++-kinds=+p --c-kinds=+p --fields=+iaS --extra=+q .
command!    VIMRC            tabedit $MYVIMRC
command!    -range UniqueLine     <line1>,<line2>call UniqueLine()
command!    ASTYLE           !astyle --mode=c --style=ansi --indent=spaces=4 --indent-switches --indent-preprocessor %
command!    -range=% Uniq3          <line1>,<line2>g/^\%<<line2>l\(.*\)\n\1$/d
command!    -range=% -nargs=? Nl    <line1>,<line2>s/^/\=printf("%"."<args>"."d ",line(".")-<line1> + 1)/
command!    DiffOrig         vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis

if has("unix")
    command!    SaveAsRoot      write !sudo tee %
endif


" Menus: {{{1
"--------------------------------------------------
menu        &Plugin.Toggle\ Sketch                  :call ToggleSketch()<cr>
menu        &Misc.Add\ Header                       :AddHeader<cr>
menu        &Misc.Add\ Doxygen\ Comment             :Dox<cr>
menu        &Misc.-sep1-                            :
menu        &Misc.Create\ ctags                     :CPPtags<cr>
menu        &Misc.Astyle_format                     :ASTYLE<cr>
menu        &Misc.Unique\ lines                     :UniqueLine<cr>
menu        &Misc.Edit\ vimrc                       :VIMRC<cr>

" vim: set ts=4 et ft=vim ff=unix fdm=marker :
