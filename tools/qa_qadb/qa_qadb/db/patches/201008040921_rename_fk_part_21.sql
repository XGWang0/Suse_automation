ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_2;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_configID_rpmConfig_configID FOREIGN KEY (`configID`) REFERENCES `rpmConfig` (`configID`);
