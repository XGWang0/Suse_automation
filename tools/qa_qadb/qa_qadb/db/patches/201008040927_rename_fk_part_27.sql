ALTER TABLE tests DROP FOREIGN KEY tests_ibfk_2;
ALTER TABLE tests ADD CONSTRAINT fk_tests_testsuiteID_testsuites_testsuiteID FOREIGN KEY (`testsuiteID`) REFERENCES `testsuites` (`testsuiteID`);
