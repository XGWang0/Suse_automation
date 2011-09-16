ALTER TABLE waiver_testcase DROP FOREIGN KEY waiver_testcase_ibfk_1;
ALTER TABLE waiver_testcase ADD CONSTRAINT fk_waiver_testcase_archID_architectures_archID FOREIGN KEY (`archID`) REFERENCES `architectures` (`archID`);
