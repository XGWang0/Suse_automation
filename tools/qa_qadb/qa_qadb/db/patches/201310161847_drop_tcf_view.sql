DROP VIEW IF EXISTS tcf_view;
CREATE VIEW tcf_view
	AS SELECT submission_id,submission_date,arch,product,`release`,active,related,host,tester,`comment`,rpm_config_id,hwinfo_id,tcf_id,testsuite,log_url,test_date
	FROM submission_view JOIN tcf_group USING(submission_id) JOIN testsuite USING(testsuite_id);

