ALTER TABLE released_rpms DROP FOREIGN KEY released_rpms_ibfk_1;
ALTER TABLE released_rpms ADD CONSTRAINT fk_released_rpms_basenameID_rpm_basenames_basenameID FOREIGN KEY (`basenameID`) REFERENCES `rpm_basenames` (`basenameID`);
