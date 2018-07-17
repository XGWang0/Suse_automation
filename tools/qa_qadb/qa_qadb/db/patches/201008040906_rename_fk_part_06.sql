ALTER TABLE kotd_testing DROP FOREIGN KEY kotd_testing_ibfk_1;
ALTER TABLE kotd_testing ADD CONSTRAINT fk_kotd_testing_branchID_kernel_branches_branchID FOREIGN KEY (`branchID`) REFERENCES `kernel_branches` (`branchID`);
