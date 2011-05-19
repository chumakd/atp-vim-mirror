#!/usr/bin/python

import re, optparse, subprocess
from optparse import OptionParser

# TIP:
# I can use synstack function remotely to get tag_type.

# OPTIONS:
usage   = "usage: %prog [options]"
parser  = OptionParser(usage=usage)
parser.add_option("--files",    dest="files"    )
parser.add_option("--auxfile",  dest="auxfile"  )
parser.add_option("--hyperref", dest="hyperref", action="store_true", default=False)
parser.add_option("--servername", dest="servername", default="" )
parser.add_option("--progname", dest="progname", default="gvim" )
(options, args) = parser.parse_args()
file_list=options.files.split(";")

def vim_remote_expr(servername, expr):
# Send <expr> to vim server,

# expr must be well quoted:
#       vim_remote_expr('GVIM', "atplib#TexReturnCode()")
    cmd=[options.progname, '--servername', servername, '--remote-expr', expr]
    subprocess.Popen(cmd)

def get_tag_type(line, match, label):
# Find tag type,

# line is a string, match is an element of a MatchingObject
    tag_type=""
    if label == 'label':
        pat='(?:\\\\hypertarget{.*})?\s*\\\\label'
    else:
        pat='(?:\\\\label{.*})?\s*\\\\hypertarget'
    if re.match('\\\\part{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="part"
    elif re.match('.*\\\\chapter(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="chapter"
    elif re.match('.*\\\\section(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="section"
    elif re.match('.*\\\\subsection(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="subsection"
    elif re.match('.*\\\\subsubsection(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="subsubsection"
    elif re.match('.*\\\\paragraph(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="paragraph"
    elif re.match('.*\\\\subparagraph(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="subparagraph"
    elif re.match('.*\\\\begin{[^}]*}', line):
        # \label command must be in the same line, 
        # To do: I should add searching in next line too.
        #        Find that it is inside \begin{equation}:\end{equation}.
        type_match=re.match('.\\\\begin\s*{\s*([^}]*)\s*}(?:\s*{.*})?\s*(?:\[.*\])?\s*'+pat+'{'+match+'}', line)
        try:
            tag_type=type_match.group(1)
        except AttributeError:
            tag_type=""
    return tag_type

# GENERATE TAGS:
# From \label{} and \hypertarget{}{} commands:
tags=[]
tag_dict={}
for file_name in file_list:
    file=open(file_name, "r")
    file_list=file.read().split("\n")
    linenr=0
    for line in file_list:
        linenr+=1
        # Find labels in the current line:
        matches=re.findall('^(?:[^%]|\\\\%)*\\\\label{([^}]*)}', line)
        for match in matches:
            tag=str(match)+"\t"+file_name+"\t"+str(linenr)
            # Set the tag type:
            tag_type=get_tag_type(line, match, "label")
            tag+=";\"\tinfo:"+tag_type+"\tkind:label"
            # Add tag:
            tags.extend([tag])
            tag_dict[str(match)]=[str(linenr), file_name, tag_type, 'label']
        # Find hypertargets in the current line:        /this could be switched on/off depending on useage of hyperref/
        if options.hyperref:
            matches=re.findall('^(?:[^%]|\\\\%)*\\\\hypertarget{([^}]*)}', line)
            for match in matches:
                # Add only if not yet present in tag list:
                if not tag_dict.has_key(str(match)):
                    tag_dict[str(match)]=[str(linenr), file_name, tag_type, 'hyper']
                    tag_type=get_tag_type(line, match, 'hypertarget')
                    tags.extend([str(match)+"\t"+file_name+"\t"+str(linenr)+";\"\tinfo:"+tag_type+"\tkind:hyper"])
# From aux file:
ioerror=False
try:
    auxfile_list=open(options.auxfile, "r").read().split("\n")
    for line in auxfile_list:
        if re.match('\\\\newlabel{[^}]*}{{[^}]*}', line):
            [label, counter]=re.match('\\\\newlabel{([^}]*)}{{([^}]*)}', line).group(1,2)
            counter=re.sub('{', '', counter)
            try:
                [linenr, file, tag_type, kind]=tag_dict[label]
            except KeyError:
                [linenr, file, tag_type, kind]=["no_label", "no_label", "", ""]
            except ValueError:
                [linenr, file, tag_type, kind]=["no_label", "no_label", "", ""]
            if linenr != "no_label" and counter != "":
                tags.extend([str(counter)+"\t"+file+"\t"+linenr+";\"\tinfo:"+tag_type+"\tkind:"+kind])
except IOError:
    ioerror=True
    pass

# SORT (vim works faster when tag file is sorted) AND WRITE TAGS
tags_sorted=sorted(tags)
tag_file = open("tags", 'w')
tag_file.write("\n".join(tags_sorted))

# Communicate to Vim:
if options.servername != "":
    vim_remote_expr(options.servername, "atplib#Echo(\"[LatexTags:] tags done.\",'echo','')")
if ioerror:
    vim_remote_expr(options.servername, "atplib#Echo(\"[LatexTags:] no aux file.\",'echomsg', 'WarningMsg')")
