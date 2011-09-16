ALTER TABLE waiver_testcase DROP FOREIGN KEY waiver_testcase_ibfk_3;
ALTER TABLE waiver_testcase ADD CONSTRAINT fk_waiver_testcase_releaseID_releases_releaseID FOREIGN KEY (`releaseID`) REFERENCES `releases` (`releaseID`);
