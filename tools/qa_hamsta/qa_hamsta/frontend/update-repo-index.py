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

"""Generate network installation sources repo index and sdk index
The index is written as 'default.repo.json' and 'default.sdk.json' under current directory by default.
In case you don't have write access to your repo, you can run it remotely too
by passing the url of your repo, we will fetch and parse.

DirectoryStructure
====================
	product/arch/DVDx

Usage
=======
	$ python update-repo-index.py -r "<repourl1> [repourl2] [...]" -s "<sdkurl1> [sdkurl2] [...]" -o <output_name>
	repourl could be "http://dist.suse.de/install/SLP/"
"""
import os,re,urllib2,optparse,json,sys,gzip,StringIO
supported_archs = ['i386', 'i586', 'x86_64', 'ia64', 'ppc', 'ppc64', 'ppc64le', 's390x']
basename = 'default'

def list_dir(url):
	"""Parsing the web page and get the directory list, os.listdir clone"""
	page = urllib2.urlopen(url).read()
	return re.findall('<img.*?folder.(?:gif|png).*?href="(.*?)/">', page)

def append_result(repo, product, arch, am):
	p = {}
	p['product'] = product
	p['arch'] = arch
	p['url'] = os.path.join(repo, product, am)
	baserepo = p['url']
	p['pattern'] = []

	if (re.match('i.86$', arch)):
		matcharch ='i.86'
	elif (re.match('ppc', arch)):
		matcharch = 'ppc(64(le)?)?'
	else:
		matcharch = arch
	re_arch = re.compile('\.' + matcharch + '\.pat(\.gz)?$')
	re_pat = re.compile('^=Pat: ')
	re_vis = re.compile('^=Vis: ')
	try:
		# patfiles contain list of .pat or .pat.gz files with pattern definitions
		patfiles = filter(re_arch.search, urllib2.urlopen(baserepo + "/suse/setup/descr/patterns").read().split("\n"))
		if not patfiles:
			print "Pattern descriptor (" + baserepo + "/suse/setup/descr/patterns) is empty. No pattern info grepped."
		for patfile in patfiles:
			# Some patfile contain definition of multiple patterns, while some not
			# Patterh name line looks like:
			# =Pat:  Basis-Devel 11 89.17.4 i586
			data = urllib2.urlopen(baserepo + "/suse/setup/descr/" + patfile).read()
			if (patfile.endswith('.gz')):
				data = gzip.GzipFile(fileobj = StringIO.StringIO(data)).read()

			pattern = None
			for line in data.split("\n"):
				if re.match(re_pat, line):
					pattern = line.split(' ')[2]
				if re.match(re_vis, line) and pattern != None:
					visible = line.split(' ')[1]
					if(re.match(r"([Tt]rue|TRUE)", visible)):
						p['pattern'].append(pattern)
						pattern = None

			#for line in filter(re_pat.search, data.split("\n")):
			#	p['pattern'].append(line.split(' ')[2])
	except:
		print "Can not read " + baserepo + "/suse/setup/descr/patterns (either non-exsit or broken)."
	
	# If no patterns were found so far, it is possible that it is sle-12 (or new openSUSE)
	# and does not use pattern file. Instead it uses patterns RPMs
	# patterns-<PRODUCT>-<NAME_WITH_DASHES>-<PRODVER>-<VER>.<ARCH>.rpm
	if not p['pattern']:
		print "No patterns found so far. Trying new method..."
		try:
			try:
				# Hack for ppc64le arch - try to add le to arch if path
				# does not exist. This scritp needs complete rewrite to
				# support addons (not just sdk), so IMHO can be accepted
				rpmpage = urllib2.urlopen(baserepo + "/suse/"+arch).read()
			except:
				print "read failed, trying ppc64le path"
				rpmpage = urllib2.urlopen(baserepo + "/suse/"+arch+"le").read()
				arch = arch+"le"
				p['arch'] = arch

			rpmpat = re.findall('<img.*?href="patterns-\w+-([\w-]+)-[\d.]+-[\d.]+\.\w+\.rpm',rpmpage)
			p['pattern'] = rpmpat
		except:
			print "No patterns found in " + baserepo


	print 'Found', product, arch, " on  ", repo
	return p

def generate_index(repo_url, theFilter):
	"""Generate index for repo
	repo_url is where the repo can be accessed publicly by http
	"""
	result = []
	for repo in repo_url.split():
		products = list_dir(repo)
		newlist = []
		for product in products:
			for i in theFilter['+']:
				if i in product.lower():
					newlist.append(product)
			for i in theFilter['-']:
				if i in product.lower():
					try:
						newlist.remove(product)
					except:
						pass
		for item in newlist:
			dirs = list_dir(os.path.join(repo, item))
			if 'suse' in dirs: #that means a plain mount, without ix86/DVD1. e.g. 147.2.207.242/iso_mnt
				#if 'DVD1' not in item and 'openSUSE' not in item and 'Media1' not in item:
				#	continue
				subdirs = list_dir(os.path.join(repo, item, 'suse'))
				for arch in supported_archs:
					if arch in item:
						break
				am = '' #am means arch+media part in the url string
				result.append(append_result(repo, item, arch, am))
			else:
				for arch in dirs:
					if arch not in supported_archs:
						continue
					subdirs = list_dir(os.path.join(repo, item, arch))
					if 'media.1' in subdirs:
						am = arch
					elif 'DVD1' in subdirs:
						am = arch + "/DVD1"
					else:
						am = arch + "/CD1"
					result.append(append_result(repo, item, arch, am))
	def product(s):
		return s['product']
	sresult = sorted(result, key=product)
	return sresult

# Main program entry
if __name__ == '__main__':
	parser = optparse.OptionParser()	
	group = optparse.OptionGroup(parser, 'Example', './update-repo-index.py -r "http://147.2.207.242/iso_mnt/ http://147.2.207.208/dist/install/SLP/" -s "http://147.2.207.242/iso_mnt/ http://147.2.207.208/dist/install/" -o cn')
	parser.add_option("-r", "--repo", dest="repourl", help = 'The base url(s) of your install repo, support multiple urls which sperated by space')
	parser.add_option("-s", "--sdk", dest="sdkurl", help = 'The base url(s) of your sdk repo, support multiple urls which sperated by space')
	parser.add_option("-o", "--output", dest="output", help = 'The output index file base name, default value is "default" if -o option is not given')
	parser.add_option_group(group)
	(options, args) = parser.parse_args()
	if not (options.repourl or options.sdkurl):
		print 'Install repo url and SDK repo url are required, please try ./update-repo-index.py -h'
		sys.exit()
	else:
		if options.output:
			basename = options.output
		theFilter = {'+':["sles","sled","opensuse","server","desktop"], '-':["sdk"]}
		json.dump(generate_index(options.repourl, theFilter),
		open("%s.repo.json" %basename, 'w'), indent = 2)
		theFilter = {'+':["sdk"], '-':["vmware"]}
		if options.sdkurl:
			json.dump(generate_index(options.sdkurl, theFilter),
			open("%s.sdk.json" %basename, 'w'), indent = 2)

