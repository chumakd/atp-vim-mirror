#!/usr/bin/python

import sys, os.path, shutil, subprocess, re, psutil, tempfile, optparse 
from os import chdir, readlink, mkdir
from optparse import OptionParser
# from tempfile import mkdtemp

####################################
#
# 	Parse Options:   
#
####################################

usage	= "usage: %prog [options]"
parser 	= OptionParser(usage=usage)
parser.add_option("-c", "--command", dest="command", default="pdflatex", help="tex compiler")
parser.add_option("--tex-options", dest="tex_options", default="-synctex=1,-interaction=nonstopmode", help="comma separeted list of tex options")
parser.add_option("--verbose", dest="verbose", help="atp verbose mode: silent/debug/verbose", default="silent")
parser.add_option("-f", "--file", dest="mainfile", help="full path to file to compile")
parser.add_option("-o", "--output-format", dest="output_format", help="format od the output file: dvi or pdf (it is not checked consistency with --command", default="pdf")
parser.add_option("-r", "--runs", dest="runs", help="how many times run tex consecutively", type="int", default=1 )
parser.add_option("--servername", dest="servername", help="vim server to communicate with")
parser.add_option("-v", "--view", "--start", dest="start", help="start viewer: values 0,1,2", default=0, type="int")
parser.add_option("--viewer", dest="viewer", help="output viewer to use", default="xpdf")
parser.add_option("--xpdf-server", dest="xpdf_server", help="xpdf_server")
parser.add_option("--viewer-options", dest="viewer_opt", help="comma separated list of viewer options", default="")
parser.add_option("-k", "--keep", dest="keep", help="comma separated list of extensions (see :help g:keep in vim)", default="pdf,dvi,log,aux,toc,bbl,ind,pdfsync,synctex.gz") 
# Boolean switches:
parser.add_option("--reload-viewer", action="store_false", default=True, dest="reload_viewer")
parser.add_option("-b", "--bibtex", action="store_false", default=False, dest="bibtex", help="run bibtex")
parser.add_option("--reload-on-error", action="store_true", default=False, dest="reload_on_error", help="reload Xpdf if compilation had errors")
parser.add_option("--bang", action="store_false", default=False, dest="bang", help="force reloading on error (Xpdf only)")
parser.add_option("--gui-running", "-g", action="store_true", default=False, dest="gui_running", help="if vim gui is running (has('gui_running'))") 
(options, args) = parser.parse_args()
# parser.add_option("--reload-viewer", action="store_false", default=True, dest="reload_viewer", help="reload the viewer; some viewers do not need reloading, like Okular.") 

debug_file	= open("/tmp/atp_compile.py.debug", 'w+')

command		= options.command
command_opt	= options.tex_options.split(',')
# command_opt=[ "-synctex="+str(options.synctex), "-interaction="+options.interaction ]
mainfile_fp	= options.mainfile
if options.output_format == "pdf":
	extension = ".pdf"
else:
	extension = ".dvi"
runs		= options.runs
servername	= options.servername
start		= options.start
viewer		= options.viewer
XpdfServer	= options.xpdf_server
viewer_rawopt	= options.viewer_opt.split(',')
def nonempty(string):
	debug_file.write(str(string)+"\n")
	if str(string) == '':
		return False
	else:
		return True
viewer_it	=filter(nonempty,viewer_rawopt)
viewer_opt	=[]
for opt in viewer_it:
	viewer_opt.append(opt)
viewer_rawopt	= viewer_opt
if viewer == "xpdf" and XpdfServer != None:
	viewer_opt.extend(["-remote", XpdfServer])
verbose		= options.verbose
keep		= options.keep.split(',')
# Boolean options
reload_viewer	= options.reload_viewer
bibtex		= options.bibtex
bang		= options.bang
reload_on_error	= options.reload_on_error
gui_running	= options.gui_running

debug_file.write("COMMAND "+command+"\n")
debug_file.write("COMMAND_OPT "+str(command_opt)+"\n")
debug_file.write("MAINFILE_FP "+str(mainfile_fp)+"\n")
debug_file.write("EXT "+extension+"\n")
debug_file.write("RUNS "+str(runs)+"\n")
debug_file.write("VIM_SERVERNAME "+str(servername)+"\n")
debug_file.write("START "+str(start)+"\n")
debug_file.write("VIEWER "+str(viewer)+"\n")
debug_file.write("XPDF_SERVER "+str(XpdfServer)+"\n")
debug_file.write("VIEWER_OPT "+str(viewer_opt)+"\n")
debug_file.write("VERBOSE "+str(verbose)+"\n")
debug_file.write("KEEP "+str(keep)+"\n")
debug_file.write("*BIBTEX "+str(bibtex)+"\n")
debug_file.write("*BANG "+str(bang)+"\n")
debug_file.write("*RELOAD_ON_ERROR "+str(reload_on_error)+"\n")
debug_file.write("*GUI_RUNNING "+str(gui_running)+"\n")
debug_file.write("*RELOAD_VIEWER "+str(reload_viewer)+"\n")

####################################
#
# 	Functions:   
#
####################################
# for subprocess.Popen we need not to escape file names
def sh_escape(s):
	return s.replace("(","\\(").replace(")","\\)").replace(" ","\\ ")
   
# Make dictionary: xpdf_servername : file
# to test if the server host file use:
# basename(xpdf_server_file_dict().get(server, ['_no_file_'])[0]) == basename(file)
# this dictionary always contains the full path (Linux). If this doesn't work in
# the DEBUG message there is another way of getting the filename 
# it returns dictionary { xpdf_server : [ file, pid ]}   
# TODO: this is not working as I want to:
#    when the xpdf was opened first without a file it is not visible in the command line
#    I can use 'xpdf -remote <server> -exec "run(get_filename)"'
#    where get_filename is a simple program which returns the filename. 
#    Then if the file matches I can just reload, if not I can use:
# 	   xpdf -remote <server> -exec "openFile(file)"
def xpdf_server_file_dict():
	ps_list=psutil.get_pid_list()
	server_file_dict={}
	for pr in ps_list:
		try:
			name=psutil.Process(pr).name
			cmdline=psutil.Process(pr).cmdline
			if name == 'xpdf': 
				try:
					ind=cmdline.index('-remote')
				except:
					ind=0
				if ind != 0 and len(cmdline) >= 1:	
					server_file_dict[cmdline[ind+1]]=[cmdline[len(cmdline)-1], pr]
		except psutil.NoSuchProcess:
			null=pr
			# python sais: I want to have sth to do here 
			# this is the most simple thing I can think of,
			# but there should be a better solution. 
	return server_file_dict

# Send <keys> to vim server
def vim_remote_send(servername, keys):
	cmd=['vim', '--servername', servername, '--remote-send', keys]
	subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

# Send message to vim server
#    vim_echo(<message>, <echo\|echomsg>, <servername>, <highlightgroup>
def vim_echo(message, command, servername, highlight):
	cmd=['vim', '--servername', servername, '--remote-send', ':echohl '+highlight+'|'+command+' "'+message+'"|echohl Normal<CR>' ]
	subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

# Send <expr> to vim server 
# expr must be well quoted:
# 	vim_remote_expr('GVIM', "atplib#CatchStatus()")
# (this is the only way it works)
def vim_remote_expr(servername, expr):
	cmd=['vim', '--servername', servername, '--remote-expr', expr]
	out=subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	debug_file.write("vim_remote_expr "+" ".join(cmd)+"\n")
	debug_file.write(str(out.stdout.read())+"\n")
    
# Check if pid is running:
def running(pid):
	try:
		os.kill(int(pid), 0)
		return True
	except:
		return False

# Send pid to vim
pid	= os.getpid()

####################################
#
# 	Arguments:   
#
####################################

if not re.match(os.sep, mainfile_fp):
	mainfile_fp = os.path.join(os.getcwd(),mainfile_fp)
mainfile 	= os.path.basename(mainfile_fp)
mainfile_dir	= os.path.dirname(mainfile_fp)
if mainfile_dir == "":
	mainfile_fp	= os.path.join(os.getcwd(), mainfile) 
	mainfile	= os.path.basename(mainfile_fp)
	mainfile_dir	= os.path.dirname(mainfile_fp)
if os.path.islink(mainfile_fp):
	mainfile_fp	= os.readlink(mainfile_fp)
	# The above line works if the symlink was created with full path. 
	mainfile	= os.path.basename(mainfile_fp)
	mainfile_dir	= os.path.dirname(mainfile_fp)

mainfile_dir	= os.path.normcase(mainfile_dir+os.sep)
[basename, ext] = os.path.splitext(mainfile)
# ext		= ".pdf" # extension of the output file
			 # this will be passed to mklatex.py
			 # from line 908 of <SID>compiler()
output_fp	= os.path.splitext(mainfile_fp)[0]+extension

keep		= [ 'pdf', 'dvi', 'log', 'aux', 'toc', 'bbl', 'ind', 'pdfsync', 'synctex.gz' ]


####################################
#
# 	Make temporary directory:   
#
####################################
cwd	= os.getcwd()
if not os.path.exists(str(mainfile_dir)+".tmp"+os.sep):
	# This is the main tmp dir (./.tmp) 
	# it will not be deleted by this script
	# as another instance might be using it.
	# it can be removed by Vim.
	os.mkdir(str(mainfile_dir)+".tmp"+os.sep)
tmpdir	= tempfile.mkdtemp(prefix=str(mainfile_dir)+".tmp"+os.sep)
debug_file.write("TMPDIR: "+tmpdir+"\n")
tmpaux	= os.path.join(tmpdir,basename+".aux")
debug_file.write("TMPAUX: "+tmpaux+"\n")

command_opt.append('-output-directory='+tmpdir)
latex_cmd	= [command]+command_opt+[mainfile_fp]
debug_file.write("COMMAND "+" ".join(latex_cmd)+"\n")

# Copy important files to output directory:
for ext in keep:
	file_cp=basename+"."+ext
	if os.path.exists(file_cp):
		shutil.copy(file_cp, tmpdir)

####################################
#
# 	Compile:   
#
####################################
# Start Xpdf (this can be done before compelation, because we can load file into afterwards)
# in this way Xpdf starts faster (it is already running when file compiles,
# TODO: this might cause problems when the tex file is very simple and short.
# Can we test if xpdf started properly?
# okular doesn't behave nicly even with --unique switch.
# COMPILE
if bibtex and os.path.exists(tmpaux):
	os.chdir(tmpdir)
	debug_file.write("BIBTEX1"+"\n")
	subprocess.Popen(['bibtex', basename+".aux"])
	os.chdir(cwd)
	bibtex=False
	runs=max([runs, 2])
elif bibtex:
	runs=max([runs, 3])
	
debug_file.write("RANGE="+str(range(1,int(runs+1)))+"\n")
debug_file.write("RUNS="+str(runs)+"\n")
for i in range(1, int(runs+1)):
	#DEBUG:
	debug_file.write("RUN="+str(i)+"\n")
	ls_pipe=subprocess.Popen(['ls', tmpdir], stdout=subprocess.PIPE)
	debug_file.write(str(ls_pipe.stdout.read())+"\n")
	debug_file.write("BIBTEX="+str(bibtex)+"\n")
	if verbose == 'verbose' and i == runs:
# 	<SIS>compiler() contains here ( and not bibtex )
		debug_file.write("VERBOSE"+"\n")
		latex=subprocess.Popen(latex_cmd,)
		pid=latex.pid
		debug_file.write("latex pid "+str(pid)+"\n")
		latex.wait()
		latex_return_code=latex.returncode
		debug_file.write("latex ret code "+str(latex_return_code)+"\n")
	else:
		# TODO: this is not getting the error code
		latex=subprocess.Popen(latex_cmd, stdout=subprocess.PIPE)
		pid=latex.pid
		vim_remote_expr(servername, "atplib#LatexPID("+str(pid)+")")
		debug_file.write("latex pid "+str(pid)+"\n")
		latex.wait()
		latex_return_code=latex.returncode
		debug_file.write("latex return code "+str(latex_return_code)+"\n")
	if bibtex and i == 1:
		os.chdir(tmpdir)
		debug_file.write("BIBTEX2"+"\n")
		debug_file.write(os.getcwd()+"\n")
		subprocess.Popen(['bibtex', basename+".aux"])
		os.chdir(cwd)
	# Return code of compilation:
	if verbose != "verbose":
		vim_remote_expr(servername, "atplib#CatchStatus('"+str(latex_return_code)+"')")

####################################
#
# 	Reload/Start Viewer:   
#
####################################
if re.search(viewer, '^\s*xpdf\e') and reload_viewer:
	# The condition tests if the server XpdfServer is running
	xpdf_server_dict=xpdf_server_file_dict()
	cond = xpdf_server_dict.get(XpdfServer, ['_no_file_']) != ['_no_file_']
	debug_file.write("COND="+str(cond)+":"+str(reload_on_error)+":"+str(bang)+"\n")
	debug_file.write("COND="+str( not reload_on_error or bang )+"\n")
	debug_file.write(str(xpdf_server_dict)+"\n")
	if start == 1:
		run=['xpdf']
		run.extend(viewer_opt)
		run.append(output_fp)
		debug_file.write("D1: "+str(run)+"\n")
		subprocess.Popen(run)
# 		debug_file.write(str(pipe.stdout.read())+"\n")
	elif cond and ( reload_on_error or latex_ret_code  == 0 or bang ): 
		run=['xpdf', '-remote', XpdfServer, '-reload']
		subprocess.Popen(run, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		debug_file.write("D2: "+str(['xpdf',  '-remote', XpdfServer, '-reload'])+"\n")
else:
	if start >= 1:
		run=[viewer]
		run.extend(viewer_opt)
		run.append(output_fp)
		debug_file.write(str(run)+"\n")
		subprocess.Popen(run, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	if start == 2:
		vim_remote_expr(servername, "atplib#SyncTex()")

####################################
#
# 	Call Back Communication:   
#
####################################
# this is not working in vim
# within gvim it works (running a command doesn't suspend gvim) to be tested:
# I'm not sure if these commands reach gvim. But latex status is not needed in
# verbose mode can we add interaction as an option for verbose mode this would
# make classical style of compilation which is also nice :)
if verbose != "verbose":
	# call back:
	vim_remote_expr(servername, "atplib#CallBack('"+str(verbose)+"')")
	# return code of compelation is returned before (after each compilation).


####################################
#
# 	Copy Files and Clean:   
#
####################################

# Copy files:
os.chdir(tmpdir)
for ext in keep:
	file_cp=basename+"."+ext
	if os.path.exists(file_cp):
		shutil.copy(file_cp, mainfile_dir)
os.chdir(cwd)

# Clean:
debug_file.close()
shutil.rmtree(tmpdir)
