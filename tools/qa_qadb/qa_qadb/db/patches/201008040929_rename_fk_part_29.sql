ALTER TABLE waiver_data DROP FOREIGN KEY waiver_data_ibfk_1;
ALTER TABLE waiver_data ADD CONSTRAINT fk_waiver_data_testcaseID_testcases_testcaseID FOREIGN KEY (`testcaseID`) REFERENCES `testcases` (`testcaseID`);
