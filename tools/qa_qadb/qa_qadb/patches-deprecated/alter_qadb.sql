reset master;
-- delete obsolete tables
drop table if exists tiobench_details;
drop table if exists dbenchdflt_details;
drop table if exists dbenchsyncIO_details;
drop table if exists rpms_SUT;
-- drop last run remains
drop view if exists tests;
drop view if exists bench_suites;
drop view if exists submissions_view;
drop view if exists testsuites_view;
drop view if exists benchsuites_view;
drop view if exists rpms_view;
drop view if exists tcf_view;
drop view if exists bench_tcf_view;
drop table if exists tests;
drop table if exists rpmConfig;
drop table if exists results;
drop table if exists attr_keys;
drop table if exists hosts;
drop table if exists testers;
drop table if exists hwinfo;
drop table if exists bd_tmp;
drop table if exists rpmd_tpm;
drop table if exists rpmTmp;
drop table if exists softwareConfigTmp;
-- TODO: perhaps migrating data to bench_data?

-- set default DB collation here so that newly created tables have it
alter database qadb default character set utf8 collate utf8_unicode_ci;

-- new table to find obsolete script versions
drop table if exists script_versions;
create table if not exists script_versions (
	versionID int not null auto_increment,
	script_name varchar(50),
	latest_major int not null,
	latest_minor int,
	minimal_major int,
	minimal_minor int,
	primary key(versionID),
	unique(script_name)
) engine innodb;
INSERT INTO `script_versions` (`versionID`, `script_name`, `latest_major`, `latest_minor`, `minimal_major`, `minimal_minor`) VALUES
(1, 'qa_db_report.pl', 1, 0, 1, 0);

drop table if exists table_desc;
create table if not exists table_desc (
	table_desc_id int not null auto_increment,
	`table` varchar(50) not null,
	`desc` varchar(32768),
	primary key(table_desc_id),
	unique(`table`)
) engine innodb;
INSERT INTO `table_desc` (`table_desc_id`, `table`, `desc`) VALUES
(1, 'architectures', 'Enumerates known architectures.'),
(2, 'bench_data', 'Used for benchmark results, stores one benchmark number per row.'),
(3, 'bench_parts', 'Stores different benchmark parts and their names.'),
(4, 'kernel_branches', 'Enumerates used kernel branches.'),
(5, 'kotd_testing', 'Every KOTD submission has its details here.'),
(6, 'maintenance_testing', 'Every maintainence testing submission has its details here.'),
(7, 'product_testing', 'Every product testing submission has its details here.'),
(8, 'products', 'Enumerates know products.'),
(9, 'released_rpms', 'Used to list relevant RPMs for maintainence testing.'),
(10, 'releases', 'Enumerates known releases.'),
(11, 'rpm_basenames', 'Stores base RPM names.'),
(12, 'rpm_versions', 'Stores RPM versions.'),
(13, 'rpms', 'Makes a combination of RPM name and version.'),
(14, 'rpmConfig', 'Stores MD5 sums of configurations. A configuration is alphabetically sorted,\r\nspace-separated list of entries in form of &lt;basename&gt;-&lt;version&gt;'),
(15, 'softwareConfig', 'Lists all RPMs and their versions that were installed during a test.'),
(16, 'submissions', 'Every submissions has its row here.'),
(17, 'tcf_group', 'Every run of a testsuite has its row here.'),
(18, 'testcases', 'Enumerates known testcases.'),
(19, 'results', 'Every run of a subtest has its row here, to store its results.'),
(20, 'tests', 'This is a statistics table with generated contents.\r\nShows what testcases appear in what testsuites, and if they contain benchmark data.'),
(21, 'testsuites', 'Enumerates known testsuites.'),
(22, 'waiver_data', 'Lists waiver testcase occurences.'),
(23, 'waiver_testcase', 'Lists waiver testcases.'),
(24, 'board', 'This table holds topics from the QADB bulletin board.'),
(25, 'hosts', 'This table enumerates the computers that were used as test hosts.'),
(26, 'hwinfo', 'This table lists bzipped hwinfo. &lt;br/&gt;\r\nLines with IRQ stats are removed, so that the hwinfo is the same for the same machine and product. '),
(27, 'script_versions', 'This table holds info about oldest allowed and newest available versions of different scripts. The scripts can do online checks using <a href="versions.php">version.php</a> .'),
(28, 'table_desc', 'Describes tables in the current database.\r\nThe info is Added into the generated table description.'),
(30, 'testers', 'Enumerates users that ran tests.');


-- convert & drop tcf_results
alter table test_result add column tcfID int, add index ( tcfid, testcaseID ), drop column performanceID;
update test_result r, tcf_results tr, tcf_group tg set r.tcfID=tg.tcfID where r.resultsID=tr.resultsID and tr.tcfID=tg.tcfID;
delete from test_result where tcfID is null;
alter table test_result change tcfID tcfID int not null;
drop table if exists tcf_results;
rename table test_result to results;

-- tcf_group
alter table tcf_group change column tcfNameID testsuiteID int not null, add column logs_url varchar(250),add column test_date datetime;

-- fixes timestamp change on update
alter table submissions change submission_date submission_date timestamp not null default CURRENT_TIMESTAMP;

-- adding related submissions
alter table submissions add column related int;
update submissions s, submissions_addons a set s.related=a.previousID where s.submissionID=a.submissionID;
drop table submissions_addons;

-- converting hostnames
create table hosts (
	hostID int not null auto_increment,
	host varchar(50),
	primary key (hostID),
	unique(host)
) engine innodb;
insert into hosts(host) select distinct replace(replace(test_host,'.suse.de',''),'.suse.cz','') from submissions where length(test_host)>0 order by test_host;
alter table submissions add column hostID int not null, add index(hostID);
update submissions set hostID=(select hostID from hosts where host=test_host);
alter table submissions drop column test_host;
delete from submissions where hostID=0;
-- hwinfo into submissions
create table hwinfo (
	hwinfoID int not null auto_increment,
	md5sum char(32) not null,
	hwinfo_bz2 blob,
	primary key(hwinfoID),
	unique(md5sum)
) engine innodb;
alter table submissions add column hwinfoID int, add index(hwinfoID);
-- add index to submissions comments
alter table submissions add index(comment);


create table testers (
	testerID int not null auto_increment,
	tester varchar(50),
	primary key(testerID),
	unique index(tester)
) engine innodb;
insert into testers(tester) select distinct tester from submissions where length(tester)>0 order by tester;
alter table submissions add column testerID int not null;
update submissions set testerID=(select testerID from testers where tester=submissions.tester);
alter table submissions drop column tester;
delete from submissions where testerID=0;
alter table submissions add index(testerID);


-- rpm info
-- 1: set up environment so that we can do md5sum correctly
-- 2: make table rpmTmp with tcfID/md5sum
-- 3: make table rpmConfig with distinct md5sums
-- 4: add configID to tcf_group
-- 5: replace table softwareConfig with link between rpmConfig and tcf_group
set group_concat_max_len=1048576;
create temporary table rpmTmp as select tcfID, md5(group_concat(b.basename,'-',v.version order by b.basename,v.version separator ' ')) as md5sum from softwareConfig c, rpms r, rpm_basenames b, rpm_versions v where c.rpmID=r.rpmID and r.basenameID=b.basenameID and r.versionID=v.versionID group by tcfID;
create table rpmConfig ( 
	configID int not null auto_increment, 
	md5sum char(32) not null, 
	primary key(configID), 
	unique(md5sum) 
) engine innodb;
insert into rpmConfig(md5sum) select distinct md5sum from rpmTmp;
alter table tcf_group add column configID int;
update tcf_group tg, rpmTmp tmp, rpmConfig c set tg.configID=c.configID where tg.tcfID=tmp.tcfID and tmp.md5sum=c.md5sum;
drop table rpmTmp;
create table softwareConfigTmp engine innodb as select distinct configID,rpmID from tcf_group tg, softwareConfig c where tg.tcfID=c.tcfID;
drop table softwareConfig;
rename table softwareConfigTmp to softwareConfig;

-- clean up RPM tables in following steps:
-- 1: make table bd_tmp and split there the unsplitted basenames
-- 2: reinsert the splitted parts to rpm_basenames and rpm_versions when necessary
-- 3: update rpms to use the splitted parts instead
create temporary table bd_tmp( rpmID int,basename varchar(50), basenameID int, bleft varchar(50), bright varchar(50),bID int, vID int,index(bleft),index(bright));
insert into bd_tmp(rpmID,basenameID,basename,bleft,bright) select rpmID, basenameID, basename, substr(basename,1,length(basename)-length(substring_index(basename,'-',-2))-1), substring_index(basename,'-',-2) from rpms join rpm_basenames using(basenameID) join rpm_versions using(versionID) where version='';
insert ignore into rpm_basenames(basename) select bleft from bd_tmp;
insert ignore into rpm_versions(version) select bright from bd_tmp;
update bd_tmp,rpm_basenames set bd_tmp.bID=rpm_basenames.basenameID where bd_tmp.bleft =rpm_basenames.basename;
update bd_tmp,rpm_versions  set bd_tmp.vID=rpm_versions.versionID   where bd_tmp.bright=rpm_versions.version;
update rpms,bd_tmp set rpms.basenameID=bd_tmp.bID,rpms.versionID=bd_tmp.vID where rpms.rpmID=bd_tmp.rpmID;
drop table bd_tmp;
delete from rpm_versions where version='';

-- remove duplicite RPMs from the table rpms
-- 1: make table rpmd_tmp with obsolete rpms
-- 2: relink softwareConfig entries that use obsolete rpms
-- 3: delete obsolete rpms from table rpms
create temporary table rpmd_tmp as select r1.rpmID,r1.basenameID,r1.versionID,min(r3.rpmID) as origID from rpms r1,rpms r3 where exists( select * from rpms r2 where r1.basenameID=r2.basenameID and r1.versionID=r2.versionID and r1.rpmID>r2.rpmID ) and r1.basenameID=r3.basenameID and r1.versionID=r3.versionID group by r1.rpmID,r1.basenameID,r1.versionID;
update softwareConfig,rpmd_tmp set softwareConfig.rpmID=rpmd_tmp.origID where softwareConfig.rpmID=rpmd_tmp.rpmID;
alter table rpmd_tmp add index(rpmID);
delete from rpms where exists( select * from rpmd_tmp where rpms.rpmID=rpmd_tmp.rpmID);
drop table rpmd_tmp;
alter table rpms add unique index(basenameID,versionID);
alter table rpms drop index basenameID;

-- allow longer submission comments
alter table submissions change `comment` `comment` varchar(16384);

-- split submissions with duplicite RPM configuration
-- 1: make table sub_split_tmp with info about submission parts that have different rpms
-- 2: make table sub_addons_tmp with new submission data - MySQL cannot do INSERT SELECT on one table
-- 3: insert new submissions
-- 4: add part info to the comment of the splitted submissions
-- 5: move configID field from tcf_group to submissions
-- 6: propagate the splits to product_testing, maintenance_testing, and kotd_testing
-- 7: clean up

-- 1:
create temporary table tmp as select submissionID, count(distinct configID) as cnt from submissions join tcf_group using(submissionID) group by submissionID;
create temporary table sub_split_tmp as select submissionID,g1.configID,count(distinct g2.configID) as part from submissions s join tmp using(submissionID) join tcf_group g1 using(submissionID) join tcf_group g2 using(submissionID) where cnt>1 and g2.configID<=g1.configID group by submissionID,g1.configID order by submissionID;
-- 2:
create temporary table sub_addons_tmp as select * from submissions join sub_split_tmp using(submissionID) where part>1;

-- 3:
alter table sub_addons_tmp add column newID int;
alter table submissions add column configID int;
alter table submissions add column oldID int;
alter table submissions add column part int;
insert into submissions(oldID,submission_date,comment,archID,productID,releaseID,active,related,hostID,testerID,hwinfoID,configID,part) select submissionID,submission_date,comment,archID,productID,releaseID,active,related,hostID,testerID,hwinfoID,configID,part from sub_addons_tmp;

-- 4:
update tcf_group,submissions set tcf_group.submissionID=submissions.submissionID where tcf_group.submissionID=submissions.oldID and tcf_group.configID=submissions.configID;
update submissions set comment=concat(comment,' (',oldID,' conf. #',part,')') where part is not null;

-- 5:
update submissions,tcf_group set submissions.configID=tcf_group.configID where submissions.submissionID=tcf_group.submissionID and submissions.configID is null;
alter table tcf_group drop column configID;

-- 6:
insert into product_testing(submissionID) select s.submissionID from submissions s join product_testing t where s.oldID=t.submissionID and s.part>1;
insert into kotd_testing(submissionID,`release`,version,branch) select s.submissionID,t.`release`,t.version,t.branch from submissions s join kotd_testing t where s.oldID=t.submissionID and s.part>1;
insert into maintenance_testing(submissionID,patchID,md5sum,status) select s.submissionID,t.patchID,t.md5sum,t.status from submissions s join maintenance_testing t where s.oldID=t.submissionID and s.part>1;

-- 7:
alter table submissions drop column oldID;
alter table submissions drop column part;
drop table sub_split_tmp;
drop table sub_addons_tmp;
drop table tmp;


-- allow RPM versions to fit in the table
alter table rpm_versions change version version varchar(150) not null;

-- clean up the junk
delete from submissions where archID=0 or productID=0 or releaseID=0;
delete from submissions where not exists ( select * from tcf_group  where submissions.submissionID=submissionID );
delete from tcf_group where not exists( select * from submissions s where s.submissionID=tcf_group.submissionID);
delete from tcf_group   where not exists ( select * from testsuites where testsuiteID=tcf_group.testsuiteID );
delete from results where not exists ( select * from tcf_group  where tcfID=results.tcfID);
delete from maintenance_testing where not exists( select * from submissions s where s.submissionID=maintenance_testing.submissionID);
delete from kotd_testing where not exists( select * from submissions s where s.submissionID=kotd_testing.submissionID);
delete from product_testing where not exists( select * from submissions s where s.submissionID=product_testing.submissionID);
delete from releases where not exists( select * from submissions s where s.releaseID=releases.releaseID );
delete from testsuites where not exists( select * from tcf_group tg where tg.testsuiteID=testsuiteID );
delete from bench_data where not exists ( select * from results where resultsID=bench_data.resultsID );
delete from released_rpms where not exists ( select * from submissions s where s.submissionID=released_rpms.submissionID );

-- fix kotd_testing broken kernel branch field
alter table kotd_testing add column branchID int;
alter table kotd_testing add index ( branchID );
update kotd_testing,kernel_branches set kotd_testing.branchID=kernel_branches.branchID where kotd_testing.branch=kernel_branches.branch;
delete from kotd_testing where branchID is null;
alter table kotd_testing change branchID branchID int not null;
alter table kotd_testing drop column branch;


-- table to link testsuites and testcases
create table tests(
	testsuiteID int not null,
	testcaseID int not null,
	is_bench tinyint not null default 0,
	index(testcaseID),
	index(is_bench),
	primary key(testsuiteID,testcaseID)
) engine innodb;
-- howto update tests:
delete from tests;
insert into tests( testsuiteid, testcaseid ) select distinct g.testsuiteid as  testsuiteid, r.testcaseid as testcaseid from results r join tcf_group g using(tcfid);
update tests t set is_bench=exists( select * from results r join bench_data b using(resultsID) where r.testcaseID=t.testcaseID);

create view bench_suites as select distinct testsuiteID from tests where is_bench;

-- change waiver tables
delete from waiver_data;
delete from waiver_testcase;
alter table waiver_data drop column resultsID;
alter table waiver_data add column testcaseID int not null;
update waiver_data d, waiver_testcase t set d.testcaseID=t.testcaseID where d.waiverID=t.waiverID;
alter table waiver_data add unique index(testcaseID);
alter table waiver_testcase drop column testcaseID;
alter table waiver_data change bugID bugID int(10) null;
alter table waiver_testcase add column (archID int, matchtype enum('no problem','problem') not null);

-- normalize column names in enum tables
alter table architectures change architecture arch varchar(30) not null;
alter table testsuites change testsuiteName testsuite varchar(50) not null;
alter table testcases change testcaseName testcase varchar(50) not null;

-- add missing enum indexes
alter table architectures add unique index(arch);
alter table products add unique index (product);
alter table releases add unique index (`release`);
alter table kernel_branches add unique index(branch);

-- move to InnoDB
alter table architectures engine=innodb;
alter table bench_data engine=innodb;
alter table bench_parts engine=innodb;
alter table kernel_branches engine=innodb;
alter table kotd_testing engine=innodb;
alter table maintenance_testing engine=innodb;
alter table product_testing engine=innodb;
alter table products engine=innodb;
alter table released_rpms engine=innodb;
alter table releases engine=innodb;
alter table rpm_basenames engine=innodb;
alter table rpm_versions engine=innodb;
alter table rpms engine=innodb;
alter table submissions engine=innodb;
alter table tcf_group engine=innodb;
alter table results engine=innodb;
alter table testcases engine=innodb;
alter table testsuites engine=innodb;
alter table waiver_data engine=innodb;
alter table waiver_testcase engine=innodb;


-- foreign keys
-- parts and subparts: on delete cascade
-- enums : on delete restrict
-- optional data: on delete set null
alter table submissions add foreign key (archID) references architectures(archID) on delete restrict;
alter table submissions add foreign key (productID) references products(productID) on delete restrict;
alter table submissions add index(active);
alter table submissions add foreign key (releaseID) references releases(releaseID) on delete restrict;
alter table submissions add foreign key (related) references submissions(submissionID) on delete set null;
alter table submissions add foreign key (configID) references rpmConfig(configID) on delete restrict;
alter table submissions add foreign key(hostID) references hosts(hostID) on delete restrict;
alter table submissions add foreign key(testerID) references testers(testerID) on delete restrict;
alter table submissions add foreign key(hwinfoID) references hwinfo(hwinfoID) on delete restrict;

alter table kotd_testing add foreign key (branchID) references kernel_branches(branchID) on delete restrict;
alter table product_testing add foreign key(submissionID) references submissions(submissionID) on delete cascade;
alter table kotd_testing add foreign key(submissionID) references submissions(submissionID) on delete cascade;
alter table maintenance_testing add foreign key(submissionID) references submissions(submissionID) on delete cascade;
alter table tcf_group add foreign key(submissionID) references submissions(submissionID) on delete cascade;
alter table released_rpms add foreign key(submissionID) references submissions(submissionID) on delete cascade;

alter table results add foreign key(tcfID) references tcf_group(tcfID) on delete cascade;
alter table results add foreign key(testcaseID) references testcases(testcaseID) on delete restrict;
alter table bench_data add foreign key(partID) references bench_parts(partID) on delete restrict;
alter table bench_data add foreign key(resultsID) references results(resultsID) on delete cascade;
alter table tcf_group add foreign key(testsuiteID) references testsuites(testsuiteID) on delete restrict;
alter table rpms add foreign key(basenameID) references rpm_basenames(basenameID) on delete restrict;
alter table rpms add foreign key(versionID) references rpm_versions(versionID) on delete restrict;
alter table released_rpms add foreign key(basenameID) references rpm_basenames(basenameID) on delete restrict;
alter table released_rpms change versionID versionID int null;
update released_rpms set versionID=null where versionID=0;
alter table released_rpms add foreign key(versionID) references rpm_versions(versionID) on delete restrict;

alter table tests add foreign key(testsuiteID) references testsuites(testsuiteID) on delete restrict;
alter table tests add foreign key(testcaseID) references testcases(testcaseID) on delete restrict;
alter table softwareConfig add foreign key(configID) references rpmConfig(configID) on delete cascade;
alter table softwareConfig add foreign key(rpmID) references rpms(rpmID) on delete cascade;
alter table waiver_data add foreign key(testcaseID) references testcases(testcaseID) on delete restrict;
alter table waiver_testcase add foreign key(archID) references architectures(archID) on delete restrict;
alter table waiver_testcase add foreign key(productID) references products(productID) on delete restrict;
alter table waiver_testcase add foreign key(releaseID) references releases(releaseID) on delete restrict;
alter table waiver_testcase add foreign key(waiverID) references waiver_data(waiverID) on delete cascade;

-- create some useful views
create view submissions_view
	as select submissionID,submission_date,arch,product,`release`,active,related,host,tester,comment, configID 
	from submissions join architectures using(archID) join products using(productID) join releases using(releaseID) join hosts using(hostID) join testers using(testerID);
create view tcf_view
	as select submissionID,submission_date,arch,product,`release`,host,tester,testsuite,configID
	from submissions_view join tcf_group using(submissionID) join testsuites using(testsuiteID);
create view bench_tcf_view
	as select submissionID,submission_date,arch,product,`release`,host,tester,testsuite,configID
	from submissions_view join tcf_group using(submissionID) join testsuites using(testsuiteID)
	where exists( select * from tests where testsuiteID=tcf_group.testsuiteID and is_bench );
create view rpms_view
	as select rpmID,basename,version from rpms join rpm_basenames using(basenameID) join rpm_versions using(versionID);
-- new table for attributes
-- create table attr_keys(
--	keyID int not null auto_increment primary key,
--	keyName varchar(100)
-- ) engine innodb;

-- create table attr_vals(
--	valID int not null auto_increment primary key,
--	valName varchar(100)
-- ) engine innodb;

-- create table attrs(
--	attrID int not null auto_increment primary key,
--	attrSetID int not null,
--	keyID int not null,
--	valID int not null,
--	foreign key(keyID) references attr_keys(keyID) on delete restrict,
--	foreign key(valID) references attr_vals(valID) on delete restrict,
--	index (attrSetID)
-- ) engine innodb;

-- QADB board
drop table if exists board;
create table if not exists board (
	boardID int not null auto_increment,
	created_by int not null,
	updated_by int null,
	last_update timestamp not null default current_timestamp on update current_timestamp,
	topic varchar(32768),
	foreign key(created_by) references testers(testerID),
	foreign key(updated_by) references testers(testerID),
	primary key(boardID),
	index(last_update)
) engine innodb;
INSERT IGNORE INTO `board` (`boardID`, `created_by`, `updated_by`, `last_update`, `topic`) VALUES
(2, 23, 23, '2009-10-20 15:27:09', 'This is the QADB board.\r\n\r\nInsert your feedback here.\r\n\r\nYou can also write about bugs, problems, and wanted features (of course you can use the standard tools as well)\r\n\r\nHave a nice day.');


-- change collation
alter table architectures default character set utf8 collate utf8_unicode_ci;
alter table bench_parts default character set utf8 collate utf8_unicode_ci;
alter table bench_data default character set utf8 collate utf8_unicode_ci;
alter table kernel_branches default character set utf8 collate utf8_unicode_ci;
alter table kotd_testing default character set utf8 collate utf8_unicode_ci;
alter table maintenance_testing default character set utf8 collate utf8_unicode_ci;
alter table products default character set utf8 collate utf8_unicode_ci;
alter table product_testing default character set utf8 collate utf8_unicode_ci;
alter table released_rpms default character set utf8 collate utf8_unicode_ci;
alter table releases default character set utf8 collate utf8_unicode_ci;
alter table results default character set utf8 collate utf8_unicode_ci;
alter table rpms default character set utf8 collate utf8_unicode_ci;
alter table rpm_basenames default character set utf8 collate utf8_unicode_ci;
alter table rpm_versions default character set utf8 collate utf8_unicode_ci;
alter table submissions default character set utf8 collate utf8_unicode_ci;
alter table tcf_group default character set utf8 collate utf8_unicode_ci;
alter table testcases default character set utf8 collate utf8_unicode_ci;
alter table testsuites default character set utf8 collate utf8_unicode_ci;
alter table waiver_data default character set utf8 collate utf8_unicode_ci;
alter table waiver_testcase default character set utf8 collate utf8_unicode_ci;


reset master;

-- compress the old database and set it RO by:
-- # for A in *.MYI; do echo $A; myisampack -f $A; myisamchk -rq $A; done
