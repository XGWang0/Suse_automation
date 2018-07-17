ALTER TABLE kotd_testing DROP FOREIGN KEY kotd_testing_ibfk_2;
ALTER TABLE kotd_testing ADD CONSTRAINT fk_kotd_testing_submissionID_submissions_submissionID FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;
