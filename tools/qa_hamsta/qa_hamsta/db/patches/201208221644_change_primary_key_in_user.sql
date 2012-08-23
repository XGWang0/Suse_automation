
ALTER TABLE `user_in_role` DROP FOREIGN KEY `fk_user_in_role_user_id`;

ALTER TABLE `user_in_role` MODIFY COLUMN `user_id` integer NOT NULL;

ALTER TABLE `user` DROP PRIMARY KEY;
ALTER TABLE `user` CHANGE COLUMN `id` `user_login` varchar(255) NOT NULL UNIQUE;
ALTER TABLE `user` ADD COLUMN `user_id` integer PRIMARY KEY AUTO_INCREMENT FIRST;

ALTER TABLE `user_in_role` ADD FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT;
