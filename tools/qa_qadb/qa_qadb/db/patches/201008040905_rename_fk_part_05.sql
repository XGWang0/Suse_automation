ALTER TABLE board_last DROP FOREIGN KEY board_last_ibfk_1;
ALTER TABLE board_last ADD CONSTRAINT fk_board_last_testerID_testers_testerID FOREIGN KEY (`testerID`) REFERENCES `testers` (`testerID`) ON DELETE CASCADE;
