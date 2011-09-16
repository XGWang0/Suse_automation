ALTER TABLE rpms DROP FOREIGN KEY rpms_ibfk_1;
ALTER TABLE rpms ADD CONSTRAINT fk_rpms_basenameID_rpm_basenames_basenameID FOREIGN KEY (`basenameID`) REFERENCES `rpm_basenames` (`basenameID`);
