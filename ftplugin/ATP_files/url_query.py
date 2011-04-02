#!/usr/bin/python
import sys, urllib2, tempfile

url  = sys.argv[1]
print(url)
tmpf = sys.argv[2]
print(tmpf)

f    = open(tmpf, "w+")
data = urllib2.urlopen(url)
f.write(data.read())
