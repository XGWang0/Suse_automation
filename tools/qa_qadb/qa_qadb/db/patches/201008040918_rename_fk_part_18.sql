ALTER TABLE submissions DROP FOREIGN KEY submissions_ibfk_5;
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_productID_products_productID FOREIGN KEY (`productID`) REFERENCES `products` (`productID`);
