ALTER TABLE results DROP FOREIGN KEY results_ibfk_2;
ALTER TABLE results ADD CONSTRAINT fk_results_testcaseID_testcases_testcaseID FOREIGN KEY (`testcaseID`) REFERENCES `testcases` (`testcaseID`);
