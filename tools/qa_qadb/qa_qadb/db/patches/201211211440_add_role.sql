CREATE TABLE `role` (
	`role_id` int(11) AUTO_INCREMENT PRIMARY KEY COMMENT 'Role identifier',
	`role` varchar(50) NOT NULL collate utf8_unicode_ci COMMENT 'Diplayed name of the user role',
	`description` varchar(255) DEFAULT NULL COMMENT 'More information about the role',
	UNIQUE KEY `role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='List of user roles';
