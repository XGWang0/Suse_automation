#!/usr/bin/perl -w
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


use strict;
use qadb;

&set_user('bender.suse.cz','qadb');

#print join "\n",&tmp_list('hwinfo','blabla');
#&remove_tmp_files();

my $configID=&rpm_info('rpmlist');
my $hwinfoID=&hwinfo('hwinfo');
my $submissionID=&create_submission(1, 'test3.pl', 1, 1, 1, $configID, $hwinfoID);
printf "SubmissionID=%i\n", $submissionID;
my $tcfID1=&create_tcf(21,$submissionID,'http://root.cz','2009-09-25 12:00:00');
my $tcfID2=&create_tcf(22,$submissionID,'http://abclinuxu.cz','2009-09-25 13:00:00');
my $resultsID1=&submit_results(1,2,3,4,5,6,$tcfID1);
my $resultsID2=&submit_results(3,4,5,6,7,8,$tcfID1);
&insert_benchmark_data($resultsID1,1,1);
&insert_benchmark_data($resultsID1,2,1);
&exec_submission_type($submissionID,'patch:ffea3eaf97e43abb88f477ec4f689352/');
printf "TCFID=%i,%i\n",$tcfID1,$tcfID2;
&commit();
system("sh -c read");
&delete_open_submissions();
#&undo_rpm_info();
#&undo_hwinfo();
&enum_undo_all_inserts();
&commit();
&tidy_up();

