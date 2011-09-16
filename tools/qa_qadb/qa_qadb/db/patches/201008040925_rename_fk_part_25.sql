ALTER TABLE tcf_group DROP FOREIGN KEY tcf_group_ibfk_1;
ALTER TABLE tcf_group ADD CONSTRAINT fk_tcf_group_submissionID_submissions_submissionID FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;
