ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_7;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_hwinfoID_hwinfo_hwinfoID FOREIGN KEY (`hwinfoID`) REFERENCES `hwinfo` (`hwinfoID`);
