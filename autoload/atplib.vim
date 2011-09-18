" Title: 	Vim library for ATP filetype plugin.
" Author:	Marcin Szamotulski
" Email:	mszamot [AT] gmail [DOT] com
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex

" Source ATPRC File:
function! atplib#ReadATPRC() "{{{
    if ( has("unix") || has("max") || has("macunix") )
	" Note: in $HOME/.atprc file the user can set all the local buffer
	" variables without using autocommands
	"
	" Note: it must be sourced at the begining because some options handle
	" how atp will load (for example if we load history or not)
	" It also should be run at the end if the user defines mapping that
	" should be overwrite the ATP settings (this is done via
	" autocommand).
	let atprc_file=get(split(globpath($HOME, '.atprc.vim', 1), "\n"), 0, "")
	if !filereadable(atprc_file)
	    let atprc_file = get(split(globpath(&rtp, "**/ftplugin/ATP_files/atprc.vim"), '\n'), 0, "")
	endif
	if filereadable(atprc_file)
	    execute 'source ' . fnameescape(atprc_file)
	endif
    else
	let atprc_file = get(split(globpath(&rtp, "**/ftplugin/ATP_files/atprc.vim"), '\n'), 0, "")
	if filereadable(atprc_file)
	    execute 'source ' . fnameescape(atprc_file)
	endif
    endif
endfunction "}}}
" Kill:
function! atplib#KillPIDs(pids,...) "{{{
    if len(a:pids) == 0 && a:0 == 0
	return
    endif
python << END
import os, signal
from signal import SIGKILL
pids=vim.eval("a:pids")
for pid in pids:
    try:
	os.kill(int(pid),SIGKILL)
    except OSError:
        pass
END
endfunction "}}}
" Write:
function! atplib#write(...) "{{{
    let backup		= &backup
    let writebackup	= &writebackup
    let project		= b:atp_ProjectScript

    " In this way lastchange plugin will work better (?):
"     let eventignore 	= &eventignore
"     setl eventigonre	+=BufWritePre

    " Disable WriteProjectScript
    let b:atp_ProjectScript = 0
    set nobackup
    set nowritebackup

    if a:0 > 0 && a:1 == "silent"
	silent! update
    else
	update
    endif

    let b:atp_ProjectScript = project
    let &backup		= backup
    let &writebackup	= writebackup
"     let &eventignore	= eventignore
endfunction "}}}
" Log:
function! atplib#Log(file, string, ...) "{{{1
    if finddir(g:atp_TempDir, "/") == ""
	call mkdir(g:atp_TempDir, "p", 0700)
    endif
    if a:0 >= 1
	call delete(g:atp_TempDir."/".a:file)
    else
	exe "redir >> ".g:atp_TempDir."/".a:file 
	silent echo a:string
	redir END
    endif
endfunction "}}}1

"Make g:atp_TempDir, where log files are stored.
"{{{1
function! atplib#TempDir() 
    " Return temporary directory, unique for each user.
if has("python")
function! ATP_SetTempDir(tmp)
    let g:atp_TempDir=a:tmp
endfunction
python << END
import vim, tempfile, os
USER=os.getenv("USER")
tmp=tempfile.mkdtemp(suffix="", prefix="atp_")
vim.eval("ATP_SetTempDir('"+tmp+"')")
END
delfunction ATP_SetTempDir
else
    let g:atp_TempDir=substitute(tempname(), '\d\+$', "atp_debug", '')
    call mkdir(g:atp_TempDir, "p", 0700)
endif
endfunction
"}}}1
" Outdir: append to '/' to b:atp_OutDir if it is not present. 
function! atplib#outdir() "{{{1
    if has("win16") || has("win32") || has("win64") || has("win95")
	if b:atp_OutDir !~ "\/$"
	    let b:atp_OutDir=b:atp_OutDir . "\\"
	endif
    else
	if b:atp_OutDir !~ "\/$"
	    let b:atp_OutDir=b:atp_OutDir . "/"
	endif
    endif
    return b:atp_OutDir
endfunction
"}}}1
" Return {path} relative to {rel}, if not under {rel} return {path}
function! atplib#RelativePath(path, rel) "{{{1
    let current_dir 	= getcwd()
    exe "lcd " . fnameescape(a:rel)
    let rel_path	= fnamemodify(a:path, ':.')
    exe "lcd " . fnameescape(current_dir)
    return rel_path
endfunction
"}}}1
" Return fullpath
function! atplib#FullPath(file_name) "{{{1
    let cwd = getcwd()
    if a:file_name =~ '^\s*\/'
	let file_path = a:file_name
    elseif exists("b:atp_ProjectDir")
	exe "lcd " . fnameescape(b:atp_ProjectDir)
	let file_path = fnamemodify(a:file_name, ":p")
	exe "lcd " . fnameescape(cwd)
    else
	let file_path = fnamemodify(a:file_name, ":p")
    endif
    return file_path
endfunction
"}}}1
" Table:
"{{{ atplibTable, atplib#FormatListinColumns, atplib#PrintTable
function! atplib#Table(list, spaces)
" take a list of lists and make a list which is nicely formated (to echo it)
" spaces = list of spaces between columns.
    "maximal length of columns:
    let max_list=[]
    let new_list=[]
    for i in range(len(a:list[0]))
	let max=max(map(deepcopy(a:list), "len(v:val[i])"))
	call add(max_list, max)
    endfor

    for row in a:list
	let new_row=[]
	let i=0
	for el in row
	    let new_el=el.join(map(range(max([0,max_list[i]-len(el)+get(a:spaces,i,0)])), "' '"), "")
	    call add(new_row, new_el)
	    let i+=1
	endfor
	call add(new_list, new_row)
    endfor

    return map(new_list, "join(v:val, '')")
endfunction 
function! atplib#FormatListinColumns(list,s)
    " take a list and reformat it into many columns
    " a:s is the number of spaces between columns
    " for example of usage see atplib#PrintTable
    let max_len=max(map(copy(a:list), 'len(v:val)'))
    let new_list=[]
    let k=&l:columns/(max_len+a:s)
    let len=len(a:list)
    let column_len=len/k
    for i in range(0, column_len)
	let entry=[]
	for j in range(0,k)
	    call add(entry, get(a:list, i+j*(column_len+1), ""))
	endfor
	call add(new_list,entry)
    endfor
    return new_list
endfunction 
" Take list format it with atplib#FormatListinColumns and then with
" atplib#Table (which makes columns of equal width)
function! atplib#PrintTable(list, spaces)
    " a:list 	- list to print
    " a:spaces 	- nr of spaces between columns 

    let list = atplib#FormatListinColumns(a:list, a:spaces)
    let nr_of_columns = max(map(copy(list), 'len(v:val)'))
    let spaces_list = ( nr_of_columns == 1 ? [0] : map(range(1,nr_of_columns-1), 'a:spaces') )

    return atplib#Table(list, spaces_list)
endfunction
"}}}

" QFLength "{{{
function! atplib#qflength() 
    let lines = 1
    " i.e. open with one more line than needed.
    for qf in getqflist()
	let text=substitute(qf['text'], '\_s\+', ' ', 'g')
	let lines+=(len(text))/&l:columns+1
    endfor
    return lines
endfunction "}}}

function! atplib#Let(varname, varvalue)
    exe "let ".substitute(string(a:varname), "'", "", "g")."=".substitute(string(a:varvalue), "''\\@!", "", "g")
endfunction

" IMap Functions:
" {{{
" These maps extend ideas from TeX_9 plugin:
" With a:1 = "!" (bang) remove texMathZoneT (tikzpicture from MathZones).
function! atplib#IsInMath(...)
    let line		= a:0 >= 2 ? a:2 : line(".")
    let col		= a:0 >= 3 ? a:3 : col(".")-1
    if a:0 > 0 && a:1 == "!"
	let atp_MathZones=filter(copy(g:atp_MathZones), "v:val != 'texMathZoneT'")
    else
	let atp_MathZones=copy(g:atp_MathZones)
    endif
    call filter(atp_MathZones, 'v:val !~ ''\<texMathZone[VWXY]\>''')
    if atplib#complete#CheckSyntaxGroups(['texMathZoneV', 'texMathZoneW', 'texMathZoneX', 'texMathZoneY'])
	return 1
    else
	return atplib#complete#CheckSyntaxGroups(atp_MathZones, line, col) && 
		    \ !atplib#complete#CheckSyntaxGroups(['texMathText'], line, col)
    endif
endfunction
function! atplib#MakeMaps(maps, ...)
    let aucmd = ( a:0 >= 1 ? a:1 : '' )
    for map in a:maps
	if map[3] != "" && ( !exists(map[5]) || {map[5]} > 0 || 
		    \ exists(map[5]) && {map[5]} == 0 && aucmd == 'InsertEnter'  )
	    if exists(map[5]) && {map[5]} == 0 && aucmd == 'InsertEnter'
		exe "let ".map[5]." =1"
	    endif
	    exe map[0]." ".map[1]." ".map[2].map[3]." ".map[4]
	endif
    endfor
endfunction
function! atplib#DelMaps(maps)
    for map in a:maps
	let cmd = matchstr(map[0], '[^m]\ze\%(nore\)\=map') . "unmap"
	let arg = ( map[1] =~ '<buffer>' ? '<buffer>' : '' )
	try
	    exe cmd." ".arg." ".map[2].map[3]
	catch /E31:/
	endtry
    endfor
endfunction
" From TeX_nine plugin:
function! atplib#IsLeft(lchar,...)
    let nr = ( a:0 >= 1 ? a:1 : 0 )
    let left = getline('.')[col('.')-2-nr]
    if left ==# a:lchar
	return 1
    else
	return 0
    endif
endfunction
" try
function! atplib#ToggleIMaps(var, augroup, ...)
    if exists("s:isinmath") && 
		\ ( atplib#IsInMath() == s:isinmath ) &&
		\ ( a:0 >= 2 && a:2 ) &&
		\ a:augroup == 'CursorMovedI'
	return
    endif

    call SetMathVimOptions()

    if atplib#IsInMath() 
	call atplib#MakeMaps(a:var, a:augroup)
    else
	call atplib#DelMaps(a:var)
	if a:0 >= 1 && len(a:1)
	    call atplib#MakeMaps(a:1)
	endif
    endif
    let s:isinmath = atplib#IsInMath() 
endfunction
" catch E127
" endtry "}}}

" Compilation Call Back Communication: 
" with some help of D. Munger
" (Communications with compiler script: both in compiler.vim and the python script.)
" {{{ Compilation Call Back Communication
" TexReturnCode {{{
function! atplib#TexReturnCode(returncode)
	let b:atp_TexReturnCode=a:returncode
endfunction "}}}
" BibtexReturnCode {{{
function! atplib#BibtexReturnCode(returncode,...)
	let b:atp_BibtexReturnCode=a:returncode
	let b:atp_BibtexOutput= ( a:0 >= 1 ? a:1 : "" )
endfunction
" }}}
" MakeidxReturnCode {{{
function! atplib#MakeidxReturnCode(returncode,...)
	let b:atp_MakeidxReturnCode=a:returncode
	let b:atp_MakeidxOutput= ( a:0 >= 1 ? a:1 : "" )
endfunction
" }}}
" PlaceSigns {{{
function! atplib#Signs()
    if has("signs")
	sign unplace *
	" There is no way of getting list of defined signs in the current buffer.
	" Thus there is no proper way of deleting them. I overwrite them using
	" numbers as names. The vim help tells that there might be at most 120
	" signs put.
	
	" But this is not undefineing signs.
	let qflist=getqflist()
	let g:qflist=qflist
	let i=1
	for item in qflist
	    if item['type'] == 'E'
		let hl = 'ErrorMsg'
	    elseif item['type'] == 'W'
		let hl = 'WarningMsg'
	    else
		let hl = 'Normal'
	    endif
	    exe 'sign define '.i.' text='.item['type'].': texthl='.hl
	    exe 'sign place '.i.' line='.item['lnum'].' name='.i.' file='.expand('%:p')
	    let i+=1
	endfor
    endif
endfunction "}}}
" Callback {{{
" a:mode 	= a:verbose 	of s:compiler ( one of 'default', 'silent',
" 				'debug', 'verbose')
" a:commnad	= a:commmand 	of s:compiler 
"		 		( a:commnad = 'AU' if run from background)
"
" Uses b:atp_TexReturnCode which is equal to the value returned by tex
" compiler.
function! atplib#CallBack(mode,...)

    " If the compiler was called by autocommand.
    let AU 	= ( a:0 >= 1 ? a:1 : 'COM' )
    " Was compiler called to make bibtex
    let BIBTEX 	= ( a:0 >= 2 ? a:2 : "False" )
    let BIBTEX 	= ( BIBTEX == "True" || BIBTEX == 1 ? 1 : 0 )
    let MAKEIDX	= ( a:0 >= 3 ? a:3 : "False" )
    let MAKEIDX = ( MAKEIDX == "TRUE" || MAKEIDX == 1 ? 1 : 0 )

    if g:atp_debugCallBack
	exe "redir! > ".g:atp_TempDir."/CallBack.log"
    endif

    for cmd in keys(g:CompilerMsg_Dict) 
    if b:atp_TexCompiler =~ '^\s*' . cmd . '\s*$'
	    let Compiler 	= g:CompilerMsg_Dict[cmd]
	    break
	else
	    let Compiler 	= b:atp_TexCompiler
	endif
    endfor
    let b:atp_running	= b:atp_running - 1

    " Read the log file
    cgetfile

    " signs
    if g:atp_signs
	call atplib#Signs()
    endif

    if g:atp_debugCallBack
	silent echo "file=".expand("%:p")
	silent echo "g:atp_HighlightErrors=".g:atp_HighlightErrors
    endif
    if g:atp_HighlightErrors
	call atplib#HighlightErrors()
    endif
    " /this cgetfile is not working (?)/
    let error	= len(getqflist()) + (BIBTEX ? b:atp_BibtexReturnCode : 0)

    " If the log file is open re read it / it has 'autoread' opion set /
    checktime

    " redraw the status line /for the notification to appear as fast as
    " possible/ 
    if a:mode != 'verbose'
	redrawstatus
    endif

    " redraw has values -0,1 
    "  1 do  not redraw 
    "  0 redraw
    "  i.e. redraw at the end of function (this is done to not redraw twice in
    "  this function)
    let l:clist 	= 0
    let atp_DebugMode 	= t:atp_DebugMode

    if b:atp_TexReturnCode == 0 && ( a:mode == 'silent' || atp_DebugMode == 'silent' ) && g:atp_DebugMode_AU_change_cmdheight 
	let &l:cmdheight=g:atp_cmdheight
    endif

    if g:atp_debugCallBack
	let g:debugCB 		= 0
	let g:debugCB_mode 	= a:mode
	let g:debugCB_error 	= error
	silent echo "mode=".a:mode."\nerror=".error
    endif

    let msg_list = []
    let showed_message = 0

    if a:mode == "silent" && !error

	if t:atp_QuickFixOpen 

	    if g:atp_debugCallBack
		let g:debugCB .= 7
	    endif

	    cclose
	    call add(msg_list, ["[ATP:] no errors, closing quick fix window.", "Normal"])
	endif

    elseif a:mode == "silent" && AU == "COM"
	if b:atp_TexReturnCode
	    let showed_message		= 1
	    call add(msg_list, ["[ATP:] ".Compiler." returned with exit code ".b:atp_TexReturnCode.".", 'ErrorMsg', 'after'])
	endif
	if BIBTEX && b:atp_BibtexReturnCode
	    let showed_message		= 1
	    call add(msg_list, ["[ATP:] ".b:atp_BibCompiler." returned with exit code ".b:atp_BibtexReturnCode.".", 'ErrorMsg', 'after'])
	endif
	if MAKEIDX && b:atp_Makeindex
	    let showed_message		= 1
	    call add(msg_list, ["[ATP:] makeidx returned with exit code ".b:atp_MakeidxReturnCode.".", 'ErrorMsg', 'after'])
	endif
    endif

    if a:mode ==? 'debug' && !error

	if g:atp_debugCallBack
	    let g:debugCB 	.= 3
	endif

	cclose
	call add(msg_list,["[ATP:] ".b:atp_TexCompiler." returned without errors [b:atp_ErrorFormat=".b:atp_ErrorFormat."]".(g:atp_DefaultDebugMode=='silent'&&atp_DebugMode!='silent'?"\ngoing out of debuging mode.": "."), "Normal", "after"]) 
	let showed_message 	= 1
	let t:atp_DebugMode 	= g:atp_DefaultDebugMode
	if g:atp_DefaultDebugMode == "silent" && t:atp_QuickFixOpen
	    cclose
	endif
	let &l:cmdheight 	= g:atp_cmdheight
    endif

    " debug mode with errors
    if a:mode ==? 'debug' && error
	if len(getqflist())

	    if g:atp_debugCallBack
		let g:debugCB .= 4
	    endif

	    let &l:cmdheight 	= g:atp_DebugModeCmdHeight
		let showed_message 	= 1
		if b:atp_ReloadOnError || b:atp_Viewer !~ '^\s*xpdf\>'
		    call add(msg_list, ["[ATP:] ".Compiler." returned with exit code " . b:atp_TexReturnCode . ".", (b:atp_TexReturnCode ? "ErrorMsg" : "Normal"), "before"])
		else
		    call add(msg_list, ["[ATP:] ".Compiler." returned with exit code " . b:atp_TexReturnCode . " output file not reloaded.", (b:atp_TexReturnCode ? "ErrorMsg" : "Normal"), "before"])
		endif
	    if !t:atp_QuickFixOpen
		let l:clist		= 1
	    endif
	endif

	if BIBTEX && b:atp_BibtexReturnCode
	    let l:clist		= 1
	    call add(msg_list, [ "[Bib:] ".b:atp_BibtexCompiler." returned with exit code ".b:atp_BibtexReturnCode .".", "ErrorMsg", "after"])
	    call add(msg_list, [ "BIBTEX_OUTPUT" , "Normal", "after"])
	endif

	if MAKEIDX && b:atp_MakeidxReturnCode
	    let l:clist		= 1
	    call add(msg_list, [ "[Bib:] makeidx returned with exit code ".b:atp_MakeidxReturnCode .".", "ErrorMsg", "after"])
	    call add(msg_list, [ "MAKEIDX_OUTPUT" , "Normal", "after"])
	endif

	" In debug mode, go to first error. 
	if a:mode ==# "Debug"

	    if g:atp_debugCallBack
		let g:debugCB .= 6
	    endif

	    cc
	endif
    endif

    if msg_list == []
	if g:atp_debugCallBack
	    redir END
	endif
	return
    endif

    " Count length of the message:
    let msg_len		= len(msg_list)
    if len(filter(copy(msg_list), "v:val[0] == 'BIBTEX_OUTPUT'")) 
	let msg_len 	+= (BIBTEX ? len(split(b:atp_BibtexOutput, "\\n")) - 1 : - 1 )
    endif
    if len(filter(copy(msg_list), "v:val[0] == 'MAKEIDX_OUTPUT'")) 
	let msg_len 	+= (MAKEIDX ? len(split(b:atp_MakeidxOutput, "\\n")) - 1 : - 1 )
    endif
    " We never show qflist: (that's why it is commented out)
"     let msg_len		+= ((len(getqflist()) <= 7 && !t:atp_QuickFixOpen) ? len(getqflist()) : 0 )

    " Show messages/clist
    
    if g:atp_debugCallBack
	let g:msg_list 	= msg_list
	let g:clist 	= l:clist
	silent echo "msg_list=\n**************\n".join(msg_list, "\n")."\n**************"
	silent echo "l:clist=".l:clist
    endif

    let cmdheight = &l:cmdheight
    if msg_len <= 2
	let add=0
    elseif msg_len <= 7
	let add=1
    else
	let add=2
    endif
    let &l:cmdheight	= max([cmdheight, msg_len+add])
    let g:msg_len=msg_len
    if l:clist && len(getqflist()) > 7 && !t:atp_QuickFixOpen
	let winnr = winnr()
	copen
	exe winnr."wincmd w"
    elseif (a:mode ==? "debug") && !t:atp_QuickFixOpen 
	let l:clist = 1
    endif
    redraw
    let before_msg = filter(copy(msg_list), "v:val[2] == 'before'")
    let after_msg = filter(copy(msg_list), "v:val[2] == 'after'")
    for msg in before_msg 
	exe "echohl " . msg[1]
	echo msg[0]
    endfor
    let l:redraw	= 1
    if l:clist && len(getqflist()) <= 7 && !t:atp_QuickFixOpen
	if g:atp_debugCallBack
	    let g:debugCB .= "clist"
	endif
	try
	    clist
	catch E42:
	endtry
	let l:redraw	= 0
    endif
    for msg in after_msg 
	exe "echohl " . msg[1]
	if msg[0] !=# "BIBTEX_OUTPUT"
	    echo msg[0]
	else
	    echo "       ".substitute(b:atp_BibtexOutput, "\n", "\n       ", "g")
" 	    let bib_output=split(b:atp_BibtexOutput, "\n")
" 	    let len=max([10,len(bib_output)])
" 	    below split +setl\ buftype=nofile\ noswapfile Bibtex\ Output
" 	    setl nospell
" 	    setl nonumber
" 	    setl norelativenumber
" 	    call append(0,bib_output)
" 	    resize 10
" 	    redraw!
" 	    normal gg
" 	    nmap q :bd<CR>
	    let g:debugCB .=" BIBTEX_output "
	endif
    endfor
    echohl Normal
    if len(msg_list)==0
	redraw
    endif
    let &l:cmdheight = cmdheight
    if g:atp_debugCallBack
	redir END
    endif
endfunction "}}}
"{{{ LatexPID
"Store LatexPIDs in a variable
function! atplib#LatexPID(pid)
    call add(b:atp_LatexPIDs, a:pid)
"     call atplib#PIDsRunning("b:atp_BitexPIDs")
    let b:atp_LastLatexPID =a:pid
endfunction "}}}
"{{{ BibtexPID
"Store BibtexPIDs in a variable
function! atplib#BibtexPID(pid)
    call add(b:atp_BibtexPIDs, a:pid)
"     call atplib#PIDsRunning("b:atp_BibtexPIDs")
endfunction "}}}
"{{{ MakeindexPID
"Store MakeindexPIDs in a variable
function! atplib#MakeindexPID(pid)
    call add(b:atp_MakeindexPIDs, a:pid)
    let b:atp_LastMakeindexPID =a:pid
endfunction "}}}
"{{{ PythonPID
"Store PythonPIDs in a variable
function! atplib#PythonPID(pid)
    call add(b:atp_PythonPIDs, a:pid)
"     call atplib#PIDsRunning("b:atp_PythonPIDs")
endfunction "}}}
"{{{ MakeindexPID
"Store MakeindexPIDs in a variable
function! atplib#PythonPIDs(pid)
    call add(b:atp_PythonPIDs, a:pid)
    let b:atp_LastPythonPID =a:pid
endfunction "}}}
"{{{ PIDsRunning
function! atplib#PIDsRunning(var)
" a:var is a string, and might be one of 'b:atp_LatexPIDs', 'b:atp_BibtexPIDs' or
" 'b:atp_MakeindexPIDs'
python << EOL
import psutil, re, sys, vim
var  = vim.eval("a:var")
pids = vim.eval(var)
if len(pids) > 0:
    ps_list=psutil.get_pid_list()
    rmpids=[]
    for lp in pids:
	run=False
	for p in ps_list:
            if str(lp) == str(p):
		run=True
		break
	if not run:
            rmpids.append(lp)
    rmpids.sort()
    rmpids.reverse()
    for pid in rmpids:
	vim.eval("filter("+var+", 'v:val !~ \""+str(pid)+"\"')")
EOL
endfunction "}}}
"{{{ ProgressBar
function! atplib#ProgressBar(value,pid)
    if a:value != 'end'
	let b:atp_ProgressBar[a:pid]=a:value
    else
	call remove(b:atp_ProgressBar, a:pid)
    endif
    redrawstatus
endfunction "}}}
"{{{ redrawstatus
function! atplib#redrawstatus()
    redrawstatus
endfunction "}}}
"{{{ CursorMoveI
" function! atplib#CursorMoveI()
"     if mode() != "i"
" 	return
"     endif
"     let cursor_pos=[ line("."), col(".")]
"     call feedkeys("\<left>", "n")
"     call cursor(cursor_pos)
" endfunction "}}}
" {{{ HighlightErrors
function! atplib#HighlightErrors()
    call atplib#ClearHighlightErrors()
    let qf_list = getqflist()
    for error in qf_list
	if error.type ==? 'e'
	    let hlgroup = g:atp_Highlight_ErrorGroup
	else
	    let hlgroup = g:atp_Highlight_WarningGroup
	endif
	if hlgroup == ""
	    continue
	endif
	let m_id = matchadd(hlgroup, '\%'.error.lnum.'l.*', 20)
	call add(s:matchid, m_id)
	let error_msg=split(error.text, "\n")
    endfor
endfunction "}}}
" {{{ ClearHighlightErrors
function! atplib#ClearHighlightErrors()
    if !exists("s:matchid")
	let s:matchid=[]
	return
    endif
    for m_id in s:matchid
	try
	    silent call matchdelete(m_id)
	catch /E803:/
	endtry
    endfor
    let s:matchid=[]
endfunction "}}}
"{{{ echo
function! atplib#Echo(msg, cmd, hlgroup, ...)
    if a:0 >= 1 && a:1
	redraw
    endif
    exe "echohl ".a:hlgroup
    exe a:cmd." '".a:msg."'"
    echohl Normal
endfunction "}}}
" }}}

" Toggle On/Off Completion 
" {{{1 atplib#OnOffComp
function! atplib#OnOffComp(ArgLead, CmdLine, CursorPos)
    return filter(['on', 'off'], 'v:val =~ "^" . a:ArgLead') 
endfunction
"}}}1
" Open Function:
 "{{{1 atplib#Open
 " a:1	- pattern or a file name
 " 		a:1 is regarded as a filename if filereadable(pattern) is non
 " 		zero.
function! atplib#Open(bang, dir, TypeDict, ...)
    if a:dir == "0"
	echohl WarningMsg 
	echomsg "You have to set g:atp_LibraryPath in your vimrc or atprc file." 
	echohl Normal
	return
    endif

    let pattern = ( a:0 >= 1 ? a:1 : "") 
    let file	= filereadable(pattern) ? pattern : ""

    if file == ""
	if a:bang == "!" || !exists("g:atp_Library")
	    let g:atp_Library 	= filter(split(globpath(a:dir, "*"), "\n"), 'count(keys(a:TypeDict), fnamemodify(v:val, ":e"))')
	    let found 		= deepcopy(g:atp_Library) 
	else
	    let found		= deepcopy(g:atp_Library)
	endif
	call filter(found, "fnamemodify(v:val, ':t') =~ pattern")
	" Resolve symlinks:
	call map(found, "resolve(v:val)")
	" Remove double entries:
	call filter(found, "count(found, v:val) == 1")
	if len(found) > 1
	    echohl Title 
	    echo "Found files:"
	    echohl Normal
	    let i = 1
	    for file in found
		if len(map(copy(found), "v:val =~ escape(fnamemodify(file, ':t'), '~') . '$'")) == 1
		    echo i . ") " . fnamemodify(file, ":t")
		else
		    echo i . ") " . pathshorten(fnamemodify(file, ":p"))
		endif
		let i+=1
	    endfor
	    let choice = input("Which file to open? ")-1
	    if choice == -1
		return
	    endif
	    let file = found[choice]
	elseif len(found) == 1
	    let file = found[0]
	else
	    echohl WarningMsg
	    echomsg "[ATP:] Nothing found."
	    echohl None
	    return
	endif
    endif

    let ext 	= fnamemodify(file, ":e")
    let viewer 	= get(a:TypeDict, ext, 0) 

    if viewer == '0'
	echomsg "\n"
	echomsg "[ATP:] filetype: " . ext . " is not supported, add an entry to g:atp_OpenTypeDict" 
	return
    endif
    if viewer !~ '^\s*cat\s*$' && viewer !~ '^\s*g\=vim\s*$' && viewer !~ '^\s*edit\s*$' && viewer !~ '^\s*tabe\s*$' && viewer !~ '^\s*split\s*$'
	call system(viewer . " '" . file . "' &")  
    elseif viewer =~ '^\s*g\=vim\s*$' || viewer =~ '^\s*tabe\s*$'
	exe "tabe " . fnameescape(file)
	setl nospell
    elseif viewer =~ '^\s*edit\s*$' || viewer =~ '^\s*split\s*$'
	exe viewer . " " . fnameescape(file)
	setl nospell
    elseif viewer == '^\s*cat\s*'
	redraw!
	echohl Title
	echo "cat '" . file . "'"
	echohl Normal
	echo system(viewer . " '" . file . "' &")  
    endif
"     if fnamemodify(file, ":t") != "" && count(g:atp_open_completion, fnamemodify(file, ":t")) == 0
" 	call extend(g:atp_open_completion, [fnamemodify(file, ":t")], 0)
"     endif
    " This removes the hit Enter vim prompt. 
    call feedkeys("<CR>")
    return
endfunction
"}}}1

" Find Vim Server: find server 'hosting' a file and move to the line.
" {{{1 atplib#FindAndOpen
" Can be used to sync gvim with okular.
" just set in okular:
" 	settings>okular settings>Editor
" 		Editor		Custom Text Editor
" 		Command		gvim --servername GVIM --remote-expr "atplib#FindAndOpen('%f','%l', '%c')"
" You can also use this with vim but you should start vim with
" 		vim --servername VIM
" and use servername VIM in the Command above.		
function! atplib#ServerListOfFiles()
    exe "redir! > " . g:atp_TempDir."/ServerListOfFiles.log"
    let file_list = []
    for nr in range(1, bufnr('$')-1)
	" map fnamemodify(v:val, ":p") is not working if we are in another
	" window with file in another dir. So we are not using this (it might
	" happen that we end up in a wrong server though).
	let files 	= getbufvar(nr, "ListOfFiles")
	let main_file 	= getbufvar(nr, "atp_MainFile")
	if string(files) != "" 
	    call add(file_list, main_file)
	endif
	if string(main_file) != ""
	    call extend(file_list, files)
	endif
    endfor
    call filter(file_list, 'v:val != ""')
    redir end
    return file_list
endfunction
function! atplib#FindAndOpen(file, line, ...)
    let col		= ( a:0 >= 1 && a:1 > 0 ? a:1 : 1 )
    let file		= ( fnamemodify(a:file, ":e") == "tex" ? a:file : fnamemodify(a:file, ":p:r") . ".tex" )
    let file_t		= fnamemodify(file, ":t")
    let server_list	= split(serverlist(), "\n")
    exe "redir! > /tmp/FindAndOpen.log"
    if len(server_list) == 0
	return 1
    endif
    let use_server	= ""
    let use_servers	= []
    for server in server_list
	let file_list=split(remote_expr(server, 'atplib#ServerListOfFiles()'), "\n")
	let cond_1 = (index(file_list, file) != "-1")
	let cond_2 = (index(file_list, file_t) != "-1")
	if cond_1
	    let use_server	= server
	    break
	elseif cond_2
	    call add(use_servers, server)
	endif
    endfor
    " If we could not find file name with full path in server list use the
    " first server where is fnamemodify(file, ":t"). 
    if use_server == ""
	let use_server=get(use_servers, 0, "")
    endif
    if use_server != ""
	call system(v:progname." --servername ".use_server." --remote-wait +".a:line." ".fnameescape(file) . " &")
" 	Test this for file names with spaces
	let bufwinnr 	= remote_expr(use_server, 'bufwinnr("'.file.'")')
	if bufwinnr 	== "-1"
" 	    " The buffer is in a different tab page.
	    let tabpage	= 1
" 	    " Find the correct tabpage:
	    for tabnr in range(1, remote_expr(use_server, 'tabpagenr("$")'))
		let tabbuflist = split(remote_expr(use_server, 'tabpagebuflist("'.tabnr.'")'), "\n")
		let tabbuflist_names = split(remote_expr(use_server, 'map(tabpagebuflist("'.tabnr.'"), "bufname(v:val)")'), "\n")
		if count(tabbuflist_names, file) || count(tabfublist_names, file_t)
		    let tabpage = tabnr
		    break
		endif
	    endfor
	    " Goto to the tabpage:
	    if remote_expr(use_server, 'tabpagenr()') != tabpage
		call remote_send(use_server, '<Esc>:tabnext '.tabpage.'<CR>')
	    endif
	    " Check the bufwinnr once again:
	    let bufwinnr 	= remote_expr(use_server, 'bufwinnr("'.file.'")')
	endif

	" winnr() doesn't work remotely, this is a substitute:
	let remote_file = remote_expr(use_server, 'expand("%:t")')
	if remote_file  != file_t
	    call remote_send(use_server, "<Esc>:".bufwinnr."wincmd w<CR>")
	else

	" Set the ' mark, cursor position and redraw:
	call remote_send(use_server, "<Esc>:normal! 'm `'<CR>:call cursor(".a:line.",".a:col.")<CR>:redraw<CR>")
    endif
    return use_server
endfunction
"}}}1

" Labels Tools: GrepAuxFile, SrotLabels, generatelabels and showlabes.
" {{{1 LABELS
" the argument should be: resolved full path to the file:
" resove(fnamemodify(bufname("%"),":p"))

" {{{2 --------------- atplib#GrepAuxFile
" This function searches in aux file (actually it tries first ._aux file,
" made by compile.py - this is because compile.py is copying aux file only if
" there are no errors (for to not affect :Labels command)
function! atplib#GrepAuxFile(...)
    " Aux file to read:
    if exists("b:atp_MainFile")
	let atp_MainFile	= atplib#FullPath(b:atp_MainFile)
    endif
    if filereadable(fnamemodify(atp_MainFile, ":r") . "._aux")
	let aux_filename	= ( a:0 == 0 && exists("b:atp_MainFile") ? fnamemodify(atp_MainFile, ":r") . "._aux" : a:1 )
    else
	let aux_filename	= ( a:0 == 0 && exists("b:atp_MainFile") ? fnamemodify(atp_MainFile, ":r") . ".aux" : a:1 )
    endif
    let tex_filename	= fnamemodify(aux_filename, ":r") . ".tex"

    if !filereadable(aux_filename)
	" We should worn the user that there is no aux file
	" /this is not visible ! only after using the command 'mes'/
	echohl WarningMsg
	echomsg "[ATP:] there is no aux file. Run ".b:atp_TexCompiler." first."
	echohl Normal
	return []
	" CALL BACK is not working
	" I can not get output of: vim --servername v:servername --remote-expr v:servername
	" for v:servername
	" Here we should run latex to produce auxfile
" 	echomsg "Running " . b:atp_TexCompiler . " to get aux file."
" 	let labels 	= system(b:atp_TexCompiler . " -interaction nonstopmode " . atp_MainFile . " 1&>/dev/null  2>1 ; " . " vim --servername ".v:servername." --remote-expr 'atplib#GrepAuxFile()'")
" 	return labels
    endif
"     let aux_file	= readfile(aux_filename)

    let saved_llist	= getloclist(0)
    if bufloaded(aux_filename)
	exe "silent! bd! " . bufnr(aux_filename)
    endif
    try
	silent execute 'lvimgrep /\\newlabel\s*{/j ' . fnameescape(aux_filename)
    catch /E480:/
    endtry
    let loc_list	= getloclist(0)
    call setloclist(0, saved_llist)
    call map(loc_list, ' v:val["text"]')

    let labels		= []
    if g:atp_debugGAF
	let g:gaf_debug	= {}
    endif

    " Equation counter depedns on the option \numberwithin{equation}{section}
    " /now this only supports article class.
    let equation = len(atplib#complete#GrepPreambule('^\s*\\numberwithin{\s*equation\s*}{\s*section\s*}', tex_filename))
"     for line in aux_file
    for line in loc_list
    if line =~ '\\newlabel\>'
	" line is of the form:
	" \newlabel{<label>}{<rest>}
	" where <rest> = {<label_number}{<title>}{<counter_name>.<counter_number>}
	" <counter_number> is usually equal to <label_number>.
	"
	" Document classes: article, book, amsart, amsbook, review:
	" NEW DISCOVERY {\zs\%({[^}]*}\|[^}]\)*\ze} matches for inner part of 
	" 	{ ... { ... } ... }	/ only one level of being recursive / 
	" 	The order inside the main \%( \| \) is important.
	"This is in the case that the author put in the title a command,
	"for example \mbox{...}, but not something more difficult :)
	if line =~ '^\\newlabel{[^}]*}{{[^}]*}{[^}]*}{\%({[^}]*}\|[^}]\)*}{[^}]*}'
	    let label	= matchstr(line, '^\\newlabel\s*{\zs[^}]*\ze}')
	    let rest	= matchstr(line, '^\\newlabel\s*{[^}]*}\s*{\s*{\zs.*\ze}\s*$')
	    let l:count = 1
	    let i	= 0
	    while l:count != 0 
		let l:count = ( rest[i] == '{' ? l:count+1 : rest[i] == '}' ? l:count-1 : l:count )
		let i+= 1
	    endwhile
	    let number	= substitute(strpart(rest,0,i-1), '{\|}', '', 'g')  
	    let rest	= strpart(rest,i)
	    let rest	= substitute(rest, '^{[^}]*}{', '', '')
	    let l:count = 1
	    let i	= 0
	    while l:count != 0 
		let l:count = rest[i] == '{' ? l:count+1 : rest[i] == '}' ? l:count-1 : l:count 
		let i+= 1
	    endwhile
	    let counter	= substitute(strpart(rest,i-1), '{\|}', '', 'g')  
	    let counter	= strpart(counter, 0, stridx(counter, '.')) 

	" Document classes: article, book, amsart, amsbook, review
	" (sometimes the format is a little bit different)
	elseif line =~ '\\newlabel{[^}]*}{{\d\%(\d\|\.\)*{\d\%(\d\|\.\)*}}{\d*}{\%({[^}]*}\|[^}]\)*}{[^}]*}'
	    let list = matchlist(line, 
		\ '\\newlabel{\([^}]*\)}{{\(\d\%(\d\|\.\)*{\d\%(\d\|\.\)*\)}}{\d*}{\%({[^}]*}\|[^}]\)*}{\([^}]*\)}')
	    let [ label, number, counter ] = [ list[1], list[2], list[3] ]
	    let number	= substitute(number, '{\|}', '', 'g')
	    let counter	= matchstr(counter, '^\w\+')

	" Document class: article
	elseif line =~ '\\newlabel{[^}]*}{{\d\%(\d\|\.\)*}{\d\+}}'
	    let list = matchlist(line, '\\newlabel{\([^}]*\)}{{\(\d\%(\d\|\.\)*\)}{\d\+}}')
	    let [ label, number, counter ] = [ list[1], list[2], "" ]

	" Memoir document class uses '\M@TitleReference' command
	" which doesn't specify the counter number.
	elseif line =~ '\\M@TitleReference' 
	    let label	= matchstr(line, '^\\newlabel\s*{\zs[^}]*\ze}')
	    let number	= matchstr(line, '\\M@TitleReference\s*{\zs[^}]*\ze}') 
	    let counter	= ""

	elseif line =~ '\\newlabel{[^}]*}{.*\\relax\s}{[^}]*}{[^}]*}}'
	    " THIS METHOD MIGHT NOT WORK WELL WITH: book document class.
	    let label 	= matchstr(line, '\\newlabel{\zs[^}]*\ze}{.*\\relax\s}{[^}]*}{[^}]*}}')
	    let nc 		= matchstr(line, '\\newlabel{[^}]*}{.*\\relax\s}{\zs[^}]*\ze}{[^}]*}}')
	    let counter	= matchstr(nc, '\zs\a*\ze\(\.\d\+\)\+')
	    let number	= matchstr(nc, '.*\a\.\zs\d\+\(\.\d\+\)\+') 
	    if counter == 'equation' && !equation
		let number = matchstr(number, '\d\+\.\zs.*')
	    endif

	" aamas2010 class
	elseif line =~ '\\newlabel{[^}]*}{{\d\%(\d\|.\)*{\d\%(\d\|.\)*}{[^}]*}}' && atplib#complete#DocumentClass(b:atp_MainFile) =~? 'aamas20\d\d'
	    let label 	= matchstr(line, '\\newlabel{\zs[^}]*\ze}{{\d\%(\d\|.\)*{\d\%(\d\|.\)*}{[^}]*}}')
	    let number 	= matchstr(line, '\\newlabel{\zs[^}]*\ze}{{\zs\d\%(\d\|.\)*{\d\%(\d\|.\)*\ze}{[^}]*}}')
	    let number	= substitute(number, '{\|}', '', 'g')
	    let counter	= ""

	" subeqautions
	elseif line =~ '\\newlabel{[^}]*}{{[^}]*}{[^}]*}}'
	    let list 	= matchlist(line, '\\newlabel{\([^}]*\)}{{\([^}]*\)}{\([^}]*\)}}')
	    let [ label, number ] = [ list[1], list[2] ]
	    let counter	= ""

	" AMSBook uses \newlabel for tocindent
	" which we filter out here.
	elseif line =~ '\\newlabel{[^}]*}{{\d\+.\?{\?\d*}\?}{\d\+}}'
	    let list 	= matchlist(line,  '\\newlabel{\([^}]*\)}{{\(\d\+.\?{\?\d*}\?\)}{\(\d\+}\)}')
	    let [ label, number ] = [ list[1], list[2] ]
	    let number 	= substitute(number, '\%({\|}\)', '', 'g')
	    let counter 	= ""
	else
	    let label	= "nolabel: " . line
	endif

	if label !~ '^nolabel:\>'
	    call add(labels, [ label, number, counter])
	    if g:atp_debugGAF
		call extend(g:gaf_debug, { label : [ number, counter ] })
	    endif
	endif
    endif
    endfor

    return labels
endfunction
" }}}2
" Sorting function used to sort labels.
" {{{2 --------------- atplib#SortLabels
" It compares the first component of lists (which is line number)
" This should also use the bufnr.
function! atplib#SortLabels(list1, list2)
    if a:list1[0] == a:list2[0]
	return 0
    elseif str2nr(a:list1[0]) > str2nr(a:list2[0])
	return 1
    else
	return -1
    endif
endfunction
" }}}2
" Function which find all labels and related info (label number, lable line
" number, {bufnr} <= TODO )
" {{{2 --------------- atplib#generatelabels
" This function runs in two steps:
" 	(1) read lables from aux files using GrepAuxFile()
" 	(2) search all input files (TreeOfFiles()) for labels to get the line
" 		number 
" 	   [ this is done using :vimgrep which is fast, when the buffer is not loaded ]
function! atplib#generatelabels(filename, ...)
    let s:labels	= {}
    let bufname		= fnamemodify(a:filename,":t")
    let auxname		= fnamemodify(a:filename,":p:r") . ".aux"
    let return_ListOfFiles	= a:0 >= 1 ? a:1 : 1

    let true=1
    let i=0

    let aux_labels	= atplib#GrepAuxFile(auxname)

    let saved_pos	= getpos(".")
    call cursor(1,1)

    let [ TreeofFiles, ListOfFiles, DictOfFiles, LevelDict ] 		= TreeOfFiles(a:filename)
    let ListOfFiles_orig = copy(ListOfFiles)
    if count(ListOfFiles, a:filename) == 0
	call add(ListOfFiles, a:filename)
    endif
    let saved_llist	= getloclist(0)
    call setloclist(0, [])

    " Look for labels in all input files.
    for file in ListOfFiles
	let file	= atplib#FullPath(file)
	silent! execute "lvimgrepadd /\\label\s*{/j " . fnameescape(file)
    endfor
    let loc_list	= getloclist(0)
"     call setloclist(0, saved_llist)
    call map(loc_list, '[ v:val["lnum"], v:val["text"], v:val["bufnr"] ]')

    let labels = {}

    for label in aux_labels
	let dict		= filter(copy(loc_list), "v:val[1] =~ '\\label\s*{\s*'.escape(label[0], '*\/$.') .'\s*}'")
	let line		= get(get(dict, 0, []), 0, "") 
	let bufnr		= get(get(dict, 0, []), 2, "")
	let bufname		= fnamemodify(bufname(bufnr), ":p")
	if get(labels, bufname, []) == []
	    let labels[bufname] = [ [line, label[0], label[1], label[2], bufnr ] ]
	else
	    call add(labels[bufname], [line, label[0], label[1], label[2], bufnr ]) 
	endif
    endfor

    for bufname in keys(labels)
	call sort(labels[bufname], "atplib#SortLabels")
    endfor

"     let i=0
"     while i < len(texfile)
" 	if texfile[i] =~ '\\label\s*{'
" 	    let lname 	= matchstr(texfile[i], '\\label\s*{.*', '')
" 	    let start 	= stridx(lname, '{')+1
" 	    let lname 	= strpart(lname, start)
" 	    let end	= stridx(lname, '}')
" 	    let lname	= strpart(lname, 0, end)
"     "This can be extended to have also the whole environment which
"     "could be shown.
" 	    call extend(s:labels, { i+1 : lname })
" 	endif
" 	let i+=1 
"     endwhile

    if exists("t:atp_labels")
	call extend(t:atp_labels, labels, "force")
    else
	let t:atp_labels	= labels
    endif
    keepjumps call setpos(".", saved_pos)
    if return_ListOfFiles
	return [ t:atp_labels, ListOfFiles_orig ]
    else
	return t:atp_labels
    endif
endfunction
" }}}2
" This function opens a new window and puts the results there.
" {{{2 --------------- atplib#showlabels
" the argument is [ t:atp_labels, ListOfFiles ] 
" 	where ListOfFiles is the list returne by TreeOfFiles() 
function! atplib#showlabels(labels)

    " the argument a:labels=t:atp_labels[bufname("")] !
    let l:cline=line(".")

    let saved_pos	= getpos(".")

    " Open new window or jump to the existing one.
    let l:bufname	= bufname("")
    let l:bufpath	= fnamemodify(resolve(fnamemodify(bufname("%"),":p")),":h")
    let BufFullName	= fnamemodify(l:bufname, ":p") 

    let l:bname="__Labels__"

    let t:atp_labelswinnr=winnr()
    let t:atp_labelsbufnr=bufnr("^".l:bname."$")
    let l:labelswinnr=bufwinnr(t:atp_labelsbufnr)

    let tabstop	= 0
    for file in a:labels[1]
	let dict	= get(a:labels[0], file, [])
	let tabstop	= max([tabstop, max(map(copy(dict), "len(v:val[2])")) + 1])
	unlet dict
    endfor
"     let g:labelswinnr	= l:labelswinnr
    let saved_view	= winsaveview()

    if l:labelswinnr != -1
	" Jump to the existing window.
	redraw
	exe l:labelswinnr . " wincmd w"
	if l:labelswinnr != t:atp_labelswinnr
	    silent exe "%delete"
	else
	    echoerr "ATP error in function s:showtoc, TOC/LABEL buffer 
		    \ and the tex file buffer agree."
	    return
	endif
    else

    " Open new window if its width is defined (if it is not the code below
    " will put lab:cels in the current buffer so it is better to return.
	if !exists("t:atp_labels_window_width")
	    echoerr "t:atp_labels_window_width not set"
	    return
	endif

	" tabstop option is set to be the longest counter number + 1
	redraw
	let toc_winnr=bufwinnr(bufnr("__ToC__"))
	if toc_winnr == -1
	    let l:openbuffer= "keepalt " . t:atp_labels_window_width . "vsplit +setl\\ tabstop=" . tabstop . "\\ nowrap\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp __Labels__"
	else
	    exe toc_winnr."wincmd w"
	    let l:openbuffer= "keepalt below split +setl\\ tabstop=".tabstop."\\ nowrap\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp __Labels__"
	endif
	silent exe l:openbuffer
	silent call atplib#setwindow()
	let t:atp_labelsbufnr=bufnr("")
    endif
    unlockvar b:atp_Labels
    let b:atp_Labels	= {}

"     let g:labels=copy(a:labels)

    let line_nr	= 2
    for file in a:labels[1]
	if !(len(get(a:labels[0], file, []))>0)
	    continue
	endif
	call setline("$", fnamemodify(file, ":t") . " (" . fnamemodify(file, ":h")  . ")")
	call extend(b:atp_Labels, { 1 : [ file, 0 ]})
	for label in get(a:labels[0], file, [])
	    " Set line in the format:
	    " /<label_numberr> \t[<counter>] <label_name> (<label_line_nr>)/
	    " if the <counter> was given in aux file (see the 'counter' variable in atplib#GrepAuxFile())
	    " print it.
	    " /it is more complecated because I want to make it as tight as
	    " possible and as nice as possible :)
	    " the first if checks if there are counters, then counter type is
	    " printed, then the tabs are set./
    " 	let slen	= winwidth(0)-tabstop-5-5
    " 	let space_len 	= max([1, slen-len(label[1])])
	    if tabstop+(len(label[3][0])+3)+len(label[1])+(len(label[0])+2) < winwidth(0)
		let space_len	= winwidth(0)-(tabstop+(len(label[3][0])+3)+len(label[1])+(len(label[0])+2))
	    else
		let space_len  	= 1
	    endif
	    let space	= join(map(range(space_len), '" "'), "")
	    let set_line 	= label[2] . "\t[" . label[3][0] . "] " . label[1] . space . "(" . label[0] . ")"
	    call setline(line_nr, set_line ) 
	    call extend(b:atp_Labels, { line_nr : [ file, label[0] ]}) 
	    let line_nr+=1
	endfor
    endfor
    lockvar 3 b:atp_Labels

    " set the cursor position on the correct line number.
    call search(l:bufname, 'w')
    let l:number=1
    for label  in get(a:labels[0], BufFullName, [])
	if l:cline >= label[0]
	    keepjumps call cursor(line(".")+1, col("."))
	elseif l:number == 1 && l:cline < label[0]
	    keepjumps call cursor(line(".")+1, col("."))
	endif
	let l:number+=1
    endfor
endfunction
" }}}2
" }}}1

" Table Of Contents Tools:
function! atplib#getlinenr(...) "{{{
    let line 	=  a:0 >= 1 ? a:1 : line('.')
    let labels 	=  a:0 >= 2 ? a:2 : expand("%") == "__Labels__" ? 1 : 0

    if labels == 0
	return get(b:atp_Toc, line, ["", ""])[1]
    else
	return get(b:atp_Labels, line, ["", ""])[1]
    endif
endfunction "}}}
function! atplib#CursorLine() "{{{
    if exists("t:cursorline_idmatch")
	try
	    call matchdelete(t:cursorline_idmatch)
	catch /E803:/
	endtry
    endif
    if atplib#getlinenr(line(".")) 
	let t:cursorline_idmatch =  matchadd('CursorLine', '^\%'.line(".").'l.*$')
    endif
endfunction "}}}

" Various Comparing Functions:
"{{{1 atplib#CompareNumbers
function! atplib#CompareNumbers(i1, i2)
   return str2nr(a:i1) == str2nr(a:i2) ? 0 : str2nr(a:i1) > str2nr(a:i2) ? 1 : -1
endfunction
"}}}1
" {{{1 atplib#CompareCoordinates
" Each list is an argument with two values:
" listA=[ line_nrA, col_nrA] usually given by searchpos() function
" listB=[ line_nrB, col_nrB]
" returns 1 iff A is smaller than B
fun! atplib#CompareCoordinates(listA,listB)
    if a:listA[0] < a:listB[0] || 
	\ a:listA[0] == a:listB[0] && a:listA[1] < a:listB[1] ||
	\ a:listA == [0,0]
	" the meaning of the last is that if the searchpos() has not found the
	" beginning (a:listA) then it should return 1 : the env is not started.
	return 1
    else
	return 0
    endif
endfun
"}}}1
" {{{1 atplib#CompareCoordinates_leq
" Each list is an argument with two values!
" listA=[ line_nrA, col_nrA] usually given by searchpos() function
" listB=[ line_nrB, col_nrB]
" returns 1 iff A is smaller or equal to B
function! atplib#CompareCoordinates_leq(listA,listB)
    if a:listA[0] < a:listB[0] || 
	\ a:listA[0] == a:listB[0] && a:listA[1] <= a:listB[1] ||
	\ a:listA == [0,0]
	" the meaning of the last is that if the searchpos() has not found the
	" beginning (a:listA) then it should return 1 : the env is not started.
	return 1
    else
	return 0
    endif
endfunction
"}}}1
" {{{1 atplib#CompareStarAfter
" This is used by atplib#complete#TabCompletion to put abbreviations of starred environment after not starred version
function! atplib#CompareStarAfter(i1, i2)
    if a:i1 !~ '\*' && a:i2 !~ '\*'
	if a:i1 == a:i2
	    return 0
	elseif a:i1 < a:i2
	    return -1
	else
	    return 1
	endif
    else
	let i1 = substitute(a:i1, '\*', '', 'g')
	let i2 = substitute(a:i2, '\*', '', 'g')
	if i1 == i2
	    if a:i1 =~ '\*' && a:i2 !~ '\*'
		return 1
	    else
		return -1
	    endif
	    return 0
	elseif i1 < i2
	    return -1
	else
	    return 1
	endif
    endif
endfunction
" }}}1

" ReadInputFile function reads finds a file in tex style and returns the list
" of its lines. 
" {{{1 atplib#ReadInputFile
" this function looks for an input file: in the list of buffers, under a path if
" it is given, then in the b:atp_OutDir.
" directory. The last argument if equal to 1, then look also
" under g:texmf.
function! atplib#ReadInputFile(ifile,check_texmf)

    let l:input_file = []

    " read the buffer or read file if the buffer is not listed.
    if buflisted(fnamemodify(a:ifile,":t"))
	let l:input_file=getbufline(fnamemodify(a:ifile,":t"),1,'$')
    " if the ifile is given with a path it should be tried to read from there
    elseif filereadable(a:ifile)
	let l:input_file=readfile(a:ifile)
    " if not then try to read it from b:atp_OutDir
    elseif filereadable(b:atp_OutDir . fnamemodify(a:ifile,":t"))
	let l:input_file=readfile(filereadable(b:atp_OutDir . fnamemodify(a:ifile,":t")))
    " the last chance is to look for it in the g:texmf directory
    elseif a:check_texmf && filereadable(findfile(a:ifile,g:texmf . '**'))
	let l:input_file=readfile(findfile(a:ifile,g:texmf . '**'))
    endif

    return l:input_file
endfunction
"}}}1

" BIB SEARCH:
" These are all bibsearch related variables and functions.
"{{{ BIBSEARCH
"{{{ atplib#variables
let atplib#bibflagsdict={ 
                \ 't' : ['title',       'title        '],               'a' : ['author',        'author       '], 
		\ 'b' : ['booktitle',   'booktitle    '],               'c' : ['mrclass',       'mrclass      '], 
		\ 'e' : ['editor',      'editor       '], 	        'j' : ['journal',       'journal      '], 
		\ 'f' : ['fjournal',    'fjournal     '], 	        'y' : ['year',          'year         '], 
		\ 'n' : ['number',      'number       '], 	        'v' : ['volume',        'volume       '], 
		\ 's' : ['series',      'series       '], 	        'p' : ['pages',         'pages        '], 
		\ 'P' : ['publisher',   'publisher    '],               'N' : ['note',          'note         '], 
		\ 'S' : ['school',      'school       '], 	        'h' : ['howpublished',  'howpublished '], 
		\ 'o' : ['organization', 'organization '],              'I' : ['institution' ,  'institution '],
		\ 'u' : ['url',         'url          '],
		\ 'H' : ['homepage',    'homepage     '], 	        'i' : ['issn',          'issn         '],
		\ 'k' : ['key',         'key          '], 	        'R' : ['mrreviewer',    'mrreviewer   ']}
" they do not work in the library script :(
" using g:bibflags... .
" let atplib#bibflagslist=keys(atplib#bibflagsdict)
" let atplib#bibflagsstring=join(atplib#bibflagslist,'')
"}}}
" This is the main search engine.
"{{{ atplib#searchbib
" ToDo should not search in comment lines.

" To make it work after kpsewhich is searching for bib path.
" let s:bibfiles=FindBibFiles(bufname('%'))
function! atplib#searchbib(pattern, bibdict, ...) 

    call atplib#outdir()
    " for tex files this should be a flat search.
    let flat 	= &filetype == "plaintex" ? 1 : 0
    let bang	= a:0 >=1 ? a:1 : ""
    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

    " Make a pattern which will match for the elements of the list g:bibentries
    let pattern = '^\s*@\%(\<'.g:bibentries[0].'\>'
    for bibentry in g:bibentries['1':len(g:bibentries)]
	let pattern	= pattern . '\|\<' . bibentry . '\>'
    endfor
    let pattern	= pattern . '\)'
" This pattern matches all entry lines: author = \| title = \| ... 
    let pattern_b = '^\s*\%('
    for bibentry in keys(g:bibflagsdict)
	let pattern_b	= pattern_b . '\|\<' . g:bibflagsdict[bibentry][0] . '\>'
    endfor
    let pattern_b.='\)\s*='

    if g:atp_debugBS
	exe "redir! >>".g:atp_TempDir."/BibSearch.log"
	silent! echo "==========atplib#searchbib==================="
	silent! echo "atplib#searchbib_bibfiles=" . string(s:bibfiles)
	silent! echo "a:pattern=" . a:pattern
	silent! echo "pattern=" . pattern
	silent! echo "pattern_b=" . pattern_b
	silent! echo "bang=" . bang
	silent! echo "flat=" . flat
    endif

    unlet bibentry
    let b:bibentryline={} 
    
    " READ EACH BIBFILE IN TO DICTIONARY s:bibdict, WITH KEY NAME BEING THE bibfilename
    let s:bibdict={}
    let l:bibdict={}
    for l:f in keys(a:bibdict)
	let s:bibdict[l:f]=[]

	" read the bibfile if it is in b:atp_OutDir or in g:atp_raw_bibinputs directory
	" ToDo: change this to look in directories under g:atp_raw_bibinputs. 
	" (see also ToDo in FindBibFiles 284)
" 	for l:path in split(g:atp_raw_bibinputs, ',') 
" 	    " it might be problem when there are multiple libraries with the
" 	    " same name under different locations (only the last one will
" 	    " survive)
" 	    let s:bibdict[l:f]=readfile(fnameescape(findfile(atplib#append(l:f,'.bib'), atplib#append(l:path,"/") . "**")))
" 	endfor
	let l:bibdict[l:f]=copy(a:bibdict[l:f])
	" clear the s:bibdict values from lines which begin with %    
	call filter(l:bibdict[l:f], ' v:val !~ "^\\s*\\%(%\\|@\\cstring\\)"')
    endfor

    if g:atp_debugBS
	silent! echo "values(l:bibdict) len(l:bibdict[v:val]) = " . string(map(deepcopy(l:bibdict), "len(v:val)"))
    endif

    if a:pattern != ""
	for l:f in keys(a:bibdict)
	    let l:list=[]
	    let l:nr=1
	    for l:line in l:bibdict[l:f]
		" Match Pattern:
		" if the line matches find the beginning of this bib field and add its
		" line number to the list l:list
		" remove ligatures and brackets {,} from the line
		let line_without_ligatures = substitute(substitute(l:line,'\C{\|}\|\\\%("\|`\|\^\|=\|\.\|c\|\~\|v\|u\|d\|b\|H\|t\)\s*','','g'), "\\\\'\\s*", '', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\oe', 'oe', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\OE', 'OE', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\ae', 'ae', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\AE', 'AE', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\o', 'o', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\O', 'O', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\i', 'i', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\j', 'j', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\l', 'l', 'g')
		let line_without_ligatures = substitute(line_without_ligatures, '\C\\L', 'L', 'g')

		if line_without_ligatures =~? a:pattern

		    if g:atp_debugBS
			silent! echo "line_without_ligatures that matches " . line_without_ligatures
			silent! echo "____________________________________"
		    endif

		    let l:true=1
		    let l:t=0
		    while l:true == 1
			let l:tnr=l:nr-l:t

			    if g:atp_debugBS
				silent! echo " l:tnr=" . string(l:tnr) . " l:bibdict[". string(l:f) . "][" . string(l:tnr-1) . "]=" . string(l:bibdict[l:f][l:tnr-1])
			    endif

			" go back until the line will match pattern (which
			" should be the beginning of the bib field.
		       if l:bibdict[l:f][l:tnr-1] =~? pattern && l:tnr >= 0
			   let l:true=0
			   let l:list=add(l:list,l:tnr)
		       elseif l:tnr <= 0
			   let l:true=0
		       endif
		       let l:t+=1
		    endwhile
		endif
		let l:nr+=1
	    endfor

	    if g:atp_debugBS
		silent! echo "A l:list=" . string(l:list)
	    endif

    " CLEAR THE l:list FROM ENTRIES WHICH APPEAR TWICE OR MORE --> l:clist
	    let l:pentry="A"		" We want to ensure that l:entry (a number) and l:pentry are different
	    for l:entry in l:list
		if l:entry != l:pentry
		    if count(l:list,l:entry) > 1
			while count(l:list,l:entry) > 1
			    let l:eind=index(l:list,l:entry)
			    call remove(l:list,l:eind)
			endwhile
		    endif 
		    let l:pentry=l:entry
		endif
	    endfor

	    " This is slower than the algorithm above! 
" 	    call sort(filter(l:list, "count(l:list, v:val) == 1"), "atplib#CompareNumbers")

	    if g:atp_debugBS
		silent! echo "B l:list=" . string(l:list)
	    endif

	    let b:bibentryline=extend(b:bibentryline,{ l:f : l:list })

	    if g:atp_debugBS
		silent! echo "atplib#bibsearch b:bibentryline= (pattern != '') " . string(b:bibentryline)
	    endif

	endfor
    endif
"   CHECK EACH BIBFILE
    let l:bibresults={}
"     if the pattern was empty make it faster. 
    if a:pattern == ""
	for l:bibfile in keys(l:bibdict)
	    let l:bibfile_len=len(l:bibdict[l:bibfile])
	    let s:bibd={}
		let l:nr=0
		while l:nr < l:bibfile_len
		    let l:line=l:bibdict[l:bibfile][l:nr]
		    if l:line =~ pattern
			let s:lbibd={}
			let s:lbibd["bibfield_key"]=l:line
			let l:beg_line=l:nr+1
			let l:nr+=1
			let l:line=l:bibdict[l:bibfile][l:nr]
			let l:y=1
			while l:line !~ pattern && l:nr < l:bibfile_len
			    let l:line=l:bibdict[l:bibfile][l:nr]
			    let l:lkey=tolower(
					\ matchstr(
					    \ strpart(l:line,0,
						\ stridx(l:line,"=")
					    \ ),'\<\w*\>'
					\ ))
	" CONCATENATE LINES IF IT IS NOT ENDED
			    let l:y=1
			    if l:lkey != ""
				let s:lbibd[l:lkey]=l:line
	" IF THE LINE IS SPLIT ATTACH NEXT LINE									
				let l:nline=get(l:bibdict[l:bibfile],l:nr+l:y)
				while l:nline !~ '=' && 
					    \ l:nline !~ pattern &&
					    \ (l:nr+l:y) < l:bibfile_len
				    let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:bibfile],l:nr+l:y),'^\s*','','')
				    let l:line=get(l:bibdict[l:bibfile],l:nr+l:y)
				    let l:y+=1
				    let l:nline=get(l:bibdict[l:bibfile],l:nr+l:y)
				    if l:y > 30
					echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry (check line " . l:nr . ") in " . l:f . " line=".l:line
					break
				    endif
				endwhile
				if l:nline =~ pattern 
				    let l:y=1
				endif
			    endif
			    let l:nr+=l:y
			    unlet l:y
			endwhile
			let l:nr-=1
			call extend(s:bibd, { l:beg_line : s:lbibd })
		    else
			let l:nr+=1
		    endif
		endwhile
	    let l:bibresults[l:bibfile]=s:bibd
	    let g:bibresults=l:bibresults
	endfor
	let g:bibresults=l:bibresults

	if g:atp_debugBS
	    silent! echo "atplib#searchbib_bibresults A =" . l:bibresults
	endif

	return l:bibresults
    endif
    " END OF NEW CODE: (up)

    for l:bibfile in keys(b:bibentryline)
	let l:f=l:bibfile . ".bib"
"s:bibdict[l:f])	CHECK EVERY STARTING LINE (we are going to read bibfile from starting
"	line till the last matching } 
 	let s:bibd={}
 	for l:linenr in b:bibentryline[l:bibfile]

	    let l:nr=l:linenr-1
	    let l:i=atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),"{")-atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),"}")
	    let l:j=atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),"(")-atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),")") 
	    let s:lbibd={}
	    let s:lbibd["bibfield_key"]=get(l:bibdict[l:bibfile],l:linenr-1)
	    if s:lbibd["bibfield_key"] !~ '@\w\+\s*{.\+' 
		let l:l=0
		while get(l:bibdict[l:bibfile],l:linenr-l:l) =~ '^\s*$'
		    let l:l+=1
		endwhile
		let s:lbibd["bibfield_key"] .= get(l:bibdict[l:bibfile],l:linenr+l:l)
		let s:lbibd["bibfield_key"] = substitute(s:lbibd["bibfield_key"], '\s', '', 'g')
	    endif

	    let l:x=1
" we go from the first line of bibentry, i.e. @article{ or @article(, until the { and (
" will close. In each line we count brackets.	    
            while l:i>0	|| l:j>0
		let l:tlnr=l:x+l:linenr
		let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),"{")
		let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),"}")
		let l:i+=l:pos-l:neg
		let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),"(")
		let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),")")
		let l:j+=l:pos-l:neg
		let l:lkey=tolower(
			    \ matchstr(
				\ strpart(get(l:bibdict[l:bibfile],l:tlnr-1),0,
				    \ stridx(get(l:bibdict[l:bibfile],l:tlnr-1),"=")
				\ ),'\<\w*\>'
			    \ ))
		if l:lkey != ""
		    let s:lbibd[l:lkey]=get(l:bibdict[l:bibfile],l:tlnr-1)
			let l:y=0
" IF THE LINE IS SPLIT ATTACH NEXT LINE									
			if get(l:bibdict[l:bibfile],l:tlnr-1) !~ '\%()\|}\|"\)\s*,\s*\%(%.*\)\?$'
" 				    \ get(l:bibdict[l:bibfile],l:tlnr) !~ pattern_b
			    let l:lline=substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y-1),'\\"\|\\{\|\\}\|\\(\|\\)','','g')
			    let l:pos=atplib#count(l:lline,"{")
			    let l:neg=atplib#count(l:lline,"}")
			    let l:m=l:pos-l:neg
			    let l:pos=atplib#count(l:lline,"(")
			    let l:neg=atplib#count(l:lline,")")
			    let l:n=l:pos-l:neg
			    let l:o=atplib#count(l:lline,"\"")
    " this checks if bracets {}, and () and "" appear in pairs in the current line:  
			    if l:m>0 || l:n>0 || l:o>l:o/2*2 
				while l:m>0 || l:n>0 || l:o>l:o/2*2 
				    let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"{")
				    let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"}")
				    let l:m+=l:pos-l:neg
				    let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"(")
				    let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),")")
				    let l:n+=l:pos-l:neg
				    let l:o+=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"\"")
    " Let's append the next line: 
				    let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y),'^\s*','','')
				    let l:y+=1
				    if l:y > 30
					echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry at line " . l:linenr . " (check line " . l:tlnr . ") in " . l:f)
					break
				    endif
				endwhile
			    endif
			endif
		endif
" we have to go line by line and we could skip l:y+1 lines, but we have to
" keep l:m, l:o values. It do not saves much.		
		let l:x+=1
		if l:x > 30
			echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry at line " . l:linenr . " in " . l:f
			break
	        endif
		let b:x=l:x
		unlet l:tlnr
	    endwhile
	    
	    let s:bibd[l:linenr]=s:lbibd
	    unlet s:lbibd
	endfor
	let l:bibresults[l:bibfile]=s:bibd
    endfor
    let g:bibresults=l:bibresults

    if g:atp_debugBS
	silent! echo "atplib#searchbib_bibresults A =" . string(l:bibresults)
	redir END
    endif

    return l:bibresults
endfunction
"}}}
" {{{ atplib#searchbib_py
function! atplib#searchbib_py(pattern, bibfiles, ...)
    call atplib#outdir()
    " for tex files this should be a flat search.
    let flat 	= &filetype == "plaintex" ? 1 : 0
    let bang	= a:0 >=1 ? a:1 : ""
    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

    let b:atp_BibFiles=a:bibfiles
python << END
import vim, re

files=vim.eval("b:atp_BibFiles")

def remove_ligatures(string):
    line_without_ligatures = re.sub( "\\\\'\s*", '', re.sub('{|}|\\\\(?:"|`|\^|=|\.|c|~|v|u|d|b|H|t)\s*', '', string))
    line_without_ligatures = re.sub('\\\\oe', 'oe', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\OE', 'OE', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\ae', 'ae', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\AE', 'AE', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\o', 'o', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\O', 'O', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\i', 'i', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\j', 'j', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\l', 'l', line_without_ligatures)
    line_without_ligatures = re.sub('\\\\L', 'L', line_without_ligatures)
    return line_without_ligatures

def remove_quotes(string):
    line=re.sub("'", "\"", string)
    line=re.sub('\\\\', '', line)
    return line
type_pattern=re.compile('\s*@(article|book|mvbook|inbook|bookinbook|suppbook|booklet|collection|mvcollection|incollection|suppcollection|manual|misc|online|patent|periodical|supppertiodical|proceedings|mvproceedings|inproceedings|reference|mvreference|inreference|report|set|thesis|unpublished|custom[a-f]|conference|electronic|masterthesis|phdthesis|techreport|www)', re.I)

# types=['abstract', 'addendum', 'afterword', 'annotation', 'author', 'authortype', 'bookauthor', 'bookpaginator', 'booksupbtitle', 'booktitle', 'booktitleaddon', 'chapter', 'commentator', 'date', 'doi', 'edition', 'editor', 'editora', 'editorb', 'editorc', 'editortype', 'editoratype', 'editorbtype', 'editorctype', 'eid', 'eprint', 'eprintclass', 'eprinttype', 'eventdate', 'eventtile', 'file', 'forword', 'holder', 'howpublished', 'indxtitle', 'institution', 'introduction', 'isan', 'isbn', 'ismn', 'isrn', 'issn', 'issue', 'issuesubtitle', 'issuetitle', 'iswc', 'journalsubtitle', 'journaltitle', 'label', 'language', 'library', 'location', 'mainsubtitle', 'maintitle', 'maintitleaddon', 'month', 'nameaddon', 'note', 'number', 'organization', 'origdate', 'origlanguage', 'origpublisher', 'origname', 'pages', 'pagetotal', 'pagination', 'part', 'publisher', 'pubstate', 'reprinttitle', 'series', 'shortauthor', 'shorteditor', 'shorthand', 'shorthandintro', 'shortjournal', 'shortseries', 'subtitle', 'title', 'titleaddon', 'translator', 'type', 'url', 'urldate', 'venue', 'version', 'volume', 'volumes', 'year', 'crossref', 'entryset', 'entrysubtype', 'execute', 'mrreviewer']

types=['author', 'bookauthor', 'booktitle', 'date', 'editor', 'eprint', 'eprintclass', 'eprinttype', 'howpublished', 'institution', 'journal', 'month', 'note', 'number', 'organization', 'pages', 'publisher', 'school', 'series', 'subtitle', 'title', 'url', 'year', 'mrreviewer', 'volume', 'pages']

def parse_bibentry(bib_entry):
    bib={}
    bib['bibfield_key']=re.sub('\\r$', '', bib_entry[0])
    nr=1
    while nr < len(bib_entry)-1:
        line=bib_entry[nr]
        if not re.match('\s*%', line):
            if not re.search('=', line):
                while not re.search('=', line) and nr < len(bib_entry)-1:
                    val=re.sub('\s*$', '', bib[p_e_type])+" "+re.sub('^\s*', '', re.sub('\t', ' ', line))
                    val=re.sub('%.*', '', val)
                    bib[p_e_type]=remove_quotes(re.sub('\\r$', '', val))
                    nr+=1
                    line=bib_entry[nr]
            else:
                v_break=False
                for e_type in types:
                    if re.match('\s*'+e_type+'\s*=', line, re.I):
                        # this is not working when title is two lines!
                        line=re.sub('%.*', '', line)
                        bib[e_type]=remove_quotes(re.sub('\\r$', '', re.sub('\t', ' ', line)))
                        p_e_type=e_type
                        nr+=1
                        v_break=True
                        break
                if not v_break:
                    nr+=1
#    for key in bib.keys():
#        print(key+"="+bib[key])
#    print("\n")
    return bib

pattern=vim.eval("a:pattern")

if pattern == "":
    pat=""
else:
    pat=pattern
pattern=re.compile(pat, re.I)
pattern_b=re.compile('\s*@\w+\s*{.+', re.I)

bibresults={}
for file in files:
    file_ob=open(file, 'r')
    file_l=file_ob.read().split("\n")
    file_ob.close()
    file_len=len(file_l)
    lnr=0
    bibresults[file]={}
#     if pattern != ""
    while lnr < file_len:
        lnr+=1
        line=file_l[lnr-1]
	if re.search('@string', line):
            continue
        line_without_ligatures=remove_ligatures(line)
        if re.search(pattern, line_without_ligatures):
            """find first line"""
            b_lnr=lnr
#             print("lnr="+str(lnr))
            b_line=line
            while not re.match(pattern_b, b_line) and b_lnr >= 1:
                b_lnr-=1
                b_line=file_l[b_lnr-1]
            """find last line"""
#             print("b_lnr="+str(b_lnr))
            e_lnr=lnr
            e_line=line
            if re.match(pattern_b, e_line):
                lnr+=1
                e_lnr=lnr
                line=file_l[lnr-1]
                e_line=file_l[lnr-1]
#                 print("X "+line)
            while not re.match(pattern_b, e_line) and e_lnr <= file_len:
                e_lnr+=1
                e_line=file_l[min(e_lnr-1, file_len-1)]
            e_lnr-=1
            e_line=file_l[min(e_lnr-1, file_len-1)]
            while re.match('\s*$', e_line):
                e_lnr-=1
                e_line=file_l[e_lnr-1]
#             e_lnr=min(e_lnr, file_len-1)
            bib_entry=file_l[b_lnr-1:e_lnr]
#             print("lnr="+str(lnr))
#             print("b_lnr="+str(b_lnr))
#             print("e_lnr="+str(e_lnr))
            if bib_entry != [] and not re.search('@string', bib_entry[0]):
                entry_dict=parse_bibentry(bib_entry)
                bibresults[file][b_lnr]=entry_dict
#             else:
#                 print("lnr="+str(lnr))
#                 print("b_lnr="+str(b_lnr))
#                 print("e_lnr="+str(e_lnr))
#             print(entry_dict)
#             print("\n".join(bib_entry))
            if lnr < e_lnr:
                lnr=e_lnr
            else:
                lnr+=1
#print(bibresults)
# for key in bibresults.keys():
#     for line in bibresults[key].keys():
#         for bib in bibresults[key][line].keys():
#                 print(bib+"="+bibresults[key][line][bib])
#         print("\n")
vim.command("let bibresults="+str(bibresults))
END
let g:bibresults=bibresults
return bibresults
endfunction
"}}}
"
" {{{ atplib#SearchBibItems
" the argument should be b:atp_MainFile but in any case it is made in this way.
" it specifies in which file to search for include files.
function! atplib#SearchBibItems()
    let time=reltime()

    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)
    " we are going to make a dictionary { citekey : label } (see :h \bibitem) 
    let l:citekey_label_dict={}

    " make a list of include files.
    let l:includefile_list=[]
    if !exists("b:ListOfFiles") || !exists("b:TypeDict")
	call TreeOfFiles(b:atp_MainFile)
    endif
    for f in b:ListOfFiles
	if b:TypeDict[f] == "input"
	    call add(l:includefile_list, f)
	endif
    endfor
    call add(l:includefile_list, atp_MainFile) 

    if has("python")
python << PEND
import vim, re
files=vim.eval("l:includefile_list")
citekey_label_dict={}
for f in files:
    f_o=open(f, 'r')
    f_l=f_o.read().split("\n")
    f_o.close()
    for line in f_l:
        if re.match('[^%]*\\\\bibitem', line):
            match=re.search('\\\\bibitem\s*(?:\[([^\]]*)\])?\s*{([^}]*)}\s*(.*)', line)
            if match:
                label=match.group(1)
                if label == None:
                    label = ""
                key=match.group(2)
                if key == None:
                    key = ""
                rest=match.group(3)
                if rest == None:
                    rest = ""
                if key != "":
                    citekey_label_dict[key]={ 'label' : label, 'rest' : rest }
vim.command("let l:citekey_label_dict="+str(citekey_label_dict))
PEND
    else
        " search for bibitems in all include files.
        for l:ifile in l:includefile_list

            let l:input_file = atplib#ReadInputFile(l:ifile,0)

                " search for bibitems and make a dictionary of labels and citekeys
                for l:line in l:input_file
                    if l:line =~# '^[^%]*\\bibitem'
                        let l:label=matchstr(l:line,'\\bibitem\s*\[\zs[^]]*\ze\]')
                        let l:key=matchstr(l:line,'\\bibitem\s*\%(\[[^]]*\]\)\?\s*{\zs[^}]*\ze}') 
                        let l:rest=matchstr(l:line,'\\bibitem\s*\%(\[[^]]*\]\)\?\s*{[^}]*}\s*\zs')
                        if l:key != ""
                            call extend(l:citekey_label_dict, { l:key : { 'label' : l:label, 'rest' : l:rest } }, 'error') 
                        endif
                    endif
                endfor
        endfor
    endif
	
    let g:time_SearchBibItems=reltimestr(reltime(time))
    return l:citekey_label_dict
endfunction
" }}}
" Showing results 
"{{{ atplib#showresults
" FLAGS:
" for currently supported flags see ':h atp_bibflags'
" All - all flags	
" L - last flag
" a - author
" e - editor
" t - title
" b - booktitle
" j - journal
" s - series
" y - year
" n - number
" v - volume
" p - pages
" P - publisher
" N - note
" S - school
" h - howpublished
" o - organization
" i - institution
" R - mrreviewer

function! atplib#showresults(bibresults, flags, pattern, bibdict)
 
    "if nothing was found inform the user and return:
    if len(a:bibresults) == count(a:bibresults, {})
	echo "BibSearch: no bib fields matched."
	if g:atp_debugBS
	    exe "redir! >> ".g:atp_TempDir."/BibSeach.log"
	    silent! echo "==========atplib#showresults================="
	    silent! echo "atplib#showresults return A - no bib fields matched. "
	    redir END
	endif
	return 0
    elseif g:atp_debugBS
	    exe "redir! >> ".g:atp_TempDir."/BibSearch.log"
	    silent! echo "==========atplib#showresults================="
	    silent! echo "atplib#showresults return B - found something. "
	    redir END
    endif

    function! s:showvalue(value)
	return substitute(strpart(a:value,stridx(a:value,"=")+1),'^\s*','','')
    endfunction

    let s:z=1
    let l:ln=1
    let l:listofkeys={}
"--------------SET UP FLAGS--------------------------    
	    let l:allflagon=0
	    let l:flagslist=[]
	    let l:kwflagslist=[]

    " flags o and i are synonims: (but refer to different entry keys): 
	if a:flags =~# 'i' && a:flags !~# 'o'
	    let l:flags=substitute(a:flags,'i','io','') 
	elseif a:flags !~# 'i' && a:flags =~# 'o'
	    let l:flags=substitute(a:flags,'o','oi','')
	endif
	if a:flags !~# 'All'
	    if a:flags =~# 'L'
"  		if strpart(a:flags,0,1) != '+'
"  		    let l:flags=b:atp_LastBibFlags . substitute(a:flags, 'L', '', 'g')
"  		else
 		    let l:flags=b:atp_LastBibFlags . substitute(a:flags, 'L', '', 'g')
"  		endif
		let g:atp_LastBibFlags = deepcopy(b:atp_LastBibFlags)
	    else
		if a:flags == "" 
		    let l:flags=g:defaultbibflags
		elseif strpart(a:flags,0,1) != '+' && a:flags !~ 'All' 
		    let l:flags=a:flags
		elseif strpart(a:flags,0,1) == '+' && a:flags !~ 'All'
		    let l:flags=g:defaultbibflags . strpart(a:flags,1)
		endif
	    endif
	    let b:atp_LastBibFlags=substitute(l:flags,'+\|L','','g')
		if l:flags != ""
		    let l:expr='\C[' . g:bibflagsstring . ']' 
		    while len(l:flags) >=1
			let l:oneflag=strpart(l:flags,0,1)
    " if we get a flag from the variable g:bibflagsstring we copy it to the list l:flagslist 
			if l:oneflag =~ l:expr
			    let l:flagslist=add(l:flagslist, l:oneflag)
			    let l:flags=strpart(l:flags,1)
    " if we get '@' we eat ;) two letters to the list l:kwflagslist			
			elseif l:oneflag == '@'
			    let l:oneflag=strpart(l:flags,0,2)
			    if index(keys(g:kwflagsdict),l:oneflag) != -1
				let l:kwflagslist=add(l:kwflagslist,l:oneflag)
			    endif
			    let l:flags=strpart(l:flags,2)
    " remove flags which are not defined
			elseif l:oneflag !~ l:expr && l:oneflag != '@'
			    let l:flags=strpart(l:flags,1)
			endif
		    endwhile
		endif
	else
    " if the flag 'All' was specified. 	    
	    let l:flagslist=split(g:defaultallbibflags, '\zs')
	    let l:af=substitute(a:flags,'All','','g')
	    for l:kwflag in keys(g:kwflagsdict)
		if a:flags =~ '\C' . l:kwflag	
		    call extend(l:kwflagslist,[l:kwflag])
		endif
	    endfor
	endif

	"NEW: if there are only keyword flags append default flags
	if len(l:kwflagslist) > 0 && len(l:flagslist) == 0 
	    let l:flagslist=split(g:defaultbibflags,'\zs')
	endif

"   Open a new window.
    let l:bufnr=bufnr("___Bibsearch: " . a:pattern . "___"  )
    if l:bufnr != -1
	let l:bdelete=l:bufnr . "bwipeout"
	exe l:bdelete
    endif
    unlet l:bufnr
    let l:openbuffer=" +setl\\ buftype=nofile\\ filetype=bibsearch_atp " . fnameescape("___Bibsearch: " . a:pattern . "___")
    if g:vertical ==1
	let l:openbuffer="keepalt vsplit " . l:openbuffer 
	let l:skip=""
    else
	let l:openbuffer="keepalt split " . l:openbuffer 
	let l:skip="       "
    endif

    let BufNr	= bufnr("%")
    let LineNr	= line(".")
    let ColNr	= col(".")
    silent exe l:openbuffer

"     set the window options
    silent call atplib#setwindow()
" make a dictionary of clear values, which we will fill with found entries. 	    
" the default value is no<keyname>, which after all is matched and not showed
" SPEED UP:
    let l:values={'bibfield_key' : 'nokey'}	
    for l:flag in g:bibflagslist
	let l:values_clear=extend(l:values,{ g:bibflagsdict[l:flag][0] : 'no' . g:bibflagsdict[l:flag][0] })
    endfor

" SPEED UP: 
    let l:kwflag_pattern="\\C"	
    let l:len_kwflgslist=len(l:kwflagslist)
    let l:kwflagslist_rev=reverse(deepcopy(l:kwflagslist))
    for l:lkwflag in l:kwflagslist
	if index(l:kwflagslist_rev,l:lkwflag) == 0 
	    let l:kwflag_pattern.=g:kwflagsdict[l:lkwflag]
	else
	    let l:kwflag_pattern.=g:kwflagsdict[l:lkwflag].'\|'
	endif
    endfor
"     let b:kwflag_pattern=l:kwflag_pattern

    for l:bibfile in keys(a:bibresults)
	if a:bibresults[l:bibfile] != {}
	    call setline(l:ln, "Found in " . l:bibfile )	
	    let l:ln+=1
	endif
	for l:linenr in copy(sort(keys(a:bibresults[l:bibfile]), "atplib#CompareNumbers"))
	    let l:values=deepcopy(l:values_clear)
	    let b:values=l:values
" fill l:values with a:bibrsults	    
	    let l:values["bibfield_key"]=a:bibresults[l:bibfile][l:linenr]["bibfield_key"]
" 	    for l:key in keys(l:values)
" 		if l:key != 'key' && get(a:bibresults[l:bibfile][l:linenr],l:key,"no" . l:key) != "no" . l:key
" 		    let l:values[l:key]=a:bibresults[l:bibfile][l:linenr][l:key]
" 		endif
" SPEED UP:
		call extend(l:values,a:bibresults[l:bibfile][l:linenr],'force')
" 	    endfor
" ----------------------------- SHOW ENTRIES -------------------------
" first we check the keyword flags, @a,@b,... it passes if at least one flag
" is matched
	    let l:check=0
" 	    for l:lkwflag in l:kwflagslist
" 	        let l:kwflagpattern= '\C' . g:kwflagsdict[l:lkwflag]
" 		if l:values['bibfield_key'] =~ l:kwflagpattern
" 		   let l:check=1
" 		endif
" 	    endfor
	    if l:values['bibfield_key'] =~ l:kwflag_pattern
		let l:check=1
	    endif
	    if l:check == 1 || len(l:kwflagslist) == 0
		let l:linenumber=index(a:bibdict[l:bibfile],l:values["bibfield_key"])+1
 		call setline(l:ln,s:z . ". line " . l:linenumber . "  " . l:values["bibfield_key"])
		let l:ln+=1
 		let l:c0=atplib#count(l:values["bibfield_key"],'{')-atplib#count(l:values["bibfield_key"],'(')

	
" this goes over the entry flags:
		for l:lflag in l:flagslist
" we check if the entry was present in bibfile:
		    if l:values[g:bibflagsdict[l:lflag][0]] != "no" . g:bibflagsdict[l:lflag][0]
" 			if l:values[g:bibflagsdict[l:lflag][0]] =~ a:pattern
			    call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
			    let l:ln+=1
" 			else
" 			    call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
" 			    let l:ln+=1
" 			endif
		    endif
		endfor
		let l:lastline=getline(line('$'))
		let l:c1=atplib#count(l:lastline,'{')-atplib#count(l:lastline,'}')
		let l:c2=atplib#count(l:lastline,'(')-atplib#count(l:lastline,')')
		let l:c3=atplib#count(l:lastline,'\"')
		if l:c0 == 1 && l:c1 == -1
		    call setline(line('$'),substitute(l:lastline,'}\s*$','',''))
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == 1 && l:c1 == 0	
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c2 == -1
		    call setline(line('$'),substitute(l:lastline,')\s*$','',''))
		    call setline(l:ln,')')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c1 == 0	
		    call setline(l:ln,')')
		    let l:ln+=1
		endif
		let l:listofkeys[s:z]=l:values["bibfield_key"]
		let s:z+=1
	    endif
	endfor
    endfor
    if g:atp_debugBS
	let g:pattern	= a:pattern
    endif
    if has("python") || g:atp_bibsearch == "python"
        let pattern_tomatch = substitute(a:pattern, '(', '\\(', 'g')
        let pattern_tomatch = substitute(pattern_tomatch, ')', '\\)', 'g')
        let pattern_tomatch = substitute(pattern_tomatch, '|', '\\|', 'g')
    else
        let pattern_tomatch = a:pattern
    endif
    let pattern_tomatch = substitute(pattern_tomatch, '\Co', 'oe\\=', 'g')
    let pattern_tomatch = substitute(pattern_tomatch, '\CO', 'OE\\=', 'g')
    let pattern_tomatch = substitute(pattern_tomatch, '\Ca', 'ae\\=', 'g')
    let pattern_tomatch = substitute(pattern_tomatch, '\CA', 'AE\\=', 'g')
    if g:atp_debugBS
	let g:pm = pattern_tomatch
    endif
    let pattern_tomatch	= join(split(pattern_tomatch, '\zs\\\@!\\\@<!'),  '[''"{\}]\{,3}')
    if g:atp_debugBS
	let g:pattern_tomatch = pattern_tomatch
    endif
    if pattern_tomatch != "" && pattern_tomatch != ".*"
	silent! call matchadd("Search", '\c' . pattern_tomatch)
	let @/=pattern_tomatch
    endif
    " return l:listofkeys which will be available in the bib search buffer
    " as b:ListOfKeys (see the BibSearch function below)
    let b:ListOfBibKeys = l:listofkeys
    let b:BufNr		= BufNr

    return l:listofkeys
endfunction
"}}}
"}}}
" URL query: (by some strange reason this is not working moved to url_query.py)
" function! atplib#URLquery(url) "{{{
" python << EOF
" import urllib2, tempfile, vim
" url  = vim.eval("a:url") 
" print(url)
" temp = tempfile.mkstemp("", "atp_ams_")
" 
" f    = open(temp[1], "w+")
" data = urllib2.urlopen(url)
" f.write(data.read())
" vim.command("return '"+temp[1]+"'")
" EOF
" endfunction "}}}

" This function sets the window options common for toc and bibsearch windows.
"{{{1 atplib#setwindow
" this function sets the options of BibSearch, ToC and Labels windows.
function! atplib#setwindow()
" These options are set in the command line
" +setl\\ buftype=nofile\\ filetype=bibsearch_atp   
" +setl\\ buftype=nofile\\ filetype=toc_atp\\ nowrap
" +setl\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp
	setlocal nonumber
	setlocal norelativenumber
 	setlocal winfixwidth
	setlocal noswapfile	
	setlocal nobuflisted
	if &filetype == "bibsearch_atp"
" 	    setlocal winwidth=30
	    setlocal nospell
	elseif &filetype == "toc_atp"
" 	    setlocal winwidth=20
	    setlocal nospell
	    setlocal cursorline 
	endif
" 	nnoremap <expr> <buffer> <C-W>l	"keepalt normal l"
" 	nnoremap <buffer> <C-W>h	"keepalt normal h"
endfunction
" }}}1
" {{{1 atplib#count
function! atplib#count(line, keyword,...)
   
    let method = ( a:0 == 0 || a:1 == 0 ) ? 0 : 1

    let line=a:line
    let i=0  
    if method==0
	while stridx(line, a:keyword) != '-1'
	    let line	= strpart(line, stridx(line, a:keyword)+1)
	    let i +=1
	endwhile
    elseif method==1
	let pat = a:keyword.'\zs'
	while line =~ pat
	    let line	= strpart(line, match(line, pat))
	    let i +=1
	endwhile
    endif
    return i
endfunction
" }}}1
" Used to append / at the end of a directory name
" {{{1 atplib#append 	
fun! atplib#append(where, what)
    return substitute(a:where, a:what . '\s*$', '', '') . a:what
endfun
" }}}1
" Used to append extension to a file name (if there is no extension).
" {{{1 atplib#append_ext 
" extension has to be with a dot.
fun! atplib#append_ext(fname, ext)
    return substitute(a:fname, a:ext . '\s*$', '', '') . a:ext
endfun
" }}}1

" Searching Tools: (kpsewhich)
" {{{1 atplib#KpsewhichGlobPath 
" 	a:format	is the format as reported by kpsewhich --help
" 	a:path		path if set to "", then kpse which will find the path.
" 			The default is what 'kpsewhich -show-path tex' returns
" 			with "**" appended. 
" 	a:name 		can be "*" then finds all files with the given extension
" 			or "*.cls" to find all files with a given extension.
" 	a:1		modifiers (the default is ":t:r")
" 	a:2		filters path names matching the pattern a:1
" 	a:3		filters out path names not matching the pattern a:2
"
" 	Argument a:path was added because it takes time for kpsewhich to return the
" 	path (usually ~0.5sec). ATP asks kpsewhich on start up
" 	(g:atp_kpsewhich_tex) and then locks the variable (this will work
" 	unless sb is reinstalling tex (with different personal settings,
" 	changing $LOCALTEXMF) during vim session - not that often). 
"
" Example: call atplib#KpsewhichGlobPath('tex', '', '*', ':p', '^\(\/home\|\.\)','\%(texlive\|kpsewhich\|generic\)')
" gives on my system only the path of current dir (/.) and my localtexmf. 
" this is done in 0.13s. The long pattern is to 
"
" atp#KpsewhichGlobPath({format}, {path}, {expr=name}, [ {mods}, {pattern_1}, {pattern_2}]) 
function! atplib#KpsewhichGlobPath(format, path, name, ...)
"     let time	= reltime()
    let modifiers = a:0 == 0 ? ":t:r" : a:1
    if a:path == ""
	let path	= substitute(substitute(system("kpsewhich -show-path ".a:format ),'!!','','g'),'\/\/\+','\/','g')
	let path	= substitute(path,':\|\n',',','g')
	let path_list	= split(path, ',')
	let idx		= index(path_list, '.')
	if idx != -1
	    let dot 	= remove(path_list, index(path_list,'.')) . ","
	else
	    let dot 	= ""
	endif
	call map(path_list, 'v:val . "**"')

	let path	= dot . join(path_list, ',')
    else
	let path = a:path
    endif
    " If a:2 is non zero (if not given it is assumed to be 0 for compatibility
    " reasons)
    if get(a:000, 1, 0) != "0"
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val =~ a:2')
	let path	= join(path_list, ',')
    endif
    if get(a:000, 2, 0) != "0"
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val !~ a:3')
	let path	= join(path_list, ',')
    endif

    let list	= split(globpath(path, a:name),"\n") 
    call map(list, 'fnamemodify(v:val, modifiers)')
    return list
endfunction
" }}}1
" {{{1 atplib#KpsewhichFindFile
" the arguments are similar to atplib#KpsewhichGlob except that the a:000 list
" is shifted:
" a:1		= path	
" 			if set to "" then kpsewhich will find the path.
" a:2		= count (as for findfile())
" a:3		= modifiers 
" a:4		= positive filter for path (see KpsewhichGLob a:1)
" a:5		= negative filter for path (see KpsewhichFind a:2)
"
" needs +path_extra vim feature
"
" atp#KpsewhichFindFile({format}, {expr=name}, [{path}, {count}, {mods}, {pattern_1}, {pattern_2}]) 
function! atplib#KpsewhichFindFile(format, name, ...)

    " Unset the suffixadd option
    let saved_sua	= &l:suffixesadd
    let &l:sua	= ""

"     let time	= reltime()
    let path	= a:0 >= 1 ? a:1 : ""
    let l:count	= a:0 >= 2 ? a:2 : 0
    let modifiers = a:0 >= 3 ? a:3 : ""
    " This takes most of the time!
    if path == ""
	let path	= substitute(substitute(system("kpsewhich -show-path ".a:format ),'!!','','g'),'\/\/\+','\/','g')
	let path	= substitute(path,':\|\n',',','g')
	let path_list	= split(path, ',')
	let idx		= index(path_list, '.')
	if idx != -1
	    let dot 	= remove(path_list, index(path_list,'.')) . ","
	else
	    let dot 	= ""
	endif
	call map(path_list, 'v:val . "**"')

	let path	= dot . join(path_list, ',')
	unlet path_list
    endif


    " If a:2 is non zero (if not given it is assumed to be 0 for compatibility
    " reasons)
    if get(a:000, 3, 0) != 0
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val =~ a:4')
	let path	= join(path_list, ',')
    endif
    if get(a:000, 4, 0) != 0
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val !~ a:5')
	let path	= join(path_list, ',')
    endif

    if l:count >= 1
	let result	= findfile(a:name, path, l:count)
    elseif l:count == 0
	let result	= findfile(a:name, path)
    elseif l:count < 0
	let result	= findfile(a:name, path, -1)
    endif
	

    if l:count >= 0 && modifiers != ""
	let result	= fnamemodify(result, modifiers) 
    elseif l:count < 0 && modifiers != ""
	call map(result, 'fnamemodify(v:val, modifiers)')
    endif

    let &l:sua	= saved_sua
    return result
endfunction
" }}}1

" List Functions:
" atplib#Extend {{{1
" arguments are the same as for extend(), but it adds only the entries which
" are not present.
function! atplib#Extend(list_a,list_b,...)
    let list_a=deepcopy(a:list_a)
    let list_b=deepcopy(a:list_b)
    let diff=filter(list_b,'count(l:list_a,v:val) == 0')
    if a:0 == 0
	return extend(list_a,diff)
    else
	return extend(list_a,diff, a:1)
    endif
endfunction
" }}}1
" {{{1 atplib#Add
function! atplib#Add(list,what)
    let new=[] 
    for element in a:list
	call add(new,element . a:what)
    endfor
    return new
endfunction
"}}}1

" Font Preview Functions:
"{{{1 Font Preview Functions
" These functions search for fd files and show them in a buffer with filetype
" 'fd_atp'. There are additional function for this filetype written in
" fd_atp.vim ftplugin. Distributed with atp.
"{{{2 atplib#FdSearch
"([<pattern>,<method>])
" There are two methods: 
" 	0 - match fd file names ( ":t" filename modifier)        <- the default one
" 	1 - match fd file path 
function! atplib#FdSearch(...)

    if a:0 == 0
	let pattern	= ""
	let method	= 0
    else
	let pattern	= ( a:0 >= 1 ? a:1 : "" )
	let method	= ( a:0 >= 2 ? a:2 : 0 )
    endif

"     let g:method = method
"     let g:pattern = pattern

    " Find fd file
    let path	= substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
    let path	= substitute(path,':\|\n',',','g')
    let fd 	= split(globpath(path,"**/*.fd"),'\n') 

    let g:fd	= copy(fd)

    " Match for l:pattern
    let fd_matches=[]
    if method == 0
	call filter(fd, 'fnamemodify(v:val, ":t") =~ pattern') 
    else
	call filter(fd, 'v:val =~ pattern') 
    endif

    return fd
endfunction
"{{{2 atplib#FontSearch
" atplib#FontSearch(method,[<pattern>]) 
" method = "" match for name of fd file
" method = "!" match against whole path
if !exists("*atplib#FontSearch")
function! atplib#FontSearch(method,...)
	
    let l:method	= ( a:method == "!" ? 1 : 0 )
    let l:pattern	= ( a:0 ? a:1 : "" )

    let s:fd_matches=atplib#FdSearch(l:pattern, l:method)

    " Open Buffer and list fd files
    " set filetype to fd_atp
    let l:tmp_dir=tempname()
    call mkdir(l:tmp_dir)
    let l:fd_bufname="fd_list " . l:pattern
    let l:openbuffer="32vsplit! +setl\\ nospell\\ ft=fd_atp ". fnameescape(l:tmp_dir . "/" . l:fd_bufname )

    let g:fd_matches=[]
    if len(s:fd_matches) > 0
	echohl WarningMsg
	echomsg "[ATP:] found " . len(s:fd_matches) . " files."
	echohl None
	" wipe out the old buffer and open new one instead
	if buflisted(fnameescape(l:tmp_dir . "/" . l:fd_bufname))
	    silent exe "bd! " . bufnr(fnameescape(l:tmp_dir . "/" . l:fd_bufname))
	endif
	silent exe l:openbuffer
	" make l:tmp_dir available for this buffer.
" 	let b:tmp_dir=l:tmp_dir
	cd /tmp
	map <buffer> q	:bd<CR>

	" print the lines into the buffer
	let l:i=0
	call setline(1,"FONT DEFINITION FILES:")
	for l:fd_file in s:fd_matches
	    " we put in line the last directory/fd_filename:
	    " this is what we cut:
	    let l:path=fnamemodify(l:fd_file,":h:h")
	    let l:fd_name=substitute(l:fd_file,"^" . l:path . '/\?','','')
" 	    call setline(line('$')+1,fnamemodify(l:fd_file,":t"))
	    call setline(line('$')+1,l:fd_name)
	    call add(g:fd_matches,l:fd_file)
	    let l:i+=1
	endfor
	call append('$', ['', 'maps:', 
			\ 'p       Preview font ', 
			\ 'P       Preview font+tex file', 
			\ '<Tab>   Show Fonts in fd file', 
			\ '<Enter> Open fd file', 
			\ 'q       "bd!"',
			\ '',
			\ 'Note: p/P works in visual mode'])
	silent w
	setlocal nomodifiable
	setlocal ro
    else
	echohl WarningMsg
	if !l:method
	    echomsg "[ATP:] no fd file found, try :FontSearch!"
	else
	    echomsg "[ATP:] no fd file found."
	endif
	echohl None
    endif

endfunction
endif
"}}}2
"{{{2 atplib#Fd_completion /not needed/
" if !exists("*atplib#Fd_completion")
" function! atplib#Fd_completion(A,C,P)
"     	
"     " Find all files
"     let l:path=substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
"     let l:path=substitute(l:path,':\|\n',',','g')
"     let l:fd=split(globpath(l:path,"**/*.fd"),"\n") 
"     let l:fd=map(l:fd,'fnamemodify(v:val,":t:r")')
" 
"     let l:matches=[]
"     for l:fd_file in l:fd
" 	if l:fd_file =~ a:A
" 	    call add(l:matches,l:fd_file)
" 	endif
"     endfor
"     return l:matches
" endfunction
" endif
" }}}2
" {{{2 atplib#OpenFdFile /not working && not needed?/
" function! atplib#OpenFdFile(name)
"     let l:path=substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
"     let l:path=substitute(l:path,':\|\n',',','g')
"     let b:path=l:path
"     let l:fd=split(globpath(l:path,"**/".a:name.".fd"),"\n") 
"     let l:fd=map(l:fd,'fnamemodify(v:val,":t:r")')
"     let b:fd=l:fd
"     execute "split +setl\\ ft=fd_atp " . l:fd[0]
" endfunction
" }}}2
"{{{2 atplib#Preview
" keep_tex=1 open the tex file of the sample file, otherwise it is deleted (at
" least from the buffer list).
" To Do: fd_file could be a list of fd_files which we would like to see, every
" font should be done after \pagebreak[4]
" if a:fd_files=['buffer'] it means read the current buffer (if one has opened
" an fd file).
function! atplib#Preview(fd_files,keep_tex)
    if a:fd_files != ["buffer"]
	let l:fd_files={}
	for l:fd_file in a:fd_files
	    call extend(l:fd_files,{fd_file : readfile(l:fd_file)})
	endfor
    else
	let l:fd_files={bufname("%"):getline(1,"$")}
    endif
    unlet l:fd_file

    let l:declare_command='\C\%(DeclareFontShape\%(WithSizes\)\?\|sauter@\%(tt\)\?family\|EC@\%(tt\)\?family\|krntstexmplfamily\|HFO@\%(tt\)\?family\)'
    let b:declare_command=l:declare_command
    
    let l:font_decl_dict={}
    for l:fd_file in a:fd_files
	call extend(l:font_decl_dict, {l:fd_file : [ ]})
	for l:line in l:fd_files[l:fd_file]
	    if l:line =~ '\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'
		call add(l:font_decl_dict[l:fd_file],l:line)
	    endif
	endfor
    endfor

    if exists("b:tmp_dir")
	let l:tmp_dir=b:tmp_dir
    else
	let l:tmp_dir=tempname()
    endif
    if !isdirectory(l:tmp_dir)
	call mkdir(l:tmp_dir)
    endif
    if a:fd_files == ["buffer"]
	" WINDOWS NOT COMPATIBLE
	let l:testfont_file=l:tmp_dir . "/" . fnamemodify(bufname("%"),":t:r") . ".tex"
    else
	" the name could be taken from the pattern
	" or join(map(keys(deepcopy(a:fd_files)),'substitute(fnamemodify(v:val,":t:r"),".fd$","","")'),'_')
	" though it can be quite a long name.
	let l:testfont_file=l:tmp_dir . "/" . fnamemodify(a:fd_files[0],":t:r") . ".tex"
    endif
    " WINDOWS NOT COMPATIBLE
"     call system("touch " . l:testfont_file)
    
    let l:fd_bufnr=bufnr("%")

    let s:text="On November 14, 1885, Senator \\& Mrs.~Leland Stanford called
		\ together at their San Francisco mansion the 24~prominent men who had
		\ been chosen as the first trustees of The Leland Stanford Junior University.
		\ They handed to the board the Founding Grant of the University, which they
		\ had executed three days before.\\\\
		\ (!`THE DAZED BROWN FOX QUICKLY GAVE 12345--67890 JUMPS!)"

"     let l:text="On November 14, 1885, Senator \\& Mrs.~Leland Stanford called
" 	\ together at their San Francisco mansion the 24~prominent men who had
" 	\ been chosen as the first trustees of The Leland Stanford Junior University.
" 	\ They handed to the board the Founding Grant of the University, which they
" 	\ had executed three days before. This document---with various amendments,
" 	\ legislative acts, and court decrees---remains as the University's charter.
" 	\ In bold, sweeping language it stipulates that the objectives of the University
" 	\ are ``to qualify students for personal success and direct usefulness in life;
" 	\ and to promote the public welfare by exercising an influence in behalf of
" 	\ humanity and civilization, teaching the blessings of liberty regulated by
" 	\ law, and inculcating love and reverence for the great principles of
" 	\ government as derived from the inalienable rights of man to life, liberty,
" 	\ and the pursuit of happiness.''\\
" 	\ (!`THE DAZED BROWN FOX QUICKLY GAVE 12345--67890 JUMPS!)\\par}}
" 	\ \\def\\\moretext{?`But aren't Kafka's Schlo{\\ss} and {\\AE}sop's {\\OE}uvres
" 	\ often na{\\"\\i}ve  vis-\\`a-vis the d{\\ae}monic ph{\\oe}nix's official r\\^ole
" 	\ in fluffy souffl\\'es? }
" 	\ \\moretext"

    if a:fd_files == ["buffer"]
	let l:openbuffer="edit "
    else
	let l:openbuffer="topleft split!"
    endif
    execute l:openbuffer . " +setlocal\\ ft=tex\\ modifiable\\ noro " . l:testfont_file 
    let b:atp_ProjectScript = 0
    map <buffer> q :bd!<CR>

    call setline(1,'\documentclass{article}')
    call setline(2,'\oddsidemargin=0pt')
    call setline(3,'\textwidth=450pt')
    call setline(4,'\textheight=700pt')
    call setline(5,'\topmargin=-10pt')
    call setline(6,'\headsep=0pt')
    call setline(7,'\begin{document}')

    let l:i=8
    let l:j=1
    let l:len_font_decl_dict=len(l:font_decl_dict)
    let b:len_font_decl_dict=l:len_font_decl_dict
    for l:fd_file in keys(l:font_decl_dict) 
	if l:j == 1 
	    call setline(l:i,'\textsc\textbf{\Large Fonts from the file '.l:fd_file.'}\\[2em]')
	    let l:i+=1
	else
" 	    call setline(l:i,'\pagebreak[4]')
	    call setline(l:i,'\vspace{4em}')
	    call setline(l:i+1,'')
	    call setline(l:i+2,'\textsc\textbf{\Large Fonts from the file '.l:fd_file.'}\\[2em]')
	    let l:i+=3
	endif
	let l:len_font_decl=len(l:font_decl_dict[l:fd_file])
	let b:match=[]
	for l:font in l:font_decl_dict[l:fd_file]
	    " SHOW THE FONT ENCODING, FAMILY, SERIES and SHAPE
	    if matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') == "b" ||
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') == "bx"
		let b:show_font='\noindent{\large \textit{Font Encoding}: \textsf{' . 
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textit{Font Family}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^}#]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textit{Font Series}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') . '}' . 
			    \ ' \textit{Font Shape}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}') . '}}\\[2pt]'
	    else
		let b:show_font='\noindent{\large \textbf{Font Encoding}: \textsf{' . 
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textbf{Font Family}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^}#]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textbf{Font Series}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') . '}' . 
			    \ ' \textbf{Font Shape}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}') . '}}\\[2pt]'
	    endif
	    call setline(l:i,b:show_font)
	    let l:i+=1
	    " CHANGE THE FONT
	    call setline(l:i,'{' . substitute(
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'),
			\ l:declare_command,'usefont','') . 
			\ '\selectfont')
	    " WRITE SAMPLE TEXT
	    call add(b:match,matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'))
	    let l:i+=1
	    " END
	    if l:j<l:len_font_decl
		call setline(l:i,s:text . '}\\\\')
	    else
		call setline(l:i,s:text . '}')
	    endif
	    let l:i+=1
	    let l:j+=1
	endfor
    endfor
    call setline(l:i,'\end{document}')
    silent w
    if b:atp_TexCompiler =~ '^pdf'	
	let l:ext=".pdf"
    else
	let l:ext=".dvi"
    endif
    call system(b:atp_TexCompiler . " " . l:testfont_file . 
	    \ " && " . b:atp_Viewer . " " . fnamemodify(l:testfont_file,":p:r") . l:ext ." &")
    if !a:keep_tex
	silent exe "bd"
    endif
endfunction
" }}}2
"{{{2 atplib#FontPreview
" a:fd_file  pattern to find fd file (.fd will be appended if it is not
" present at the end),
" a:1 = encoding
" a:2 = l:keep_tex, i.e. show the tex source.
function! atplib#FontPreview(method, fd_file,...)


    let l:method	= ( a:method == "!" ? 1 : 0 )
    let l:enc		= ( a:0 >= 1 ? a:1 : "" )
    let l:keep_tex 	= ( a:0 >= 2 ? a:2 : 0 )

    if filereadable(a:fd_file)
	let l:fd_file=a:fd_file
    else
	" Find fd file
	if a:fd_file !~ '.fd\s*$'
	    let l:fd_file=a:fd_file.".*.fd"
	else
	    let l:fd_file=a:fd_file
	endif

	let l:fd=atplib#FdSearch(a:fd_file, l:method)
	let g:fd=l:fd
	if !empty(l:enc)
	    call filter(l:fd, "fnamemodify(v:val, ':t') =~ '^' . l:enc")
	endif

	if len(l:fd) == 0
	    if !l:method
		echo "FD file not found. Try :FontPreview!"
	    else
		echo "FD file not found."
	    endif
	    return
	elseif len(l:fd) == 1
	    let l:fd_file_list=l:fd
	else
	    let l:i=1
	    for l:f in l:fd
		echo l:i." ".substitute(f,'^'.fnamemodify(f,":h:h").'/\?','','')
		let l:i+=1
	    endfor
	    let l:choice=input('Which fd file? ')
	    if l:choice == "" 
		return
	    endif
	    let l:choice_list=split(l:choice,',')
	    let b:choice_list=l:choice_list
	    " if there is 1-4  --> a list of 1,2,3,4
	    let l:new_choice_list=[]
	    for l:ch in l:choice_list
		if l:ch =~ '^\d\+$'
		    call add(l:new_choice_list,l:ch)
		elseif l:ch =~ '^\d\+\s*-\s*\d\+$'
		    let l:b=matchstr(l:ch,'^\d\+')
		    let l:e=matchstr(l:ch,'\d\+$')
		    let l:k=l:b
		    while l:k<=l:e
			call add(l:new_choice_list,l:k)
			let l:k+=1
		    endwhile
		endif
	    endfor
	    let b:new_choice_list=l:new_choice_list
	    let l:fd_file_list=map(copy(l:new_choice_list),'get(l:fd,(v:val-1),"")')
	    let l:fd_file_list=filter(l:fd_file_list,'v:val != ""')
" 	    let l:fd_file=get(l:fd,l:choice-1,"return")
	    if len(l:fd_file_list) == 0
		return
	    endif
	endif
    endif
    call atplib#Preview(l:fd_file_list,l:keep_tex)
endfunction
"}}}2
" {{{2 atplib#ShowFonts
function! atplib#ShowFonts_vim(fd_file)
    let l:declare_command='\C\%(DeclareFontShape\%(WithSizes\)\?\|sauter@\%(tt\)\?family\|EC@\%(tt\)\?family\|krntstexmplfamily\|HFO@\%(tt\)\?family\)'
    
    let l:font_decl=[]
    for l:line in readfile(a:fd_file)
	if l:line =~ '\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'
	    call add(l:font_decl,l:line)
	endif
    endfor
    let l:font_commands=[]
    for l:font in l:font_decl
	call add(l:font_commands,substitute(
		    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'),
		    \ l:declare_command,'usefont',''))
    endfor
    return l:font_commands
endfunction
function! atplib#ShowFonts_py(fd_file)
python << END
import vim, re
file=vim.eval("a:fd_file")
try:
    file_o=open(file, "r")
    file_l=file_o.readlines()
    declare_pat=re.compile('(?:DeclareFontShape(?:WithSizes)?|sauter@(?:tt)?family|EC@(?:tt)?family|krntstexmplfamily|HFO@(?:tt)?family)')
    font_pat=re.compile('(\\\\(?:DeclareFontShape(?:WithSizes)?|sauter@(?:tt)?family|EC@(?:tt)?family|krntstexmplfamily|HFO@(?:tt)?family)\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*})')
    font_commands=[]
    for line in file_l:
        if re.search(declare_pat, line):
            font_cmd=re.search(font_pat, line)
            if font_cmd:
                font=font_cmd.group(0)
                font=re.sub(declare_pat, 'usefont', font)
                font_commands.append(font)
        vim.command("let s:return_ShowFonts_py="+str(font_commands))
except IOError:
    vim.command("let s:return_ShowFonts_py=[]")
END
return map(s:return_ShowFonts_py, "substitute(v:val, '^\\', '', '')")
endfunction
function! atplib#ShowFonts(fd_file)
    if has("python")
        return atplib#ShowFonts_py(a:fd_file)
    else
        return atplib#ShowFonts(a:fd_file)
    endif
endfunction
"}}}2
" }}}1
" vim:fdm=marker:ff=unix:noet:ts=8:sw=4:fdc=1
