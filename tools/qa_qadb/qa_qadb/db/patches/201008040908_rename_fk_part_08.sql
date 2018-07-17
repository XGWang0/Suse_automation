ALTER TABLE maintenance_testing DROP FOREIGN KEY maintenance_testing_ibfk_1;
ALTER TABLE maintenance_testing ADD CONSTRAINT fk_maintenance_testing_submissionID_submissions_submissionID FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;
