ALTER TABLE softwareConfig DROP FOREIGN KEY softwareConfig_ibfk_2;
ALTER TABLE softwareConfig ADD CONSTRAINT fk_softwareConfig_rpmID_rpms_rpmID FOREIGN KEY (`rpmID`) REFERENCES `rpms` (`rpmID`) ON DELETE CASCADE;
