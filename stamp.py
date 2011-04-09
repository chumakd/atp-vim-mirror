#!/usr/bin/python

import sys, re

file="ftplugin/tex_atp.vim"
newstamp=sys.argv[1]

file_o=open(file, "r")
file_l=file_o.readlines()
i=0
for line in file_l:
    i+=1
    if re.match('\s*"\s+Time\s+Stamp:',line):
        break
file_l[i-1]='" Time Stamp: '+newstamp+"\n"
file_o.close()
file_o=open(file, "w")
file_o.write("".join(file_l))
file_o.close()
