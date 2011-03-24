#!/usr/bin/python
# This file is a part of ATP plugin to vim.
# AUTHOR: Marcin Szamotulski

# SYNTAX:
# atp_RevSearch.py <file> <line_nr> [<col_nr>]

# DESRIPTION: 
# This is a python sctipt which implements reverse searching (okular->vim)
# it uses atplib#FindAndOpen() function which finds the vimserver which hosts
# the <file>, then opens it on the <line_nr> and column <col_nr>.
# Column number is an optoinal argument if not set on the command line it is 1.

# HOW TO CONFIGURE OKULAR to get Reverse Search
# Designed to put in okular: 
# 		Settings>Configure Okular>Editor
# Choose: Custom Text Edit
# In the command field type: atp_RevSearch.py '%f' '%l'
# If it is not in your $PATH put the full path of the script.

# DEBUG:
# debug file : /tmp/atp_RevSearch.debug

import subprocess, sys, re

output = subprocess.Popen(["vim", "--serverlist"], stdout=subprocess.PIPE)
# The output from this command has 
servers = str(output.stdout.read())
# TODO: it is better to match ^b'\zs\(.*\)\ze':
servers=re.sub("^b'",'', servers)
servers=re.sub("'$",'', servers)
server_list=servers.split('\\n')
# TODO: I should test if the server is non empty (or '^\s*$'):
server = server_list[0]
# Get the column (it is an optional argument)
if (len(sys.argv) >= 4 and int(sys.argv[3]) > 0):
    column = str(sys.argv[3])
else:
    column = str(1)
cmd="vim --servername "+server+" --remote-expr \"atplib#FindAndOpen('"+sys.argv[1]+"','"+sys.argv[2]+"','"+column+"')\""
subprocess.call(cmd, shell=True) 

f = open('/tmp/atp_RevSearch.debug', 'w')
f.write(">>> file        "+sys.argv[1]+"\n>>> line        "+sys.argv[2]+"\n>>> column      "+column+"\n>>> server      "+server+"\n>>> server list "+str(server_list)+"\n>>> cmd         "+cmd+"\n")
f.close()
