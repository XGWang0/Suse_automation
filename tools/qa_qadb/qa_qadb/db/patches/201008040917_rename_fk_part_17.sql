ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_1;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_archID_architectures_archID FOREIGN KEY (`archID`) REFERENCES `architectures` (`archID`);
