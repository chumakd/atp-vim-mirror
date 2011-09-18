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
" vim:fdm=marker:ff=unix:noet:ts=8:sw=4:fdc=1
