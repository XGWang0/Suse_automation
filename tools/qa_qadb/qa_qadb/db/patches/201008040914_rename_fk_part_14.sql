ALTER TABLE rpms DROP FOREIGN KEY rpms_ibfk_2;
ALTER TABLE rpms ADD CONSTRAINT fk_rpms_versionID_rpm_versions_versionID FOREIGN KEY (`versionID`) REFERENCES `rpm_versions` (`versionID`);
