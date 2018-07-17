ALTER TABLE released_rpms DROP FOREIGN KEY released_rpms_ibfk_3;
ALTER TABLE released_rpms ADD CONSTRAINT fk_released_rpms_versionID_rpm_versions_versionID FOREIGN KEY (`versionID`) REFERENCES `rpm_versions` (`versionID`);
