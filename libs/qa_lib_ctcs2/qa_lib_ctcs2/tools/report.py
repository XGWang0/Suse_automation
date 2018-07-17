#!/usr/bin/env python

# replacement for report (.pl)
# creates a report in html
# 
# Author:  Gernot Payer <gpayer@suse.de>

import glob
import sys
import os
import re

def getTCFDirs():
	ret = []
	for tcf in sys.argv[1:]:
		ret.append(tcf)
	return ret

def notInstalledError(dir,tc):
	fn = dir+'/'+tc
	flen = os.stat(fn)[6]
	f = file(fn,'r')
	cont = f.read(flen)
	f.close()
	if None == re.search('NOTINSTALLEDERROR',cont,re.MULTILINE):
		return 0
	else:
		return 1
	
# FIXME : add support for skipped testcases
def printResults(dir):
	try:
		f = file(dir+'/test_results','r')
	except IOError:
		sys.stderr.write('Warning: no test_results in %s\n' % dir)
		return
	print "<h3>Results from %s</h3>" % dir
	print '<table border="1">'
	print '<tr><th>Times run</th><th>Succeeded</th><th>Failed</th><th>Internal Errors</th><th>Test time</th><th>Testcase</th></tr>'
	lines = f.readlines()
	f.close()
	lines = map(str.rstrip,lines)
	lhash = {}
	for i in xrange(0,len(lines),2):
		lhash[lines[i]] = lines[i+1]
	keys = lhash.keys()
	keys.sort()
	for k in keys:
		tc = k
		failed, succeeded, runcount, time, interrs, skips = lhash[k].split(' ')
		time = time + 's'
		rccolor = '#FFFFFF'
		if int(runcount) == 0:
			rccolor = '#FF1010'
			bgcolor = '#FFFFFF'
			succeeded = 'N/A'
			failed = 'N/A'
		elif int(failed) > 0:
			if notInstalledError(dir,tc):
				runcount = 'N/A'
				succeeded = 'N/A'
				failed = 'N/A'
				time = 'N/A'
				bgcolor = '#E060FF'
			else:
				bgcolor = '#FF6060'
		elif int(interrs) > 0:
			bgcolor = '#FF00FF'
		else:
			bgcolor = '#FFFFFF'
		if int(interrs) == 0:
			print '<tr><td bgcolor="%s">%s</td><td>%s</td><td bgcolor="%s">%s</td><td>%s</td><td>%s</td><td bgcolor="%s"><a href="%s">%s</a></td></tr>' % (rccolor,runcount,succeeded,bgcolor,failed,interrs,time,bgcolor,tc,tc)
		else:
			print '<tr><td>%s</td><td>%s</td><td>%s</td><td bgcolor="%s">%s</td><td>%s</td><td bgcolor="%s"><a href="%s">%s</a></td></tr>' % (runcount,succeeded,failed,bgcolor,interrs,time,bgcolor,tc,tc)
	print '</table>'

if __name__ == '__main__':
	if len(sys.argv) < 2:
		sys.stderr.write('Usage: report.py </path/to/log-directory>, default logfiles are subdirectorys from /var/log/qa/ctcs2 \n')
		sys.exit(1)
	tcfdirs = getTCFDirs()
	if len(tcfdirs) == 0:
		sys.stderr.write('Error: no ctcs result directories found!\n')
		sys.exit(1)
	print "<html>\n<head><title>ctcs results</title></head>\n<body>"
	for d in tcfdirs:
		printResults(d)
	print "</body>\n</html>"
