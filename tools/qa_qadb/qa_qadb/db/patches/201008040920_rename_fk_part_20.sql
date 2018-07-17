ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_8;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_related_submissions_submissionID FOREIGN KEY (`related`) REFERENCES `submissions` (`submissionID`) ON DELETE SET NULL;
