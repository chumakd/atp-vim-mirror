" Author:	Marcin Szmotulski
" Description:  This file contains mappings defined by ATP.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex
" Last Change:

" Commands to library functions (autoload/atplib.vim)

" <c-c> in insert mode doesn't trigger InsertLeave autocommands
" this fixes this.
if g:atp_MapCC
    imap <silent> <buffer> <c-c> <c-[>
endif

if has("gui")
    cmap <buffer> <C-Space> \_s\+
else
    cmap <buffer> <C-@> \_s\+
endif
cmap <buffer> <C-_> \_s\+

if g:atp_MapUpdateToCLine
    nmap <buffer> <silent> <C-F> <C-F>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-Down> <S-Down>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <PageDown> <PageDown>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> z+	z+:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-ScrollWheelUp> <S-ScrollWheelUp>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <C-ScrollWheelUp> <C-ScrollWheelUp>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <ScrollWheelUp> <ScrollWheelUp>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <C-U> <C-U>:call UpdateToCLine()<CR>
"     nmap <buffer> <silent> <C-E> <C-E>:call UpdateToCLine()<CR>

    nmap <buffer> <silent> <C-B> <C-B>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-ScrollWheelDown> <S-ScrollWheelDown>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <C-ScrollWheelDown> <C-ScrollWheelDown>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <ScrollWheelDown> <ScrollWheelDown>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-Up> <S-Up>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <PageUp> <PageUp>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <C-D> <C-D>:call UpdateToCLine()<CR>
"     nmap <buffer> <silent> <C-Y> <C-Y>:call UpdateToCLine()<CR>

    nmap <buffer> <silent> gj	gj:call UpdateToCLine(1)<CR>
    nmap <buffer> <silent> gk	gk:call UpdateToCLine(1)<CR>

    if maparg('j', 'n') == ''
	nmap <buffer> <silent> j	j:call UpdateToCLine(0)<CR>
    elseif maparg('j', 'n') == 'gj'
	nmap <buffer> <silent> j	gj:call UpdateToCLine(0)<CR>
    endif

    if maparg('k', 'n') == ''
	nmap <buffer> <silent> k	k:call UpdateToCLine(1)<CR>
    elseif maparg('j', 'n') == 'gj'
	nmap <buffer> <silent> k	gk:call UpdateToCLine(1)<CR>
    endif
endif


command! -buffer -bang -nargs=* FontSearch	:call atplib#FontSearch(<q-bang>, <f-args>)
command! -buffer -bang -nargs=* FontPreview	:call atplib#FontPreview(<q-bang>,<f-args>)
command! -buffer -nargs=1 -complete=customlist,atplib#Fd_completion OpenFdFile	:call atplib#OpenFdFile(<f-args>) 
command! -buffer -nargs=* CloseLastEnvironment	:call atplib#CloseLastEnvironment(<f-args>)
command! -buffer 	  CloseLastBracket	:call atplib#CloseLastBracket()
" let g:atp_map_list	= [ 
" 	    \ [ g:atp_map_forward_motion_leader, 'i', 		':NInput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_backward_motion_leader, 'i', 		':NPnput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_forward_motion_leader, 'gf', 		':NInput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_backward_motion_leader, 'gf',		':NPnput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_forward_motion_leader, 'S', 		'<Plug>GotoNextSubSection',	'nmap <buffer>' ],
" 	    \ [ g:atp_map_backward_motion_leader, 'S', 		'<Plug>vGotoNextSubSection', 	'nmap <buffer>' ],
" 	    \ ] 



" MAPS:
" Add maps, unless the user didn't want them.
if ( !exists("g:no_plugin_maps") || exists("g:no_plugin_maps") && g:no_plugin_maps == 0 ) && 
	    \ ( !exists("g:no_atp_maps") || exists("g:no_plugin_maps") && g:no_atp_maps == 0 ) 

" They are interfering with vim GG.
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."S		:<C-U>keepjumps exe v:count1.\"SSec\"<CR>"
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."s		:<C-U>keepjumps exe v:count1.\"Sec\"<CR>"
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."c		:<C-U>keepjumps exe v:count1.\"Chap\"<CR>"
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."p		:<C-U>keepjumps exe v:count1.\"Part\"<CR>"

if g:atp_MapCommentLines    
    nmap <buffer> <silent> <LocalLeader>c	<Plug>CommentLines
    vmap <buffer> <silent> <LocalLeader>c	<Plug>CommentLines
    nmap <buffer> <silent> <LocalLeader>u	<Plug>UnCommentLines
    vmap <buffer> <silent> <LocalLeader>u	<Plug>UnCommentLines
endif

nmap <buffer> <silent> t 		<Plug>SyncTexKeyStroke
nmap <buffer> <silent> <S-LeftMouse> 	<LeftMouse><Plug>SyncTexMouse

nmap <buffer> <silent> ]*	:SkipCommentForward<CR> 
omap <buffer> <silent> ]*	:SkipCommentForward<CR> 
nmap <buffer> <silent> gc	:SkipCommentForward<CR>
omap <buffer> <silent> gc	:SkipCommentForward<CR>

vmap <buffer> <silent> ]*	<Plug>SkipCommentForward
vmap <buffer> <silent> gc	<Plug>SkipCommentForward
vmap <buffer> <silent> gC	<Plug>SkipCommentBackward
vmap <buffer> <silent> [*	<Plug>SkipCommentBackward

nmap <buffer> <silent> [*	:SkipCommentBackward<CR> 
omap <buffer> <silent> [*	:SkipCommentBackward<CR> 
nmap <buffer> <silent> gC	:SkipCommentBackward<CR>
omap <buffer> <silent> gC	:SkipCommentBackward<CR>

execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."i				:NInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."i				:PInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."gf				:NInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."gf				:PInput<CR>"

" Syntax motions:
" imap <C-j> <Plug>TexSyntaxMotionForward
" imap <C-k> <Plug>TexSyntaxMotionBackward
" nmap <C-j> <Plug>TexSyntaxMotionForward
" nmap <C-k> <Plug>TexSyntaxMotionBackward

imap <C-j> <Plug>TexJMotionForward
imap <C-k> <Plug>TexJMotionBackward
nmap <C-j> <Plug>TexJMotionForward
nmap <C-k> <Plug>TexJMotionBackward

    if g:atp_map_forward_motion_leader == "}"
	noremap <silent> <buffer> }} }
    endif
    if g:atp_map_backward_motion_leader == "{"
	noremap <silent> <buffer> {{ {
    endif

    " ToDo to doc. + vmaps!
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."S 	<Plug>GotoNextSubSection"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."S		<Plug>vGotoNextSubSection"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>GotoPreviousSubSection"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>vGotoPreviousSubSection"
    " Toggle this maps on/off!
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."s 	<Plug>GotoNextSection"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."s		<Plug>vGotoNextSection"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."s 	<Plug>GotoPreviousSection"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."s 	<Plug>vGotoPreviousSection"
    if !( g:atp_map_forward_motion_leader == "]" && &l:diff )
	execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."c 	<Plug>GotoNextChapter"
	execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."c 	<Plug>vGotoNextChapter"
    endif
    if !( g:atp_map_backward_motion_leader == "]" && &l:diff )
	execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."c 	<Plug>GotoPreviousChapter"
	execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."c 	<Plug>vGotoPreviousChapter"
    endif
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."p 	<Plug>GotoNextPart"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."p 	<Plug>vGotoNextPart"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."p 	<Plug>GotoPreviousPart"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."p 	<Plug>vGotoPreviousPart"

    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."e		<Plug>GotoNextEnvironment"
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."E		<Plug>JumptoNextEnvironment"
"     map <silent> <buffer> <C-F> <Plug>GotoNextEnvironment
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."e	<Plug>GotoPreviousEnvironment"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."E 	<Plug>JumptoPreviousEnvironment"
"     map <silent> <buffer> <C-B> <Plug>GotoPreviousEnvironment
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."m		<Plug>GotoNextMath"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."m	<Plug>GotoPreviousMath"
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."M		<Plug>GotoNextDisplayedMath"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."M	<Plug>GotoPreviousDisplayedMath"

    " Goto File Map:
    if has("path_extra")
	nnoremap <buffer> <silent> gf		:call GotoFile("", "")<CR>
    endif

    if exists("g:atp_no_tab_map") && g:atp_no_tab_map == 1
	imap <silent> <buffer> <F7> 		<C-R>=atplib#TabCompletion(1)<CR>
	nnoremap <silent> <buffer> <F7>		:call atplib#TabCompletion(1,1)<CR>
	imap <silent> <buffer> <S-F7> 		<C-R>=atplib#TabCompletion(0)<CR>
	nnoremap <silent> <buffer> <S-F7>	:call atplib#TabCompletion(0,1)<CR> 
    else 
	" the default:
	imap <silent> <buffer> <Tab> 		<C-R>=atplib#TabCompletion(1)<CR>
	imap <silent> <buffer> <S-Tab> 		<C-R>=atplib#TabCompletion(0)<CR>
	" HOW TO: do this with <tab>? Streightforward solution interacts with
	" other maps (e.g. after \l this map is called).
	" when this is set it also runs after the \l map: ?!?
" 	nmap <silent> <buffer> <Tab>		:call atplib#TabCompletion(1,1)<CR>
	nnoremap <silent> <buffer> <S-Tab>	:call atplib#TabCompletion(0,1)<CR> 
	vnoremap <buffer> <silent> <F7> 	:WrapSelection \{ } begin<CR>
    endif

    " Fonts:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."f		:WrapSelection {\\usefont{".g:atp_font_encoding."}{}{}{}\\selectfont\\  } ".(len(g:atp_font_encoding)+11)."<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."mb	:WrapSelection \\mbox{ } begin<CR>"


    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."te	:<C-U>InteligentWrapSelection ['\\textrm{'],['\\text{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."rm	:<C-U>InteligentWrapSelection ['\\textrm{'],['\\mathrm{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."em	:<C-U>InteligentWrapSelection ['\\emph{'],['\\mathit{']<CR>"
"   Suggested Maps:
"     execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."tx	:<C-U>InteligentWrapSelection [''],['\\text{']<CR>"
"     execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."in	:<C-U>InteligentWrapSelection [''],['\\intertext{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."it	:<C-U>InteligentWrapSelection ['\\textit{'],['\\mathit{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."sf	:<C-U>InteligentWrapSelection ['\\textsf{'],['\\mathsf{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."tt	:<C-U>InteligentWrapSelection ['\\texttt{'],['\\mathtt{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."bf	:<C-U>InteligentWrapSelection ['\\textbf{'],['\\mathbf{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."bb	:<C-U>InteligentWrapSelection ['\\textbf{'],['\\mathbb{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."sl	:<C-U>WrapSelection \\textsl{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."sc	:<C-U>WrapSelection \\textsc{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."up	:<C-U>WrapSelection \\textup{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."md	:<C-U>WrapSelection \\textmd{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."un	:<C-U>WrapSelection \\underline{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."ov	:<C-U>WrapSelection \\overline{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."no	:<C-U>InteligentWrapSelection ['\\textnormal{'],['\\mathnormal{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."cal	:<C-U>InteligentWrapSelection [''],['\\mathcal{']<CR>"

    " Environments:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."C   :WrapSelection \\begin{center} \\end{center} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."R   :WrapSelection \\begin{flushright} \\end{flushright} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."L   :WrapSelection \\begin{flushleft} \\end{flushleft} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."E   :WrapSelection \\begin{equation=b:atp_StarMathEnvDefault<CR>} \\end{equation=b:atp_StarMathEnvDefault<CR>} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."A   :WrapSelection \\begin{align=b:atp_StarMathEnvDefault<CR>} \\end{align=b:atp_StarMathEnvDefault<CR>} 0 1<CR>"

    " Math Modes:
    vmap <silent> <buffer> m				:<C-U>WrapSelection \( \)<CR>
    vmap <silent> <buffer> M				:<C-U>WrapSelection \[ \]<CR>

    " Brackets:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."( 	:WrapSelection ( ) begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."[ 	:WrapSelection [ ] begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."\\{	:WrapSelection \\{ \\} begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."{ 	:WrapSelection { } begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."< 	:WrapSelection < > begin<CR>"
"     execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."{	:<C-U>InteligentWrapSelection ['{', '}'],['\\{', '\\}']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader.")	:WrapSelection ( ) end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."]	:WrapSelection [ ] end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."\\}	:WrapSelection \\{ \\} end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."}	:WrapSelection { } end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."> 	:WrapSelection < > end<CR>"

    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."(	:WrapSelection \\left( \\right) begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."[	:WrapSelection \\left[ \\right] begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."{	:WrapSelection \\left\\{ \\right\\} begin<CR>"
    " for compatibility:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."\\{	:WrapSelection \\left\\{ \\right\\} begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader.")	:WrapSelection \\left( \\right) end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."]	:WrapSelection \\left[ \\right] end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."}	:WrapSelection \\left\\{ \\right\\} end<CR>"
    " for compatibility:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."\\}	:WrapSelection \\left\\{ \\right\\} end<CR>"

    " Tex Align:
    nmap <silent> <buffer> <Localleader>a	:TexAlign<CR>
    " Paragraph Selecting:
    vmap <silent> <buffer> ip 	<Plug>ATP_SelectCurrentParagraphInner
    vmap <silent> <buffer> ap 	<Plug>ATP_SelectCurrentParagraphOuter
    omap <silent> <buffer>  ip	:normal vip<CR>
    omap <silent> <buffer>  ap	:normal vap<CR>

    " Formating:
    nmap <silent> <buffer> gw		m`vipgq``
    " Indent:
    nmap <silent> <buffer> g>		m`vip>``
    nmap <silent> <buffer> g<		m`vip<``
    nmap <silent> <buffer> 2g>		m`vip2>``
    nmap <silent> <buffer> 2g<		m`vip2<``
    nmap <silent> <buffer> 3g>		m`vip3>``
    nmap <silent> <buffer> 3g<		m`vip3<``
    nmap <silent> <buffer> 4g>		m`vip4>``
    nmap <silent> <buffer> 4g<		m`vip4<``
    nmap <silent> <buffer> 5g>		m`vip5>``
    nmap <silent> <buffer> 5g<		m`vip5<``
    nmap <silent> <buffer> 6g>		m`vip6>``
    nmap <silent> <buffer> 6g<		m`vip6<``

    vmap <buffer> <silent> aS		<Plug>SelectOuterSyntax
    vmap <buffer> <silent> iS		<Plug>SelectInnerSyntax

    " From vim.vim plugin (by Bram Mooleaner)
    " Move around functions.
    nnoremap <silent> <buffer> [[ m':call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "bW")<CR>
    vnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "bW")<CR>
    nnoremap <silent> <buffer> ]] m':call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "W")<CR>
    vnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "W")<CR>
    nnoremap <silent> <buffer> [] m':call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "bW")<CR>
    vnoremap <silent> <buffer> [] m':<C-U>exe "normal! gv"<Bar>call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "bW")<CR>
    nnoremap <silent> <buffer> ][ m':call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "W")<CR>
    vnoremap <silent> <buffer> ][ m':<C-U>exe "normal! gv"<Bar>call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "W")<CR>

    " Move around comments
    nnoremap <silent> <buffer> ]% :call search('^\(\s*%.*\n\)\@<!\(\s*%\)', "W")<CR>
    vnoremap <silent> <buffer> ]% :<C-U>exe "normal! gv"<Bar>call search('^\(\s*%.*\n\)\@<!\(\s*%\)', "W")<CR>
    nnoremap <silent> <buffer> [% :call search('\%(^\s*%.*\n\)\%(^\s*%\)\@!', "bW")<CR>
    vnoremap <silent> <buffer> [% :<C-U>exe "normal! gv"<Bar>call search('\%(^\s*%.*\n\)\%(^\s*%\)\@!', "bW")<CR>

    " Select comment
"     exe "vmap <silent> <buffer> ".g:atp_MapSelectComment." <Plug>vSelectComment"
    exe "map <silent> <buffer> ".g:atp_MapSelectComment." v<Plug>vSelectComment"

    " Normal mode maps (mostly)
    if mapcheck('<LocalLeader>v') == ""
	nmap  <silent> <buffer> <LocalLeader>v		<Plug>ATP_ViewOutput
    endif
"     nmap  <silent> <buffer> <F2> 			<Plug>ToggleSpace
    nmap  <silent> <buffer> <F2> 			q/:call ATP_CmdwinToggleSpace('on')<CR>i
    if mapcheck('Q/', 'n') == ""
	nmap <silent> <buffer> Q/					q/:call ATP_CmdwinToggleSpace('on')<CR>
    endif
    if mapcheck('Q?', 'n') == ""
	nmap <silent> <buffer> Q?					q?:call ATP_CmdwinToggleSpace('on')<CR>
    endif
    if mapcheck('<LocalLeader>s') == ""
	nmap  <silent> <buffer> <LocalLeader>s		<Plug>ToggleStar
    endif

    nmap  <silent> <buffer> <LocalLeader><Localleader>d	<Plug>ToggledebugMode
    nmap  <silent> <buffer> <LocalLeader><Localleader>D	<Plug>ToggleDebugMode
    vmap  <silent> <buffer> <F4>				<Plug>WrapEnvironment
    nmap  <silent> <buffer> <F4>				<Plug>ChangeEnv
    nmap  <silent> <buffer> <S-F4>			<Plug>ToggleEnvForward
"     nmap  <silent> <buffer> <S-F4>			<Plug>ToggleEnvBackward
    nmap  <silent> <buffer> <C-S-F4>			<Plug>LatexEnvPrompt
"     ToDo:
"     if g:atp_LatexBox
" 	nmap <silent> <buffer> <F3>			:call <Sid>ChangeEnv()<CR>
"     endif
    nmap  <silent> <buffer> <F3>        		<Plug>ATP_ViewOutput
    imap  <silent> <buffer> <F3> 			<Esc><Plug>ATP_ViewOutput
    nmap  <silent> <buffer> <LocalLeader>g 		<Plug>Getpid
    nmap  <silent> <buffer> <LocalLeader>t		<Plug>ATP_TOC
    nmap  <silent> <buffer> <LocalLeader>L		<Plug>ATP_Labels
    nmap  <silent> <buffer> <LocalLeader>l 		<Plug>ATP_TeXCurrent
    nmap  <silent> <buffer> <LocalLeader>d 		<Plug>ATP_TeXdebug
    nmap  <silent> <buffer> <LocalLeader>D 		<Plug>ATP_TeXDebug
"     nmap           <buffer> <c-l>			<Plug>ATP_MakeLatex
    "ToDo: imaps!
    nmap  <silent> <buffer> <F5> 			<Plug>ATP_TeXVerbose
    nmap  <silent> <buffer> <s-F5> 			<Plug>ToggleAuTeX
    imap  <silent> <buffer> <s-F5> 			<Esc><Plug>ToggleAuTeXa
    nmap  <silent> <buffer> `<Tab>			<Plug>ToggleTab
    imap  <silent> <buffer> `<Tab>			<Plug>ToggleTab
    nmap  <silent> <buffer> <LocalLeader>B		<Plug>SimpleBibtex
    nmap  <silent> <buffer> <LocalLeader>b		<Plug>BibtexDefault
    nmap  <silent> <buffer> <F6>d 			<Plug>Delete
    imap  <silent> <buffer> <F6>d			<Esc><Plug>Delete
    nmap  <silent> <buffer> <F6>l 		<Plug>OpenLog
    imap  <silent> <buffer> <F6>l 		<Esc><Plug>OpenLog
    nnoremap  <silent> <buffer> <F6> 			:ShowErrors e<CR>
    inoremap  <silent> <buffer> <F6> 			:ShowErrors e<CR>
    noremap   <silent> <buffer> <LocalLeader>e		:ShowErrors<CR>
    nnoremap  <silent> <buffer> <F6>e 			:ShowErrors e<CR>
    inoremap  <silent> <buffer> <F6>e 			:ShowErrors e<CR>
    nnoremap  <silent> <buffer> <F6>w 			:ShowErrors w<CR>
    inoremap  <silent> <buffer> <F6>w 			:ShowErrors w<CR>
    nnoremap  <silent> <buffer> <F6>r 			:ShowErrors rc<CR>
    inoremap  <silent> <buffer> <F6>r 			:ShowErrors rc<CR>
    nnoremap  <silent> <buffer> <F6>f 			:ShowErrors f<CR>
    inoremap  <silent> <buffer> <F6>f 			:ShowErrors f<CR>
    nnoremap  <silent> <buffer> <F6>g 			<Plug>PdfFonts
    nnoremap           <buffer> <F1>			:TexDoc<space>
    inoremap           <buffer> <F1> <esc> 		:TexDoc<space>

    " FONT MAPPINGS
    if g:atp_imap_first_leader == "]" || g:atp_imap_second_leader == "]" || g:atp_imap_third_leader == "]" || g:atp_imap_fourth_leader == "]" 
	inoremap <silent> <buffer> ]] ]
    endif
"     execute 'imap <silent> <buffer> '.g:atp_imap_second_leader.'rm \textrm{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'rm <Esc>:call Insert("\\textrm{", "\\mathrm{")<CR>a'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'up \textup{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'md \textmd{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'it \textit{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'it <Esc>:call Insert("\\textit{", "\\mathit{")<CR>a'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sl \textsl{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sc \textsc{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sf \textsf{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sf <Esc>:call Insert("\\textsf{", "\\mathsf{")<CR>a'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'bf \textbf{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'bf <Esc>:call Insert("\\textbf{", "\\mathbf{")<CR>a'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'tt \texttt{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'tt <Esc>:call Insert("\\texttt{", "\\mathtt{")<CR>a'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'em \emph{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'no <Esc>:call Insert("\\textnormal{", "\\mathnormal{")<Cr>a'
	    
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mit \mathit{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mrm \mathrm{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'msf \mathsf{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mbf \mathbf{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'bb \mathbb{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mtt \mathtt{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'cal \mathcal{}<Left>'

    " GREEK LETTERS
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'a \alpha'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'b \beta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'c \chi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'d \delta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'e \epsilon'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'ve \varepsilon'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'f \phi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'y \psi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'g \gamma'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'h \eta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'k \kappa'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'l \lambda'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'i \iota'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'m \mu'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'n \nu'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'p \pi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'o \theta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'r \rho'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'s \sigma'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'t \tau'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'u \upsilon'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'vs \varsigma'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'vo \vartheta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'w \omega'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'x \xi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'z \zeta'

    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'D \Delta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'Y \Psi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'F \Phi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'G \Gamma'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'L \Lambda'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'M \Mu'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'P \Pi'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'O \Theta'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'S \Sigma'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'T \Tau'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'U \Upsilon'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'W \Omega'
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'Z \mathrm{Z}'  

    let leader = (g:atp_imap_first_leader == '#' ? '<LocalLeader>' : g:atp_imap_first_leader ) 
    execute 'inoremap <silent> <buffer> '.leader.'8 \infty'  
    execute 'inoremap <silent> <buffer> '.leader.'6 \partial' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'& \wedge'  
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'ve \vee'  
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'V \Vee'  
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'+ \bigcup' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'- \bigcap' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'\ \setminus' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'N \Nabla' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'@ \circ' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'= \equiv' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'> \geq' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'< \leq' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'~ \=(g:atp_imap_wide ? "wide" : "")<CR>tilde{}<Left>' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'^ \=(g:atp_imap_wide ? "wide" : "" )<CR>hat{}<Left>' 
"     execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'_ \bar{}<Left>' 
    execute 'inoremap <silent> <buffer> '.g:atp_imap_first_leader.'. \dot' 
    execute 'inoremap <buffer> '.g:atp_imap_first_leader.'/ \frac{}{}<Esc>F}i'

if g:atp_no_env_maps != 1
    if g:atp_env_maps_old == 1
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_begin.' \begin{}<Left>'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_end.' \end{}<Left>'

execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_abstract.' \begin{abstract}<CR>\end{abstract}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.g:atp_imap_corollary.' \begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_definition.' \begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.g:atp_imap_enumerate.' \begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_align.' \begin{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O'
" Clash: \item and {itemize} 
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_item.' \item'
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.'i \begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_lemma.' \begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
" Clash: proof and propostion 
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.g:atp_imap_proof.' \begin{proof}<CR>\end{proof}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_proposition.' \begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_theorem.' \begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.g:atp_imap_tikzpicture.' \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'

	if g:atp_extra_env_maps == 1
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_remark.' \begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.g:atp_imap_flushleft.' \begin{flushleft}<CR>\end{flushleft}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_flushright.' \begin{flushright}<CR>\end{flushright}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_frame.' \begin{frame}<CR>\end{frame}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_fourth_leader.g:atp_imap_equation.' \begin{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_note.' \begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_observation.' \begin{=g:atp_EnvNameObservation<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameObservation<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_example.' \begin{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
	endif
    else
    " New mapping for the insert mode. 
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_begin.' \begin{}<Left>'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_end.' \end{}<Left>'


execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_abstract.' \begin{abstract}<CR>\end{abstract}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_theorem.' \begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_definition.' \begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
" Clash: proof and propostion 
execute 'inoremap <silent> <buffer>  '.g:atp_imap_third_leader.g:atp_imap_proposition.' \begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_lemma.' \begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_remark.' \begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_corollary.' \begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
" Clash: proof and propostion 
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_proof.' \begin{proof}<CR>\end{proof}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_example.' \begin{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_note.' \begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'

execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_enumerate.' \begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item'
" Clash: \item and itemize
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_itemize.' \begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item'
" Clash: \item and itemize
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_item.' <Esc>:call InsertItem()<CR>a'


execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_align.' \begin{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_equation.' \begin{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'

execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_center.' \begin{center}<CR>\end{center}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_flushleft.' \begin{flushleft}<CR>\end{flushleft}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_flushright.' \begin{flushright}<CR>\end{flushright}<Esc>O'

execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_bibliography.' \begin{thebibliography}<CR>\end{thebibliography}<Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_tikzpicture.' \begin{center}<CR>\begin{tikzpicture}<CR>\end{tikzpicture}<CR>\end{center}<Up><Esc>O'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_letter.' \begin{letter}{}<CR>\opening{'.g:atp_letter_opening.'}<CR>\closing{'.g:atp_letter_closing.'}<CR>\end{letter}<Up><Esc>?\\begin{letter}{\zs<CR>i'
execute 'inoremap <silent> <buffer> '.g:atp_imap_third_leader.g:atp_imap_frame.' \begin{frame}<CR>\end{frame}<Esc>O'
endif

	" imap }c \begin{corollary*}<CR>\end{corollary*}<Esc>O
	" imap }d \begin{definition*}<CR>\end{definition*}<Esc>O
	" imap }x \begin{example*}\normalfont<CR>\end{example*}<Esc>O
	" imap }l \begin{lemma*}<CR>\end{lemma*}<Esc>O
	" imap }n \begin{note*}<CR>\end{note*}<Esc>O
	" imap }o \begin{observation*}<CR>\end{observation*}<Esc>O
	" imap }p \begin{proposition*}<CR>\end{proposition*}<Esc>O
	" imap }r \begin{remark*}<CR>\end{remark*}<Esc>O
	" imap }t \begin{theorem*}<CR>\end{theorem*}<Esc>O

    endif

    function! <SID>IsLeft(lchar,...)
	let nr = ( a:0 >= 1 ? a:1 : 0 )
	" From TeX_nine plugin
	    let left = getline('.')[col('.')-2-nr]
	    if left == a:lchar
		return 1
	    else
		return 0
	    endif
    endfunction

    " This makes a diference only if 'timeout' is set.
    if !mapcheck('_', 'i') && !mapcheck('^', 'i')
	inoremap <buffer> <expr> _ <SID>IsLeft('_') && 
		    \ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		    \ !atplib#CheckSyntaxGroups(['texMathText']) ? '{}<Left>' : '_'
	inoremap <buffer> <expr> ^ <SID>IsLeft('^') && 
		    \ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		    \ !atplib#CheckSyntaxGroups(['texMathText']) ? '{}<Left>' : '^'
    else
	inoremap <buffer> <expr> <silent> __ ( atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		    \ !atplib#CheckSyntaxGroups(['texMathText']) ?  '_{}<Left>' : '' )
	inoremap <buffer> <expr> <silent> ^^ ( atplib#CheckSyntaxGroups(g:atp_MathZones) ?  '^{}<Left>' : '' )
    endif

    inoremap <buffer> <expr> = <SID>IsLeft('=') && !<SID>IsLeft('&', 1) &&
		\ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		\ !atplib#CheckSyntaxGroups(['texMathText']) ? '<BS>&=' : '='
    inoremap <buffer> <expr> ~ <SID>IsLeft('~') && 
		\ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		\ !atplib#CheckSyntaxGroups(['texMathText']) ? '<BS>\approx' : '~'

    inoremap <buffer> <expr> + <SID>IsLeft('o') && 
		\ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		\ !atplib#CheckSyntaxGroups(['texMathText']) ? '<BS>\oplus' : '+'
    inoremap <buffer> <expr> - <SID>IsLeft('o') && 
		\ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		\ !atplib#CheckSyntaxGroups(['texMathText']) ? '<BS>\ominus' : '-'
    inoremap <buffer> <expr> . <SID>IsLeft('o') && 
		\ atplib#CheckSyntaxGroups(g:atp_MathZones) && 
		\ !atplib#CheckSyntaxGroups(['texMathText']) ? '<BS>\otimes' : '.'

    execute "imap <silent> <buffer> ".g:atp_imap_third_leader."m \\(\\)<Left><Left>"
    execute "imap <silent> <buffer> ".g:atp_imap_third_leader."M \\[\\]<Left><Left>"
endif

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
