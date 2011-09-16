ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_3;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_testerID_testers_testerID FOREIGN KEY (`testerID`) REFERENCES `testers` (`testerID`);
