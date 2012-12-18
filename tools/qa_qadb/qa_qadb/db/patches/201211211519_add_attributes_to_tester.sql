ALTER TABLE `tester`
	MODIFY `tester` varchar(50) NOT NULL COMMENT 'Testers login',
	ADD COLUMN `ext_ident` varchar(255) COMMENT 'External identifier',
	ADD COLUMN `name` varchar(100) COMMENT 'Name of the tester',
	ADD COLUMN `email` varchar(80) COMMENT 'Email contact',
	ADD COLUMN `password` varchar(60) COMMENT 'Testers password';
