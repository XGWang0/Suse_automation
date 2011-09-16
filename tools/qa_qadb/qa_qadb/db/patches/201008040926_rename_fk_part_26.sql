ALTER TABLE tcf_group DROP FOREIGN KEY tcf_group_ibfk_2;
ALTER TABLE tcf_group ADD CONSTRAINT fk_tcf_group_testsuiteID_testsuites_testsuiteID FOREIGN KEY (`testsuiteID`) REFERENCES `testsuites` (`testsuiteID`);
