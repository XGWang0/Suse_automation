ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_4;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_hostID_hosts_hostID FOREIGN KEY (`hostID`) REFERENCES `hosts` (`hostID`);
