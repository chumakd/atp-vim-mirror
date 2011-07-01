PLUGIN 	= AutomaticTexPlugin
VERSION = 9.6.8
DATE	= $(shell date '+%d-%m-%y_%H-%M')

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
SOURCE += ftplugin/ATP_files/atp_RevSearch.py
SOURCE += ftplugin/ATP_files/compile.py
SOURCE += ftplugin/ATP_files/makelatex.py
SOURCE += ftplugin/ATP_files/latextags.py
SOURCE += ftplugin/ATP_files/url_query.py
SOURCE += ftplugin/ATP_files/dictionaries/dictionary
SOURCE += ftplugin/ATP_files/dictionaries/ams_dictionary
SOURCE += ftplugin/ATP_files/dictionaries/greek
SOURCE += ftplugin/ATP_files/dictionaries/SIunits
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
		python stamp.py ${DATE}
		python version.py ${VERSION}
		tar -czf ${PLUGIN}_${VERSION}.tar.gz ${SOURCE}
		vim -nX --cmd 'let g:plugin_name = "${PLUGIN}_${VERSION}"' -S build.vim -cq!

install:
		rsync -Rv ${SOURCE} ${HOME}/.vim/
		vim --cmd :helptags\ ${HOME}/.vim/doc --cmd q!

clean:		
		rm ${PLUGIN}_[0-9.]*.*
		rm msg

test:
		tar -tzf ${PLUGIN}${VERSION}.tar.gz
upload:		
	cp ${PLUGIN}_${VERSION}.vba ${PLUGIN}_${VERSION}.vba.${DATE}
	cp ${PLUGIN}_${VERSION}.tar.gz ${PLUGIN}_${VERSION}.tar.gz.${DATE}
	scp ${PLUGIN}_${VERSION}.vba.${DATE} ${PLUGIN}_${VERSION}.tar.gz.${DATE} mszamotulski,atp-vim@frs.sourceforge.net:/home/frs/project/a/at/atp-vim/snapshots/
release:		
	# upload snaphot and release (this is important for UploadATP command)
	cp ${PLUGIN}_${VERSION}.vba ${PLUGIN}_${VERSION}.vba.${DATE}
	cp ${PLUGIN}_${VERSION}.tar.gz ${PLUGIN}_${VERSION}.tar.gz.${DATE}
	scp ${PLUGIN}_${VERSION}.vba.${DATE} ${PLUGIN}_${VERSION}.tar.gz.${DATE} mszamotulski,atp-vim@frs.sourceforge.net:/home/frs/project/a/at/atp-vim/snapshots/
	scp ${PLUGIN}_${VERSION}.vba ${PLUGIN}_${VERSION}.tar.gz mszamotulski,atp-vim@frs.sourceforge.net:/home/frs/project/a/at/atp-vim/releases/
