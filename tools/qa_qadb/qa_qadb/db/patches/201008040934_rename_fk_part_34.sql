ALTER TABLE results DROP FOREIGN KEY results_ibfk_1;
ALTER TABLE results ADD CONSTRAINT fk_results_tcfID_tcf_group_tcfID FOREIGN KEY (`tcfID`) REFERENCES `tcf_group` (`tcfID`) ON DELETE CASCADE;
