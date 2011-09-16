ALTER TABLE product_testing DROP FOREIGN KEY product_testing_ibfk_1;
ALTER TABLE product_testing ADD CONSTRAINT fk_product_testing_submissionID_submissions_submissionID FOREIGN KEY (`submissionID`) REFERENCES `submissions` (`submissionID`) ON DELETE CASCADE;
