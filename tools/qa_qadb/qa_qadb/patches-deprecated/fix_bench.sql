-- zmena bench_data
alter table bench_data add column resultsID integer;

-- unikatni tcfID
select distinct(tcfID) from bench_data;

-- pocet results
select count(test_result.resultsID) from test_result join tcf_results on test_result.resultsID=tcf_results.resultsID where tcf_results.tcfID=?

-- hodnota results
select test_result.resultsID from test_result join tcf_results on test_result.resultsID=tcf_results.resultsID where tcf_results.tcfID=?


-- zmena ID
update bench_data set resultsID=? where tcfID=?

-- zmena primarniho klice
ALTER TABLE `bench_data` DROP PRIMARY KEY, ADD PRIMARY KEY(resultsID,partID)

-- zrusit tcfID
alter table bench_data drop column tcfID

-- zjistit zda lze provest (vsechny by mely mit hodnotu 1
select tcf_results.tcfID, count(*) from test_result join tcf_results on test_result.resultsID=tcf_results.resultsID where exists ( select tcfID from bench_data where bench_data.tcfID=tcf_results.tcfID) group by tcf_results.tcfID


-- pridani indexu do tcf_results
alter table tcf_results add index resultsID( resultsID );

select tg.tcfID, count(*) from tcf_group tg, bench_data bd where tg.tcfID=bd.tcfID group by tg.tcfID


select testsuites.testsuiteName from testsuites join tcf_group on testsuites.testsuiteID=tcf_group.tcfNameID where (not exists (select resultsID from tcf_results where tcf_results.tcfID=tcf_group.tcfID)) and exists (select tcfID from bench_data where bench_data.tcfID=tcf_group.tcfID)


select * from bench_data,tcf_group,tcf_results where bench_data.resultsID is null and bench_data.tcfID=tcf_results.tcfID and tcf_group.tcfID=bench_data.tcfID

select * from bench_data where resultsID is null and exists( select * from tcf_group,tcf_results where tcf_group.tcfID=bench_data.tcfID and tcf_results.tcfID=tcf_group.tcfID)



SELECT d.result FROM bench_parts p,bench_data d,tcf_group g,tcf_results tr,submissions s,testsuites t,products pr,releases r WHERE d.partID=p.partID AND d.resultsID=tr.resultsID AND tr.tcfID=g.tcfID AND s.submissionID=g.submissionID AND g.tcfNameID=t.testsuiteID AND pr.productID=s.productID AND r.releaseID=s.releaseID AND d.resultsID IN (3537131,3537132,3537222,3537224,3537228,3537229,3537230)  AND t.testsuiteName='dbench-default' AND s.test_host='patty' AND pr.product='SLES-10-SP2' AND r.release='beta1'

 ALTER TABLE `releases` ADD INDEX `r` ( `release` )  

alter table tcf_group add index tcfNameID(tcfNameID)

