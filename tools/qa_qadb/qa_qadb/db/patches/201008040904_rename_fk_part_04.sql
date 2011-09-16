ALTER TABLE board DROP FOREIGN KEY board_ibfk_2;
ALTER TABLE board ADD CONSTRAINT fk_board_updated_by_testers_testerID FOREIGN KEY (`updated_by`) REFERENCES `testers` (`testerID`);
