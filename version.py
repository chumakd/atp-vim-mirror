#!/usr/bin/python

import sys, re, datetime
from datetime import date 

date=date.today().strftime("%d %B %Y")

file="doc/automatic-tex-plugin.txt"
newversion=sys.argv[1]

file_o=open(file, "r")
file_l=file_o.readlines()
i=0
for line in file_l:
    i+=1
    if re.match('\s+An Introduction to AUTOMATIC \(La\)TeX PLUGIN \(ver(.|sion)?\s+\d+(\.\d+)+\)',line):
        break
print(file_l[i-1])
file_l[0]="*automatic-tex-plugin.txt* 	For Vim version 7.3	Last change: "+date+"\n"
file_l[i-1]='	    An Introduction to AUTOMATIC (La)TeX PLUGIN (ver. '+newversion+")\n"
file_o.close()
file_o=open(file, "w")
file_o.write("".join(file_l))
file_o.close()
