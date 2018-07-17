ALTER TABLE waiver_testcase DROP FOREIGN KEY waiver_testcase_ibfk_2;
ALTER TABLE waiver_testcase ADD CONSTRAINT fk_waiver_testcase_productID_products_productID FOREIGN KEY (`productID`) REFERENCES `products` (`productID`);
