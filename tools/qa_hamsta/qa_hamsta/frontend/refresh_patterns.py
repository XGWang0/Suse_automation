#!/usr/bin/python

# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************

import update_repo_index, os, re, StringIO, gzip, string, urllib2, sys

def retrieve_patterns(repo):
	if string.join(repo.split('/')[-3:], '/') == 'suse/setup/descr':
		arch = ''
		for supported_arch in update_repo_index.supported_archs:
			if supported_arch in repo:
				arch = supported_arch
		if (re.match('i.86$', arch)):
			matcharch ='i.86'
		elif (re.match('ppc', arch)):
			matcharch = 'ppc(64(le)?)?'
		else:
			matcharch = arch
		re_arch = re.compile('\.' + matcharch + '\.pat(\.gz)?$')
		re_pat = re.compile('^=Pat: ')
		re_vis = re.compile('^=Vis: ')
		patterns = []
		try:
			# patfiles contain list of .pat or .pat.gz files with pattern definitions
			patfiles = filter(re_arch.search, urllib2.urlopen(repo + "/patterns").read().split("\n"))
			for patfile in patfiles:
				# Some patfile contain definition of multiple patterns, while some not
				# Patterh name line looks like:
				# =Pat:  Basis-Devel 11 89.17.4 i586
				pattern = os.path.join(repo, patfile)
				data = urllib2.urlopen(pattern).read()
				if (patfile.endswith('.gz')):
					data = gzip.GzipFile(fileobj = StringIO.StringIO(data)).read()
				
				pattern = None
				for line in data.split("\n"):
					if re.match(re_pat, line):
						pattern = line.split(' ')[2]
					if re.match(re_vis, line) and pattern != None:
						visible = line.split(' ')[1]
						if(re.match(r"([Tt]rue|TRUE)", visible)):
							patterns.append(pattern)
							pattern = None

				#for line in filter(re_pat.search, data.split("\n")):
				#	patterns.append(line.split(' ')[2])

		except:
			pass

		# If no patterns were found so far, it is possible that it is sle-12 (or new openSUSE)
		# and does not use pattern file. Instead it uses patterns RPMs
		# patterns-<PRODUCT>-<NAME_WITH_DASHES>-<PRODVER>-<VER>.<ARCH>.rpm
		if not patterns:
			# No patterns found so far. Trying new method...
			try:
				try:
					# Hack for ppc64le arch - try to add le to arch if path
					# does not exist. This scritp needs complete rewrite to
					# support addons (not just sdk), so IMHO can be accepted
					temprepo = repo.replace('setup/descr','')
					rpmpage = urllib2.urlopen(temprepo + "/"+arch).read()
				except:
					# read failed, trying ppc64le path
					rpmpage = urllib2.urlopen(temprepo + "/"+arch+"le").read()
	
				rpmpat = re.findall('<img.*?href="patterns-\w+-([\w-]+)-[\d.]+-[\d.]+\.\w+\.rpm',rpmpage)
				patterns = rpmpat
			except:
				pass

		if not patterns:
			print "No patterns found for " + repo + "."

		return patterns

	else:
		result = 0
		dirs = update_repo_index.list_dir(repo)
		for directory in dirs:
			result = retrieve_patterns(os.path.join(repo, directory))
			if result:
				break
		return result

if __name__ == '__main__':
	if len(sys.argv) > 1:
		for pattern in retrieve_patterns(sys.argv[1]):
			print pattern
