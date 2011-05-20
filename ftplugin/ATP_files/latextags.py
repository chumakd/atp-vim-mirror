#!/usr/bin/python

import re, optparse, subprocess
from optparse import OptionParser

# ToDoList:
# I can use synstack function remotely to get tag_type.
# I can scan bib files to get bibkeys (but this might be slow)!
#       this could be written to seprate file (does vim support using multiple tag file)

# OPTIONS:
usage   = "usage: %prog [options]"
parser  = OptionParser(usage=usage)
parser.add_option("--files",    dest="files"    )
parser.add_option("--auxfile",  dest="auxfile"  )
parser.add_option("--hyperref", dest="hyperref", action="store_true", default=False)
parser.add_option("--servername", dest="servername", default="" )
parser.add_option("--progname", dest="progname", default="gvim" )
parser.add_option("--bibfiles", dest="bibfiles", default="")
(options, args) = parser.parse_args()
file_list=options.files.split(";")
bib_list=options.bibfiles.split(";")

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
    if re.search('\\\\part{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="part"
    elif re.search('\\\\chapter(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="chapter"
    elif re.search('\\\\section(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="section"
    elif re.search('\\\\subsection(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="subsection"
    elif re.search('\\\\subsubsection(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="subsubsection"
    elif re.search('\\\\paragraph(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="paragraph"
    elif re.search('\\\\subparagraph(?:\[.*\])?{.*}\s*'+pat+'{'+match+'}', line):
        tag_type="subparagraph"
    elif re.search('\\\\begin{[^}]*}', line):
        # \label command must be in the same line, 
        # To do: I should add searching in next line too.
        #        Find that it is inside \begin{equation}:\end{equation}.
        type_match=re.search('\\\\begin\s*{\s*([^}]*)\s*}(?:\s*{.*})?\s*(?:\[.*\])?\s*'+pat+'{'+match+'}', line)
        try:
            # Use the last found match (though it should be just one).
            tag_type=type_match.group(len(type_match.groups()))
        except AttributeError:
            tag_type=""
    return tag_type

# Read bib files:
if len(bib_list) > 1:
    bib_dict={}
    for bibfile in bib_list:
        bib_dict[bibfile]=open(bibfile, "r").read()

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
        matches=re.findall('^(?:[^%]|\\\\%)*\\\\cite(?:\[.*\])?{([^}]*)}', line)
        for match in matches:
            if not tag_dict.has_key(str(match)):
                if len(bib_list) == 1:
                    tag=str(match)+"\t"+bib_list[0]+"\t/"+match+"/\t;\"kind:cite"
                    tag_dict[str(match)]=['', bib_list[0], '', 'cite']
                    tags.extend([tag])
                elif len(bib_list) > 1:
                    bib_file=""
                    for bibfile in bib_list:
                        bibmatch=re.search(str(match), bib_dict[bibfile])
                        if bibmatch:
                            bib_file=bibfile
                            break
                    if bib_file != "":
                        tag=str(match)+"\t"+bib_file+"\t/"+match+"/;\"\tkind:cite"
                        tag_dict[str(match)]=['', bib_file, '', 'cite']
                        tags.extend([tag])
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
