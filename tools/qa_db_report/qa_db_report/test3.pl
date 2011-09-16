#!/usr/bin/perl -w

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
