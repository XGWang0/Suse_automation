-- phpMyAdmin SQL Dump
-- version 3.1.3.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 11, 2010 at 04:17 PM
-- Server version: 5.0.67
-- PHP Version: 5.2.5

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `qadb`
--

-- --------------------------------------------------------

--
-- Table structure for table `architectures`
--

CREATE TABLE IF NOT EXISTS `architectures` (
  `archID` int(11) NOT NULL auto_increment,
  `arch` varchar(30) character set latin1 NOT NULL,
  PRIMARY KEY  (`archID`),
  UNIQUE KEY `arch` (`arch`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=15 ;

-- --------------------------------------------------------

--
-- Table structure for table `bench_data`
--

CREATE TABLE IF NOT EXISTS `bench_data` (
  `partID` int(11) NOT NULL default '0',
  `result` float default NULL,
  `resultsID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`resultsID`,`partID`),
  KEY `partID` (`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bench_parts`
--

CREATE TABLE IF NOT EXISTS `bench_parts` (
  `partID` int(11) NOT NULL auto_increment,
  `part` varchar(1000) character set latin1 default NULL,
  PRIMARY KEY  (`partID`),
  KEY `part` (`part`(767))
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=2954 ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `bench_suites`
--
CREATE TABLE IF NOT EXISTS `bench_suites` (
`testsuiteID` int(11)
);
-- --------------------------------------------------------

--
-- Stand-in structure for view `bench_tcf_view`
--
CREATE TABLE IF NOT EXISTS `bench_tcf_view` (
`submissionID` int(11)
,`submission_date` timestamp
,`arch` varchar(30)
,`product` varchar(50)
,`release` varchar(50)
,`host` varchar(50)
,`tester` varchar(50)
,`testsuite` varchar(50)
,`configID` int(11)
);
-- --------------------------------------------------------

--
-- Table structure for table `board`
--

CREATE TABLE IF NOT EXISTS `board` (
  `boardID` int(11) NOT NULL auto_increment,
  `created_by` int(11) NOT NULL,
  `updated_by` int(11) default NULL,
  `last_update` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `topic` mediumtext collate utf8_unicode_ci,
  PRIMARY KEY  (`boardID`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `last_update` (`last_update`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=4 ;

-- --------------------------------------------------------

--
-- Table structure for table `board_last`
--

CREATE TABLE IF NOT EXISTS `board_last` (
  `testerID` int(11) NOT NULL,
  `last` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`testerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hosts`
--

CREATE TABLE IF NOT EXISTS `hosts` (
  `hostID` int(11) NOT NULL auto_increment,
  `host` varchar(50) collate utf8_unicode_ci default NULL,
  PRIMARY KEY  (`hostID`),
  UNIQUE KEY `host` (`host`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=360 ;

-- --------------------------------------------------------

--
-- Table structure for table `hwinfo`
--

CREATE TABLE IF NOT EXISTS `hwinfo` (
  `hwinfoID` int(11) NOT NULL auto_increment,
  `md5sum` char(32) collate utf8_unicode_ci NOT NULL,
  `hwinfo_bz2` blob,
  PRIMARY KEY  (`hwinfoID`),
  UNIQUE KEY `md5sum` (`md5sum`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=534 ;

-- --------------------------------------------------------

--
-- Table structure for table `kernel_branches`
--

CREATE TABLE IF NOT EXISTS `kernel_branches` (
  `branchID` int(11) NOT NULL auto_increment,
  `branch` varchar(32) character set latin1 NOT NULL default '',
  PRIMARY KEY  (`branchID`),
  UNIQUE KEY `branch` (`branch`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=12 ;

-- --------------------------------------------------------

--
-- Table structure for table `kotd_testing`
--

CREATE TABLE IF NOT EXISTS `kotd_testing` (
  `kotdID` int(11) NOT NULL auto_increment,
  `submissionID` int(11) NOT NULL default '0',
  `release` varchar(256) character set latin1 NOT NULL default '',
  `version` varchar(32) character set latin1 NOT NULL default '',
  `branchID` int(11) NOT NULL,
  PRIMARY KEY  (`kotdID`),
  KEY `submissionID` (`submissionID`),
  KEY `branchID` (`branchID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=500 ;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_testing`
--

CREATE TABLE IF NOT EXISTS `maintenance_testing` (
  `maintID` int(11) NOT NULL auto_increment,
  `patchID` varchar(50) character set latin1 NOT NULL,
  `md5sum` char(32) character set latin1 NOT NULL default '',
  `status` enum('wip','rejected','approved') character set latin1 default NULL,
  `submissionID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`maintID`),
  UNIQUE KEY `submissionID` (`submissionID`),
  KEY `md5sum` (`md5sum`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1338 ;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE IF NOT EXISTS `products` (
  `productID` int(10) NOT NULL auto_increment,
  `product` varchar(50) character set latin1 default NULL,
  PRIMARY KEY  (`productID`),
  UNIQUE KEY `product` (`product`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=30 ;

-- --------------------------------------------------------

--
-- Table structure for table `product_testing`
--

CREATE TABLE IF NOT EXISTS `product_testing` (
  `prodtestID` int(11) NOT NULL auto_increment,
  `submissionID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`prodtestID`),
  UNIQUE KEY `submissionID` (`submissionID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=2793 ;

-- --------------------------------------------------------

--
-- Table structure for table `released_rpms`
--

CREATE TABLE IF NOT EXISTS `released_rpms` (
  `releasedrpmID` int(11) NOT NULL auto_increment,
  `basenameID` int(11) NOT NULL default '0',
  `submissionID` int(11) NOT NULL default '0',
  `versionID` int(11) default NULL,
  PRIMARY KEY  (`releasedrpmID`),
  KEY `submissionID` (`submissionID`,`basenameID`),
  KEY `versionID` (`versionID`),
  KEY `basenameID` (`basenameID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=17829 ;

-- --------------------------------------------------------

--
-- Table structure for table `releases`
--

CREATE TABLE IF NOT EXISTS `releases` (
  `releaseID` int(10) NOT NULL auto_increment,
  `release` varchar(50) character set latin1 default NULL,
  PRIMARY KEY  (`releaseID`),
  UNIQUE KEY `release` (`release`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=86 ;

-- --------------------------------------------------------

--
-- Table structure for table `results`
--

CREATE TABLE IF NOT EXISTS `results` (
  `resultsID` int(11) NOT NULL auto_increment,
  `times_run` int(5) default NULL,
  `succeeded` int(10) default '0',
  `failed` int(10) default '0',
  `internal_error` int(10) default '0',
  `skipped` int(11) default '0',
  `test_time` int(10) default NULL,
  `testcaseID` int(11) NOT NULL default '0',
  `tcfID` int(11) NOT NULL,
  PRIMARY KEY  (`resultsID`),
  KEY `testcaseID` (`testcaseID`),
  KEY `tcfID` (`tcfID`,`testcaseID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=10588015 ;

-- --------------------------------------------------------

--
-- Table structure for table `rpmConfig`
--

CREATE TABLE IF NOT EXISTS `rpmConfig` (
  `configID` int(11) NOT NULL auto_increment,
  `md5sum` char(32) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`configID`),
  UNIQUE KEY `md5sum` (`md5sum`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=3280 ;

-- --------------------------------------------------------

--
-- Table structure for table `rpms`
--

CREATE TABLE IF NOT EXISTS `rpms` (
  `rpmID` int(11) NOT NULL auto_increment,
  `basenameID` int(11) NOT NULL default '0',
  `versionID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`rpmID`),
  UNIQUE KEY `basenameID_2` (`basenameID`,`versionID`),
  KEY `versionID` (`versionID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=114853 ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `rpms_view`
--
CREATE TABLE IF NOT EXISTS `rpms_view` (
`rpmID` int(11)
,`basename` varchar(50)
,`version` varchar(150)
);
-- --------------------------------------------------------

--
-- Table structure for table `rpm_basenames`
--

CREATE TABLE IF NOT EXISTS `rpm_basenames` (
  `basenameID` int(11) NOT NULL auto_increment,
  `basename` varchar(50) character set latin1 NOT NULL default '',
  PRIMARY KEY  (`basenameID`),
  UNIQUE KEY `basename` (`basename`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=13212 ;

-- --------------------------------------------------------

--
-- Table structure for table `rpm_versions`
--

CREATE TABLE IF NOT EXISTS `rpm_versions` (
  `versionID` int(11) NOT NULL auto_increment,
  `version` varchar(150) character set latin1 NOT NULL,
  PRIMARY KEY  (`versionID`),
  UNIQUE KEY `version` (`version`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=58657 ;

-- --------------------------------------------------------

--
-- Table structure for table `script_versions`
--

CREATE TABLE IF NOT EXISTS `script_versions` (
  `versionID` int(11) NOT NULL auto_increment,
  `script_name` varchar(50) collate utf8_unicode_ci default NULL,
  `latest_major` int(11) NOT NULL,
  `latest_minor` int(11) default NULL,
  `minimal_major` int(11) default NULL,
  `minimal_minor` int(11) default NULL,
  PRIMARY KEY  (`versionID`),
  UNIQUE KEY `script_name` (`script_name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=3 ;

-- --------------------------------------------------------

--
-- Table structure for table `softwareConfig`
--

CREATE TABLE IF NOT EXISTS `softwareConfig` (
  `configID` int(11) default NULL,
  `rpmID` int(11) NOT NULL default '0',
  KEY `configID` (`configID`),
  KEY `rpmID` (`rpmID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `submissions`
--

CREATE TABLE IF NOT EXISTS `submissions` (
  `submissionID` int(11) NOT NULL auto_increment,
  `submission_date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `comment` varchar(16384) character set latin1 default NULL,
  `archID` int(11) NOT NULL default '0',
  `productID` int(11) NOT NULL default '0',
  `releaseID` int(11) NOT NULL default '0',
  `active` tinyint(1) NOT NULL default '1',
  `related` int(11) default NULL,
  `hostID` int(11) NOT NULL,
  `hwinfoID` int(11) default NULL,
  `testerID` int(11) NOT NULL,
  `configID` int(11) default NULL,
  `type` enum('prod','kotd','maint') collate utf8_unicode_ci default NULL,
  PRIMARY KEY  (`submissionID`),
  KEY `archID` (`archID`),
  KEY `productID` (`productID`),
  KEY `releaseID` (`releaseID`),
  KEY `hostID` (`hostID`),
  KEY `hwinfoID` (`hwinfoID`),
  KEY `comment` (`comment`(767)),
  KEY `testerID` (`testerID`),
  KEY `active` (`active`),
  KEY `related` (`related`),
  KEY `configID` (`configID`),
  KEY `type` (`type`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=5397 ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `submissions_view`
--
CREATE TABLE IF NOT EXISTS `submissions_view` (
`submissionID` int(11)
,`submission_date` timestamp
,`arch` varchar(30)
,`product` varchar(50)
,`release` varchar(50)
,`active` tinyint(1)
,`related` int(11)
,`host` varchar(50)
,`tester` varchar(50)
,`comment` varchar(16384)
,`configID` int(11)
);
-- --------------------------------------------------------

--
-- Table structure for table `table_desc`
--

CREATE TABLE IF NOT EXISTS `table_desc` (
  `table_desc_id` int(11) NOT NULL auto_increment,
  `table` varchar(50) collate utf8_unicode_ci NOT NULL,
  `desc` mediumtext collate utf8_unicode_ci,
  PRIMARY KEY  (`table_desc_id`),
  UNIQUE KEY `table` (`table`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=31 ;

-- --------------------------------------------------------

--
-- Table structure for table `tcf_group`
--

CREATE TABLE IF NOT EXISTS `tcf_group` (
  `tcfID` int(11) NOT NULL auto_increment,
  `testsuiteID` int(11) NOT NULL,
  `submissionID` int(11) NOT NULL default '0',
  `logs_url` varchar(250) character set latin1 default NULL,
  `test_date` datetime default NULL,
  PRIMARY KEY  (`tcfID`),
  KEY `submissionID` (`submissionID`,`testsuiteID`),
  KEY `testsuiteID` (`testsuiteID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=60628 ;

-- --------------------------------------------------------

--
-- Table structure for table `testcases`
--

CREATE TABLE IF NOT EXISTS `testcases` (
  `testcaseID` int(11) NOT NULL auto_increment,
  `testcase` varchar(50) character set latin1 NOT NULL,
  PRIMARY KEY  (`testcaseID`),
  UNIQUE KEY `testcaseName` (`testcase`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=17881 ;

-- --------------------------------------------------------

--
-- Table structure for table `testers`
--

CREATE TABLE IF NOT EXISTS `testers` (
  `testerID` int(11) NOT NULL auto_increment,
  `tester` varchar(50) collate utf8_unicode_ci default NULL,
  PRIMARY KEY  (`testerID`),
  UNIQUE KEY `tester` (`tester`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=29 ;

-- --------------------------------------------------------

--
-- Table structure for table `tests`
--

CREATE TABLE IF NOT EXISTS `tests` (
  `testsuiteID` int(11) NOT NULL,
  `testcaseID` int(11) NOT NULL,
  `is_bench` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`testsuiteID`,`testcaseID`),
  KEY `testcaseID` (`testcaseID`),
  KEY `is_bench` (`is_bench`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `testsuites`
--

CREATE TABLE IF NOT EXISTS `testsuites` (
  `testsuiteID` int(11) NOT NULL auto_increment,
  `testsuite` varchar(50) character set latin1 NOT NULL,
  PRIMARY KEY  (`testsuiteID`),
  UNIQUE KEY `testsuiteName` (`testsuite`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=312 ;

-- --------------------------------------------------------

--
-- Table structure for table `waiver_data`
--

CREATE TABLE IF NOT EXISTS `waiver_data` (
  `waiverID` int(11) NOT NULL auto_increment,
  `bugID` int(10) default NULL,
  `explanation` text character set latin1 NOT NULL,
  `testcaseID` int(11) NOT NULL,
  PRIMARY KEY  (`waiverID`),
  UNIQUE KEY `testcaseID` (`testcaseID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=3 ;

-- --------------------------------------------------------

--
-- Table structure for table `waiver_testcase`
--

CREATE TABLE IF NOT EXISTS `waiver_testcase` (
  `waiver_tcID` int(11) NOT NULL auto_increment,
  `waiverID` int(11) NOT NULL default '0',
  `productID` int(11) NOT NULL default '0',
  `releaseID` int(11) NOT NULL default '0',
  `archID` int(11) default NULL,
  `matchtype` enum('no problem','problem') character set latin1 NOT NULL,
  PRIMARY KEY  (`waiver_tcID`),
  KEY `waiverID` (`waiverID`),
  KEY `archID` (`archID`),
  KEY `productID` (`productID`),
  KEY `releaseID` (`releaseID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=4 ;


--
-- Structure for view `bench_suites`
--
drop view if exists bench_suites;
DROP TABLE IF EXISTS `bench_suites`;
create view bench_suites as select distinct testsuiteID from tests where is_bench;


--
-- Structure for view `submissions_view`
--
drop view if exists submissions_view;
DROP TABLE IF EXISTS `submissions_view`;
create view submissions_view
        as select submissionID,submission_date,arch,product,`release`,active,related,host,tester,comment, configID
	from submissions join architectures using(archID) join products using(productID) join releases using(releaseID) join hosts using(hostID) join testers using(testerID);

--
-- Structure for view `bench_tcf_view`
--
drop view if exists bench_tcf_view;
DROP TABLE IF EXISTS `bench_tcf_view`;
create view bench_tcf_view
	as select submissionID,submission_date,arch,product,`release`,host,tester,testsuite,configID
	from submissions_view join tcf_group using(submissionID) join testsuites using(testsuiteID)
	where exists( select * from tests where testsuiteID=tcf_group.testsuiteID and is_bench );


--
-- Structure for view `rpms_view`
--
drop view if exists rpms_view;
DROP TABLE IF EXISTS `rpms_view`;
create view rpms_view
        as select rpmID,basename,version from rpms join rpm_basenames using(basenameID) join rpm_versions using(versionID);


drop table if exists tcf_view;
drop view if exists tcf_view;
create view tcf_view
        as select submissionID,submission_date,arch,product,`release`,host,tester,testsuite,configID
	from submissions_view join tcf_group using(submissionID) join testsuites using(testsuiteID);


--
-- Constraints for dumped tables
--

--
-- Constraints for table `bench_data`
--
ALTER TABLE `bench_data`
  ADD CONSTRAINT `bench_data_ibfk_1` FOREIGN KEY (`partID`) REFERENCES `bench_parts` (`partID`),
  ADD CONSTRAINT `bench_data_ibfk_2` FOREIGN KEY (`resultsID`) REFERENCES `results` (`resultsID`) ON DELETE CASCADE;

--
-- Constraints for table `board`
--
ALTER TABLE `board`
  ADD CONSTRAINT `board_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `testers` (`testerID`),
  ADD CONSTRAINT `board_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `testers` (`testerID`);

--
-- Constraints for table `board_last`
--
ALTER TABLE `board_last`
  ADD CONSTRAINT `board_last_ibfk_1` FOREIGN KEY (`testerID`) REFERENCES `testers` (`testerID`) ON DELETE CASCADE;

--
-- Constraints for table `kotd_testing`
--
ALTER TABLE `kotd_testing`
  ADD CONSTRAINT `kotd_testing_ibfk_1` FOREIGN KEY (`branchID`) REFERENCES `kernel_branches` (`branchID`),
  ADD CONSTRAINT `kotd_testing_ibfk_2` FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;

--
-- Constraints for table `maintenance_testing`
--
ALTER TABLE `maintenance_testing`
  ADD CONSTRAINT `maintenance_testing_ibfk_1` FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;

--
-- Constraints for table `product_testing`
--
ALTER TABLE `product_testing`
  ADD CONSTRAINT `product_testing_ibfk_1` FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;

--
-- Constraints for table `released_rpms`
--
ALTER TABLE `released_rpms`
  ADD CONSTRAINT `released_rpms_ibfk_1` FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE,
  ADD CONSTRAINT `released_rpms_ibfk_2` FOREIGN KEY (`basenameID`) REFERENCES `rpm_basenames` (`basenameID`),
  ADD CONSTRAINT `released_rpms_ibfk_3` FOREIGN KEY (`versionID`) REFERENCES `rpm_versions` (`versionID`);

--
-- Constraints for table `results`
--
ALTER TABLE `results`
  ADD CONSTRAINT `results_ibfk_1` FOREIGN KEY (`tcfID`) REFERENCES `tcf_group` (`tcfID`) ON DELETE CASCADE,
  ADD CONSTRAINT `results_ibfk_2` FOREIGN KEY (`testcaseID`) REFERENCES `testcases` (`testcaseID`);

--
-- Constraints for table `rpms`
--
ALTER TABLE `rpms`
  ADD CONSTRAINT `rpms_ibfk_1` FOREIGN KEY (`basenameID`) REFERENCES `rpm_basenames` (`basenameID`),
  ADD CONSTRAINT `rpms_ibfk_2` FOREIGN KEY (`versionID`) REFERENCES `rpm_versions` (`versionID`);

--
-- Constraints for table `softwareConfig`
--
ALTER TABLE `softwareConfig`
  ADD CONSTRAINT `softwareConfig_ibfk_1` FOREIGN KEY (`configID`) REFERENCES `rpmConfig` (`configID`) ON DELETE CASCADE,
  ADD CONSTRAINT `softwareConfig_ibfk_2` FOREIGN KEY (`rpmID`) REFERENCES `rpms` (`rpmID`) ON DELETE CASCADE;

--
-- Constraints for table `submissions`
--
ALTER TABLE `submissions`
  ADD CONSTRAINT `submissions_ibfk_1` FOREIGN KEY (`archID`) REFERENCES `architectures` (`archID`),
  ADD CONSTRAINT `submissions_ibfk_2` FOREIGN KEY (`productID`) REFERENCES `products` (`productID`),
  ADD CONSTRAINT `submissions_ibfk_3` FOREIGN KEY (`releaseID`) REFERENCES `releases` (`releaseID`),
  ADD CONSTRAINT `submissions_ibfk_4` FOREIGN KEY (`related`) REFERENCES `submissions` (`submissionID`) ON DELETE SET NULL,
  ADD CONSTRAINT `submissions_ibfk_5` FOREIGN KEY (`configID`) REFERENCES `rpmConfig` (`configID`),
  ADD CONSTRAINT `submissions_ibfk_6` FOREIGN KEY (`hostID`) REFERENCES `hosts` (`hostID`),
  ADD CONSTRAINT `submissions_ibfk_7` FOREIGN KEY (`testerID`) REFERENCES `testers` (`testerID`),
  ADD CONSTRAINT `submissions_ibfk_8` FOREIGN KEY (`hwinfoID`) REFERENCES `hwinfo` (`hwinfoID`);

--
-- Constraints for table `tcf_group`
--
ALTER TABLE `tcf_group`
  ADD CONSTRAINT `tcf_group_ibfk_1` FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE,
  ADD CONSTRAINT `tcf_group_ibfk_2` FOREIGN KEY (`testsuiteID`) REFERENCES `testsuites` (`testsuiteID`);

--
-- Constraints for table `tests`
--
ALTER TABLE `tests`
  ADD CONSTRAINT `tests_ibfk_1` FOREIGN KEY (`testsuiteID`) REFERENCES `testsuites` (`testsuiteID`),
  ADD CONSTRAINT `tests_ibfk_2` FOREIGN KEY (`testcaseID`) REFERENCES `testcases` (`testcaseID`);

--
-- Constraints for table `waiver_data`
--
ALTER TABLE `waiver_data`
  ADD CONSTRAINT `waiver_data_ibfk_1` FOREIGN KEY (`testcaseID`) REFERENCES `testcases` (`testcaseID`);

--
-- Constraints for table `waiver_testcase`
--
ALTER TABLE `waiver_testcase`
  ADD CONSTRAINT `waiver_testcase_ibfk_1` FOREIGN KEY (`archID`) REFERENCES `architectures` (`archID`),
  ADD CONSTRAINT `waiver_testcase_ibfk_2` FOREIGN KEY (`productID`) REFERENCES `products` (`productID`),
  ADD CONSTRAINT `waiver_testcase_ibfk_3` FOREIGN KEY (`releaseID`) REFERENCES `releases` (`releaseID`),
  ADD CONSTRAINT `waiver_testcase_ibfk_4` FOREIGN KEY (`waiverID`) REFERENCES `waiver_data` (`waiverID`) ON DELETE CASCADE;




--
-- DATA
--

-- phpMyAdmin SQL Dump
-- version 3.1.3.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 11, 2010 at 04:21 PM
-- Server version: 5.0.67
-- PHP Version: 5.2.5

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `qadb`
--

--
-- Dumping data for table `architectures`
--

INSERT INTO `architectures` (`archID`, `arch`) VALUES
(13, 'ec2-x86'),
(14, 'ec2-x86_64'),
(7, 'i586'),
(6, 'ia64'),
(5, 'ppc'),
(4, 'ppc64'),
(2, 's390'),
(1, 's390x'),
(3, 'x86_64'),
(8, 'xen0-i586'),
(11, 'xen0-x86_64'),
(12, 'xen0-x86_64-xenU-i586'),
(9, 'xenU-i586'),
(10, 'xenU-x86_64');

--
-- Dumping data for table `kernel_branches`
--

INSERT INTO `kernel_branches` (`branchID`, `branch`) VALUES
(1, 'HEAD'),
(2, 'SL100_BRANCH'),
(3, 'SL101_BRANCH'),
(4, 'SL93_BRANCH'),
(5, 'SLES10_GA_BRANCH'),
(6, 'SLES10_SP1_BRANCH'),
(11, 'SLES10_SP2_BRANCH'),
(7, 'SLES9_SP1_BRANCH'),
(8, 'SLES9_SP2_BRANCH'),
(9, 'SLES9_SP3_BRANCH'),
(10, 'SLES9_SP4_BRANCH');

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`productID`, `product`) VALUES
(22, 'openSUSE10.3'),
(21, 'openSUSE11.0'),
(12, 'SL10.1'),
(9, 'SL10.2'),
(14, 'SL10.3'),
(18, 'SL11.0'),
(25, 'SLED-10-SP1'),
(26, 'SLED-10-SP2'),
(16, 'SLERT-10'),
(20, 'SLERT-10-SP1'),
(19, 'SLERT-10-SP2'),
(29, 'SLERT-10-SP3'),
(7, 'SLES-10'),
(11, 'SLES-10-SP1'),
(17, 'SLES-10-SP2'),
(27, 'SLES-10-SP3'),
(24, 'SLES-11'),
(28, 'SLES-11-SP1'),
(8, 'SLES-8-SP4'),
(15, 'SLES-9'),
(23, 'SLES-9-NLD'),
(13, 'SLES-9-OES'),
(5, 'SLES-9-REFERENCE'),
(1, 'SLES-9-SP3'),
(2, 'SLES-9-SP4'),
(10, 'SLES8-SLEC');

--
-- Dumping data for table `releases`
--

INSERT INTO `releases` (`releaseID`, `release`) VALUES
(63, 'alpha0.1'),
(1, 'alpha1'),
(2, 'alpha2'),
(3, 'alpha3'),
(4, 'alpha4'),
(5, 'alpha5'),
(21, 'beta1'),
(30, 'beta10'),
(22, 'beta2'),
(23, 'beta3'),
(24, 'beta4'),
(25, 'beta5'),
(26, 'beta6'),
(27, 'beta7'),
(28, 'beta8'),
(29, 'beta9'),
(61, 'GA'),
(67, 'GM'),
(65, 'GMC'),
(66, 'internal'),
(62, 'maintained'),
(41, 'RC1'),
(42, 'RC2'),
(43, 'RC3'),
(44, 'RC4'),
(45, 'RC5'),
(46, 'RC6'),
(81, 'SP1'),
(79, 'SP1_beta3'),
(85, 'SP2'),
(83, 'SP3');

--
-- Dumping data for table `script_versions`
--

INSERT INTO `script_versions` (`versionID`, `script_name`, `latest_major`, `latest_minor`, `minimal_major`, `minimal_minor`) VALUES
(1, 'qa_db_report.pl', 1, 0, 1, 0),
(2, 'remote_qa_db_report.pl', 0, 1, NULL, NULL);

--
-- Dumping data for table `table_desc`
--

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

-- Create table schema and add version 000000000000 into it.
-- this table is needed to tell the update_db.sh script which
-- version the DB's schema is
-- version is in fact a datetime so it's known in which order patches
-- need to be applied
-- version format: YYYYMMDDhhmm

CREATE TABLE `qadb`.`schema` (
  `version` CHAR(12)  NOT NULL,
  PRIMARY KEY (`version`)
)
ENGINE = InnoDB
CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- create default user
GRANT SELECT ON qadb.* to qadb_guest@localhost;
FLUSH PRIVILEGES;

insert into qadb.schema (version) values ('000000000000');

