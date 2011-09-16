ALTER TABLE tests DROP FOREIGN KEY tests_ibfk_1;
ALTER TABLE tests ADD CONSTRAINT fk_tests_testcaseID_testcases_testcaseID FOREIGN KEY (`testcaseID`) REFERENCES `testcases` (`testcaseID`);
