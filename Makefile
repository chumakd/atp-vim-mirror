PLUGIN 	= AutomaticTexPlugin
VERSION = _8.7.1

SOURCE = ftplugin/ATP_files/LatexBox_common.vim
SOURCE += ftplugin/ATP_files/LatexBox_complete.vim
SOURCE += ftplugin/ATP_files/LatexBox_indent.vim
SOURCE += ftplugin/ATP_files/LatexBox_mappings.vim
SOURCE += ftplugin/ATP_files/LatexBox_motion.vim
SOURCE += ftplugin/ATP_files/LatexBox_latexmk.vim
SOURCE += ftplugin/ATP_files/project.vim
SOURCE += ftplugin/ATP_files/common.vim
SOURCE += ftplugin/ATP_files/compiler.vim
SOURCE += ftplugin/ATP_files/mappings.vim
SOURCE += ftplugin/ATP_files/abbreviations.vim
SOURCE += ftplugin/ATP_files/menu.vim
SOURCE += ftplugin/ATP_files/motion.vim
SOURCE += ftplugin/ATP_files/options.vim
SOURCE += ftplugin/ATP_files/search.vim
SOURCE += ftplugin/ATP_files/various.vim
SOURCE += ftplugin/ATP_files/helpfunctions.vim
SOURCE += ftplugin/ATP_files/vimcomplete.bst
SOURCE += ftplugin/bibsearch_atp.vim
SOURCE += ftplugin/fd_atp.vim
SOURCE += ftplugin/plaintex_atp.vim
SOURCE += ftplugin/tex_atp.vim
SOURCE += ftplugin/bib_atp.vim
SOURCE += ftplugin/toc_atp.vim
SOURCE += autoload/atplib.vim
SOURCE += doc/automatic-tex-plugin.txt
SOURCE += doc/bibtex_atp.txt
SOURCE += doc/latexhelp.txt
SOURCE += syntax/bibsearch_atp.vim
SOURCE += syntax/labels_atp.vim
SOURCE += syntax/log_atp.vim
SOURCE += syntax/toc_atp.vim
SOURCE += colors/coots-beauty-256.vim

${Plugin}_${VERSION}.vba: ${SOURCE}
		tar -czf ${PLUGIN}${VERSION}.tar.gz ${SOURCE}
		vim -nX --cmd 'let g:plugin_name = "${PLUGIN}${VERSION}"' -S build.vim -cq!

install:
		rsync -Rv ${SOURCE} ${HOME}/.vim/

clean:		
		rm ${PLUGIN}${VERSION}.vba ${PLUGIN}${VERSION}.tar.gz

test:
		tar -tzf ${PLUGIN}${VERSION}.tar.gz
