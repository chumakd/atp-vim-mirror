#!/usr/bin/python

import re, optparse
from optparse import OptionParser

# OPTIONS:
usage   = "usage: %prog [options]"
parser  = OptionParser(usage=usage)
parser.add_option("--files",    dest="files"    )
parser.add_option("--auxfile",  dest="auxfile"  )
parser.add_option("--hyperref", dest="hyperref", action="store_true", default=False)
(options, args) = parser.parse_args()
file_list=options.files.split(";")

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
        matches=re.findall('^(?:[^%]|\\\\%)*\\label{([^}]*)}', line)
        for match in matches:
            tag=str(match)+"\t"+file_name+"\t"+str(linenr)
            # Set the tag type:
            tag_type=""
            if re.match('\\\\part{.*}\s*\\\\label{'+match+'}', line):
                tag_type="part"
            elif re.match('\\\\chapter{.*}\s*\\\\label{'+match+'}', line):
                tag_type="chapter"
            elif re.match('\\\\section{.*}\s*\\\\label{'+match+'}', line):
                tag_type="section"
            elif re.match('\\\\subsection{.*}\s*\\\\label{'+match+'}', line):
                tag_type="subsection"
            elif re.match('\\\\subsubsection{.*}\s*\\\\label{'+match+'}', line):
                tag_type="subsubsection"
            elif re.match('\\\\paragraph{.*}\s*\\\\label{'+match+'}', line):
                tag_type="paragraph"
            elif re.match('\\\\subparagraph{.*}\s*\\\\label{'+match+'}', line):
                tag_type="subparagraph"
            elif re.match('\\\\begin{[^}]*}', line):
                # \label command must be in the same line, 
                # To do: I should add searching in next line too.
                #        Find that it is inside \begin{equation}:\end{equation}.
                type_match=re.match('\\\\begin\s*{\s*([^}]*)\s*}(?:\s*{.*})?\s*(?:\[.*\])?\s*\\\\label{'+match+'}', line)
                try:
                    tag_type=type_match.group(1)
                except AttributeError:
                    tag_type=""
            if tag_type != "":
                tag+=";\"\tkind:"+tag_type+" "
            # Add tag:
            tags.extend([tag])
            tag_dict[str(match)]=[str(linenr), file_name, tag_type]
        # Find hypertargets in the current line:        /this could be switched on/off depending on useage of hyperref/
        if options.hyperref:
            matches=re.findall('^(?:[^%]|\\\\%)*\\hypertarget{([^}]*)}', line)
            for match in matches:
                # Add only if not yet present in tag list:
                if not tags.count(str(match)+"\t"+file_name+"\t"+str(linenr)):
                    tags.extend([str(match)+"\t"+file_name+"\t"+str(linenr)])
                    tag_dict[str(match)]=[str(linenr), file_name]
# From aux file:
try:
    auxfile_list=open(options.auxfile, "r").read().split("\n")
    for line in auxfile_list:
        if re.match('\\\\newlabel{[^}]*}{{[^}]*}', line):
            [label, counter]=re.match('\\\\newlabel{([^}]*)}{{([^}]*)}', line).group(1,2)
            counter=re.sub('{', '', counter)
            try:
                [linenr, file, tag_type]=tag_dict[label]
            except KeyError:
                [linenr, file, tag_type]=["no_label", "no_label", ""]
            if linenr != "no_label" and counter != "":
                if tag_type == "":
                    tags.extend([str(counter)+"\t"+file+"\t"+linenr])
                else:
                    tags.extend([str(counter)+"\t"+file+"\t"+linenr+";\"\tkind:"+tag_type])
except IOError:
    print("There is no aux file.")
    pass

# SORT (vim works faster when tag file is sorted) AND WRITE TAGS
tags_sorted=sorted(tags)
tag_file = open("tags", 'w')
tag_file.write("\n".join(tags_sorted))
