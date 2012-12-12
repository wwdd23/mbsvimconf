" Vim filetype plugin file
" Language:	cos
" Author:	Ming, Bai

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:save_cpo = &cpo
set cpo-=C

" Set 'formatoptions' to break comment lines but not other lines,
" and insert the comment leader when hitting <CR> or using "o".
setlocal formatoptions-=t formatoptions+=croql

" Set 'comments' to format dashed lists in comments. Behaves just like C.
setlocal comments& comments^=sO:*\ -,mO:*\ \ ,exO:*/

setlocal commentstring=//%s

" Change the :browse e filter to primarily show Java-related files.
if has("gui_win32")
    let  b:browsefilter="COS Files (*.cos)\t*.cos\n"
endif

" Undo the stuff we changed.
let b:undo_ftplugin = "setlocal suffixes< suffixesadd<" .
		\     " formatoptions< comments< commentstring< path< includeexpr<" .
		\     " | unlet! b:browsefilter"

" Restore the saved compatibility options.
let &cpo = s:save_cpo




" Syntax
syn match Constant "\<[0-9a-fA-F]*\>"
syn match Function ".\{1,}\ze(.*)"
syn keyword Statement hexstr APDU_Script call SW RESP if 
syn match Comment "//.*$"
syn match Preproc "\".*\""
 
"add this to vimrc
"au BufNewFile,BufRead *.cos :setfiletype cos
