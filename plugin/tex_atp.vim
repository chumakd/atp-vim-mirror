" Title:		Vim plugin file of Automatix LaTex Plugin
" Author:		Marcin Szamotulski
" Web Page:		http://atp-vim.sourceforge.net
" Mailing List: 	atp-vim-list [AT] lists.sourceforge.net

" Set options and maps for tex log file.
function! TexLogCurrentFile()
    let saved_pos = getpos(".")
    let savedview = winsaveview()
    call searchpair('(', '', ')', 'cbW')
    let file = matchstr(getline(".")[col("."):], '^\f*')
    if filereadable(file)
	call setpos(".", saved_pos)
	call winrestview(savedview) 
	return file
    else
	call searchpair('(', '', ')', 'bW')
	let file = matchstr(getline(".")[col("."):], '^\f*')
	call setpos(".", saved_pos)
	call winrestview(savedview) 
	call setpos(".", saved_pos)
	call winrestview(savedview) 
	if filereadable(file)
	    return file
	else
	    return ""
	endif
    endif
endfunction
function! <SID>TexLogSettings(fname)
    " This function should also have the SyncTex section of
    " atplib#various#OpenLog, but since it requires b:atp_ProjectDir and
    " possibly b:atp_MainFile variables, it is not yet done.
    if filereadable(fnamemodify(expand(a:fname), ":r").".tex")
	setl nomodifiable
	setl buftype=nowrite
	setl nospell
	setl syn=log_atp
	setl autoread
	setl autowriteall
	nnoremap <silent> <buffer> ]m :call atplib#various#Search('\CWarning\\|^!', 'W')<CR>
	nnoremap <silent> <buffer> [m :call atplib#various#Search('\CWarning\\|^!', 'bW')<CR>
	nnoremap <silent> <buffer> ]w :call atplib#various#Search('\CWarning', 'W')<CR>
	nnoremap <silent> <buffer> [w :call atplib#various#Search('\CWarning', 'bW')<CR>
	nnoremap <silent> <buffer> ]c :call atplib#various#Search('\CLaTeX Warning: Citation', 'W')<CR>
	nnoremap <silent> <buffer> [c :call atplib#various#Search('\CLaTeX Warning: Citation', 'bW')<CR>
	nnoremap <silent> <buffer> ]r :call atplib#various#Search('\CLaTeX Warning: Reference', 'W')<CR>
	nnoremap <silent> <buffer> [r :call atplib#various#Search('\CLaTeX Warning: Reference', 'bW')<CR>
	nnoremap <silent> <buffer> ]e :call atplib#various#Search('^!', 'W')<CR>
	nnoremap <silent> <buffer> [e :call atplib#various#Search('^!', 'bW')<CR>
	nnoremap <silent> <buffer> ]f :call atplib#various#Search('\CFont \%(Info\\|Warning\)', 'W')<CR>
	nnoremap <silent> <buffer> [f :call atplib#various#Search('\CFont \%(Info\\|Warning\)', 'bW')<CR>
	nnoremap <silent> <buffer> ]p :call atplib#various#Search('\CPackage', 'W')<CR>
	nnoremap <silent> <buffer> [p :call atplib#various#Search('\CPackage', 'bW')<CR>
	nnoremap <silent> <buffer> ]P :call atplib#various#Search('\[\_d\+\zs', 'W')<CR>
	nnoremap <silent> <buffer> [P :call atplib#various#Search('\[\_d\+\zs', 'bW')<CR>
	nnoremap <silent> <buffer> ]i :call atplib#various#Search('\CInfo', 'W')<CR>
	nnoremap <silent> <buffer> [i :call atplib#various#Search('\CInfo', 'bW')<CR>
	nnoremap <silent> <buffer> % :call atplib#various#Searchpair('(', '', ')', 'W')<CR>
 
	call atplib#ReadATPRC()
	if !exists("g:atp_LogStatusLine")
	    let g:atp_LogStatusLine = 1
	endif
	if g:atp_LogStatusLine
	    let atplog_StatusLine = '%<%f %(%h%m%r%) %#User6#%{TexLogCurrentFile()}%*%=  %-14.16(%l,%c%V%)%P'
	    let &statusline=atplog_StatusLine
	endif
	let b:atp_ProjectDir = expand("%:p:h")
	let b:atp_MainFile   = expand("%:p:r").".tex" 
	if !exists("g:atp_debugST")
	    let g:atp_debugST = 0
	endif
	if !exists("g:atp_LogSync")
	    let g:atp_LogSync = 0
	endif
	if !exists("b:atp_Viewer")
	    let b:atp_Viewer = "xpdf"
	endif
	if !exists("b:atp_XpdfServer")
	    let b:atp_XpdfServer = fnamemodify(b:atp_MainFile,":t:r")
	endif
	if !exists("g:atp_SyncXpdfLog")
	    let g:atp_SyncXpdfLog 	= 0
	endif
	if !exists("g:atp_TempDir")
	    call atplib#TempDir()
	endif
	if !exists("g:atp_tex_extensions")
	    let g:atp_tex_extensions	= ["tex.project.vim", "aux", "_aux", "log", "bbl", "blg", "bcf", "run.xml", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "ind", "ilg", "maf", "glo", "mtc[0-9]", "mtc1[0-9]", "pdfsync", "synctex.gz" ]
	endif
	if !exists("b:atp_OutDir")
	    let b:atp_OutDir = substitute(fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/", '\\\s', ' ' , 'g')
	endif
	if !exists("b:atp_TempDir")
	    let b:atp_TempDir = substitute(b:atp_OutDir . "/.tmp", '\/\/', '\/', 'g')
	endif
	command! -buffer -bang SyncTex	:call atplib#various#SyncTex(<q-bang>)
	nnoremap <buffer> <Enter>		:<C-U>SyncTex<CR>
	nnoremap <buffer> <LocalLeader>f	:<C-U>SyncTex<CR>	
	augroup ATP_SyncLog
	    au!
	    au CursorMoved *.log :call atplib#various#SyncTex("", 1)
	augroup END

	command! -buffer SyncXpdf 	:call atplib#various#SyncXpdfLog(0)
	command! -buffer Xpdf 	:call atplib#various#SyncXpdfLog(0)
	map <buffer> <silent> <F3> 	:<C-U>SyncXpdf<CR>
	augroup ATP_SyncXpdfLog
	    au CursorMoved *.log :call atplib#various#SyncXpdfLog(1)
	augroup END
    endif
endfunction
augroup ATP_texlog
    au!
    au BufEnter *.log call <SID>TexLogSettings(expand("<afile>:p"))
augroup END
