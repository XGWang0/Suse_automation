CREATE VIEW all_submissions_view AS select 
	res.resultsID,
	res.times_run,
	res.succeeded,
	res.failed,
	res.internal_error,
	res.test_time,
	res.testcaseID,
	tc.testcase,
	ts.testsuite,
	tcf_grp.tcfID,
	sub.submission_date,
	hosts.host,
	testers.tester,
	sub.comment,
	sub.submissionID,
	sub.type,
	sub.archID,
	sub.productID,
	sub.releaseID,
	arch.arch,
	prod.product,
	rel.release 
from
	results res
	join testcases tc using(testcaseID) 
	join tcf_group tcf_grp using(tcfID)
	join testsuites ts using (testsuiteID) 
	join submissions sub using(submissionID)
	join architectures arch using(archID)
	join products prod using(productID)
	join releases rel using(releaseID)
	join hosts using(hostID)
	join testers using(testerID);
