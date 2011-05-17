#!/usr/bin/python

import re, optparse
from optparse import OptionParser

# OPTIONS:
usage   = "usage: %prog [options]"
parser  = OptionParser(usage=usage)
parser.add_option("--files", dest="files")
parser.add_option("--auxfile", dest="auxfile")
(options, args) = parser.parse_args()
file_list=options.files.split(";")

# GENERATE TAGS:
# from \label{} and \cite{} commands:
tags=[]
tag_dict={}
for file_name in file_list:
    file=open(file_name, "r")
    file_list=file.read().split("\n")
    linenr=0
    for line in file_list:
        linenr+=1
        matches=re.findall('\\label{([^}]*)}', line)
        for match in matches:
            tags.extend([str(match)+"\t"+file_name+"\t"+str(linenr)])
            tag_dict[str(match)]=[str(linenr), file_name]
# from aux file; 
try:
    auxfile_list=open(options.auxfile, "r").read().split("\n")
    for line in auxfile_list:
        if re.match('\\\\newlabel{[^}]*}{{[^}]*}', line):
            [label, counter]=re.match('\\\\newlabel{([^}]*)}{{([^}]*)}', line).group(1,2)
            try:
                [linenr, file]=tag_dict[label]
            except KeyError:
                [linenr, file]=["no_label", "no_label"]
            if linenr != "no_label" and counter != "":
                tags.extend([str(counter)+"\t"+file+"\t"+linenr])
except IOError:
    print("There is no aux file.")
    pass

# SORT AND WRITE TAGS
tags_sorted=sorted(tags)
tag_file = open("tags", 'w')
tag_file.write("\n".join(tags_sorted))
