ALTER TABLE waiver_testcase DROP FOREIGN KEY waiver_testcase_ibfk_4;
ALTER TABLE waiver_testcase ADD CONSTRAINT fk_waiver_testcase_waiverID_waiver_data_waiverID FOREIGN KEY (`waiverID`) REFERENCES `waiver_data` (`waiverID`) ON DELETE CASCADE;
