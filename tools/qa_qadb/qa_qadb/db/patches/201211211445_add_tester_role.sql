CREATE TABLE `tester_role` (
	`tester_id` int(11) NOT NULL COMMENT 'Tester reference',
	`role_id` int(11) NOT NULL COMMENT 'Role reference',
	PRIMARY KEY  (`tester_id`, `role_id`),
	CONSTRAINT `fk_tester_role_tester_tester_id` FOREIGN KEY (`tester_id`) REFERENCES `tester` (`tester_id`) ON DELETE CASCADE,
	CONSTRAINT `fk_tester_role_role_role_id` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET=utf8 COLLATE=utf8_unicode_ci COMMENT='Connects roles to testers';
