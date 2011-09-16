ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_6;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_releaseID_releases_releaseID FOREIGN KEY (`releaseID`) REFERENCES `releases` (`releaseID`);
