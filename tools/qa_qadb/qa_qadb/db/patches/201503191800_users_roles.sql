-- some users may be admins
ALTER TABLE `tester` ADD COLUMN is_admin tinyint NOT NULL DEFAULT 0;

-- confirmed users are able to do updates
-- existing users are confirmed
-- new users need confirming by admin
ALTER TABLE `tester` ADD COLUMN is_confirmed tinyint NOT NULL DEFAULT 0;
UPDATE `tester` SET is_confirmed=1;

-- password was never used and never will be
ALTER TABLE `tester` DROP COLUMN password;

-- we need to search by ext_ident, plus it must be unique
ALTER TABLE `tester` ADD UNIQUE(ext_ident);

-- clean up unused tables
DROP TABLE IF EXISTS `tester_role`;
DROP TABLE IF EXISTS `role`;

