ALTER TABLE machine MODIFY COLUMN usedby int NULL;

ALTER TABLE machine ADD CONSTRAINT `fk_machine_usedby_user_user_id` FOREIGN KEY (`usedby`) REFERENCES `user` (`user_id`);
