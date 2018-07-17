ALTER TABLE softwareConfig DROP FOREIGN KEY softwareConfig_ibfk_1;
ALTER TABLE softwareConfig ADD CONSTRAINT fk_softwareConfig_configID_rpmConfig_configID FOREIGN KEY (`configID`) REFERENCES `rpmConfig` (`configID`) ON DELETE CASCADE;
