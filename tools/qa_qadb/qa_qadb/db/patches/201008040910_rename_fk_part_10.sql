ALTER TABLE released_rpms DROP FOREIGN KEY released_rpms_ibfk_2;
ALTER TABLE released_rpms ADD CONSTRAINT fk_released_rpms_submissionID_submissions_submissionID FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;
