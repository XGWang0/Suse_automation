<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
  THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
  CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
  RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
  THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
  THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
  TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
  PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
  PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
  AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
  LIABILITY.
  
  SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
  WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
  AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
  LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
  WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
  ****************************************************************************
 */

	# Keep this structure (for now), especially the " -- " between the feature title and description
	$latestFeatures = array(
			"2.3.0" => array(
				'2 May 2012 -- Outdated SUTs -- out-of date and developement SUTs are marked in web frontend and can be updated from the frontend',
				'2 May 2012 -- HAMSTA CLI -- command line interface to Hamsta has been improved', 
				'2 May 2012 -- Improved patterns -- it is possible to get/choose all patterns from all products during SUT resintallation (until now, only SLES/D & SDK patterns were shown)', 
				'2 May 2012 -- Parametrized jobs -- predefined jobs can now be parametrized, so they can be customized every time the job is run', 
				'2 May 2012 -- Job web editor -- web editors of jobs has been imrpoved. Now with multimachine job support', 
				'2 May 2012 -- One-click installer -- HAMSTA client can now be installed by one-click installer', 
				'2 May 2012 -- QADB improvements'
			),
			"2.2.0" => array(
				'14 November 2011 -- Repartitioning support -- during reinstall (with an option to leave some space unpartitioned).',
				'14 November 2011 -- Default additional RPMs -- It is now possible to define list of RPMs (in hamsta frontend config), that will be prepopulated on reinstall page.',
				'14 November 2011 -- Optimized multicast -- HAMSTA multicast format has been optimized to contain less data.',
				'14 November 2011 -- Chained build validation -- It is possible now to define more than just one build validation job, and these jobs will be run sequentially.'
			),
			"2.1.0" => array(
				'4 September 2011 -- Hamsta Virtual Machine Integration (QA Cloud) -- Hamsta can now track and manage virtual machine hosts as well as the VMs installed on those hosts, including basic VM installs (now officially supported).',
				'4 September 2011 -- Renam of QA packages -- Almost all  QA packages were renamed. New naming corresponds to the role of the package.',
				'4 September 2011 -- Upgrade support -- HAMSTA now supports automated upgrade of machines to SLES11-SP2',
				'4 September 2011 --  Changed format of configuration files -- Format of /etc/qa files has changed, it is now more user friendly and is easier to parse.',
				'4 September 2011 -- More teststsuites -- More testsuites were added to automation, including HA and more Autotest testsuites.'
			),
			"2.0.0" => array(
				'8 Jun 2011 -- New/updated testsuites -- The following testsuites have either been added or significantly updated: qa_virtualization,
					LTP, qa_libo, qa_gnome, qa_cts (HA).',
				'8 Jun 2011 -- Hamsta Virtual Machine Integration -- Hamsta can now track and manage virtual machine hosts as well as the VMs installed on those hosts, 
					including basic VM installs. More enhancements around this area are coming, leading up to the full QA Cloud implementation.',
				'7 Jun 2011 -- Autotest Sub-Parsers -- Previously, any test suites run through AutoTest would simply show up as a single test, however with AutoTest sub-parsers 
					you can now run certain AutoTest suites and get individual results for each test case. Parsers have already been added for bonnie, dbench, aiostress, cerberus, 
					disktest and sleeptest.',
				'26 May 2011 -- Reinstall Pattern List Customization -- Being able to customize which patterns are installed during your automated installation is now
					much easier with the reinstall pattern list customization enhancement. Now you can select a pre-defined list of patterns, or customize the patterns you want
					installed just by clicking a series of checkboxes on the reinstall page.',
				'25 May 2011 -- Kernel of the Day (KOTD) -- KOTD makes it possible to a standard set of kernel tests on the current pre-release kernel every evening.',
				'25 May 2011 -- SLED Regression Tests -- A standard regression test target has been set up for running all existing, stable regression tests for SLED through Hamsta.',
				'20 May 2011 -- Individual Add-On Repository Registration Codes -- You can now add an online update registration code for each add-on repository that you add 
					to your auto-install.',
				'10 May 2011 -- Chainloader Selective Install -- Rather than always installing to the default-selected chain bootloader partition, you can now see a list of all available
					partitions to install to and select which one you want to use.',
				'5 May 2011 -- Flagged and Removed Duplicate and Obsolete Test Suites -- Test suites that were deemed duplicates or obsolete were flagged and moved to their own
					special exhile location within our SVN.',
				'4 May 2011 -- Automated Build Validation for SLES 11 SP2 -- Automated build validation has been prepared so that it will work for the upcoming SLES 11 SP2 testing.'
			),
			"Milestone 7" => array(
				'6 Apr 2011 -- New/updated testsuites -- The following testsuites have either been added or significantly updated: qa_hazard,
					qa_NetworkManager, qa_mozmill, qa_phoronix, qa_virtualization, qa_zypper and qa_kiwi.',
				'31 Mar 2011 -- Improved error messages -- Certain error messages that were previously being lost on certain page redirects
					are now being more clearly displayed.',
				'8 Mar 2011 -- New standard SuSE password -- All automation tools have now been updated to use
					the new standard SuSE password, meaning systems installed automatically through hamsta will
					have that new password set as the default. If you do not yet know the new password, please talk
					to your direct manager.',
				'2 Mar 2011 -- Hardware summary information -- New fields have been added to the main machine list allowing
					you to see important system information much faster, such as the number of CPUs, the CPU vendor, the amount of RAM
					and the number of disks and their corresponding sizes. These fields can be accessed by changing the selected "Display fields"
					in the "Search" section of the main machine list.',
				'20 Feb 2011 -- Graphical install option -- When you reinstall a machine, you now have the option
					of which graphical desktop to install (or to install none at all). On the reinstall page, just change the
					graphical desktop option to Gnome or KDE, or leave it without a desktop. Note: SLED installs will
					automatically default to the Gnome desktop. If installing a graphical desktop, VNC will also be
					enabled automatically.',
				'4 Mar 2011 -- QA package documentation -- Man pages have been added for various QA packages. So, if you
					have a QA package installed on your system, you can now run "man PACKAGENAME" and get some details about it.
					In addition, that documentation has been made available online
					<a href="http://qa.suse.de/automation/qa-packages" target="_blank">here</a>
					or by clicking the
					<img src="../images/icon-info.png" width="15" alt="Information Icon" title="Information Icon" />
					icon on the send job page in Hamsta'
			),
			"Milestone 6" => array(
				'3 Feb 2011 -- Filterable, color-coded job logging -- When a job runs through hamsta, there
					are a lot of separate processes and procedures in play. Previously, this caused quite a
					mess in the log on the job details page. Now, all job logs are filterable, color-coded
					and clearly divided/marked based on which process the output is from.<br /><br />To see
					the new job logging, simply click on any job ID from the "List Jobs" or machine details
					pages.',
				'3 Feb 2011 -- Machine action history -- The machine action history logs major changes
					that are done to a machine including reserving, unreserving, reinstalling, 
					starting jobs, changing configuration options, etc. The machine action history 
					is available by clicking on a machine to view its details and then scrolling 
					to the bottom of the details page. By default, only the last few changes are shown, 
					but a full list is linked from that page.<br /><br />Each action is accompanied 
					by the person that performed the action. Keep in mind that there is currently no 
					reliable identification/access-control functionality in Hamsta, so for right now 
					we rely on the machine\'s "Used By" field for this information.',
				'12 Jan 2011 -- Able to set default serial console and installation options -- For quite a while
					now, our reinstall page has supported entering linuxrc installation options (such as for SSH and 
					VNC installs, etc), but you had to enter them manually for each install. Now, you can store 
					default serial console and installation options for each machine.<br /><br />To do this, click to edit a 
					machine and modify the "Console Device", "Console Speed", "Enable Console" and "Default 
					Install Options" fields. The next time you run a reinstall through Hamsta, the selected settings
					will show up automatically'
			)
		);

	$fields_list = array(
		'hostname'=>'Hostname',
		'status_string'=>'Status',
		'used_by'=>'Used by',
		'usage'=>'Usage',
		'reserved'=>'Reserved',
		'expires_formated'=>'Expires',
		'group'=>'Group',
		'product'=>'Product',
		'architecture'=>'Installed Arch',
		'architecture_capable'=>'CPU Arch',
		'kernel'=>'Kernel',
		'cpu_numbers'=>'CPUs',
		'memory_size'=>'Memory',
		'disk_size'=>'Disks',
		'cpu_vendor'=>'CPU vendor',
		'affiliation'=>'Affiliation',
		'ip_address'=>'IP address',
		'maintainer_string'=>'Maintainer',
		'notes'=>'Notes',
		'unique_id'=>'Unique ID',
		'serialconsole'=>'Serial console',
		'powerswitch'=>'Power switch',
		'role'=>'Role',
		'type'=>'Type',
		'vh'=>'Virt. Host'
	);

# header & footer links
 $naviarr = array (
  "List Machines"=>"index.php?go=machines",
  "List Groups"=>"index.php?go=groups",
  "List Jobs"=>"index.php?go=jobruns",
  "Validation Test"=>"index.php?go=validation",
  "AutoPXE"=>"index.php?go=autopxe",
  "QA Cloud"=>"index.php?go=qacloud",
  "QADB"=>"http://qadb.suse.de/qadb/",
  "About Hamsta"=>"index.php?go=about"
 );

$virtdisktypes = array("def", "file", "tap:aio", "tap:qcow", "tap:qcow2");

$hamstaVersion = htmlspecialchars(`rpm -q qa_hamsta-master`);
$packageVersions = explode("\n", htmlspecialchars(`REPO=$(zypper lr -u | grep ibs/QA:/Head | awk '{FS="|"; print $3}'); zypper se -sr \$REPO | awk '{FS="|"; gsub(" ", "", $2); gsub(" ", "", $4); print $2 " " $4}'`));
?>
