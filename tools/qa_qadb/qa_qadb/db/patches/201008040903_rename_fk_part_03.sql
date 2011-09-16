ALTER TABLE board DROP FOREIGN KEY board_ibfk_1;
ALTER TABLE board ADD CONSTRAINT fk_board_created_by_testers_testerID FOREIGN KEY (`created_by`) REFERENCES `testers` (`testerID`);
