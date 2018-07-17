CREATE TABLE qaconf_key	(
	qaconf_key_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	qaconf_key VARCHAR(100) NOT NULL COMMENT 'QA config key',
	qaconf_key_desc VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Description of the key and / or value',
	UNIQUE(qaconf_key)
) ENGINE InnoDB DEFAULT CHARSET=utf8 COMMENT 'QA Configuration keys';

CREATE TABLE qaconf	(
	qaconf_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`desc` VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Description of the configuration',
	UNIQUE(`desc`)
) ENGINE InnoDB DEFAULT CHARSET=utf8 COMMENT 'Different QA configuration entities';

CREATE TABLE qaconf_row	(
	qaconf_row_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	qaconf_id INT NOT NULL COMMENT 'The configuration ID',
	qaconf_key_id INT NOT NULL COMMENT 'QA config key',
	val VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'QA config value',
	cmt VARCHAR(255) NULL COMMENT 'row comment',
	FOREIGN KEY fk_qaconf_row_qaconf(qaconf_id) REFERENCES qaconf(qaconf_id) ON DELETE CASCADE,
	FOREIGN KEY fk_qaconf_row_qaconf_key(qaconf_key_id) REFERENCES qaconf_key(qaconf_key_id) ON DELETE RESTRICT,
	INDEX(qaconf_id,qaconf_key_id)
) ENGINE InnoDB DEFAULT CHARSET=utf8 COMMENT 'Rows of QA configurations';

ALTER TABLE machine ADD COLUMN qaconf_id INT NULL COMMENT 'QA config';
ALTER TABLE machine ADD CONSTRAINT fk_machine_qaconf FOREIGN KEY(qaconf_id) REFERENCES qaconf(qaconf_id) ON DELETE RESTRICT;
ALTER TABLE `group` ADD COLUMN qaconf_id INT NULL COMMENT 'QA config';
ALTER TABLE `group` ADD CONSTRAINT fk_group_qaconf FOREIGN KEY(qaconf_id) REFERENCES qaconf(qaconf_id) ON DELETE RESTRICT;

INSERT INTO qaconf(`desc`) VALUES('global');
UPDATE qaconf SET qaconf_id=0 WHERE `desc`='global';
INSERT INTO qaconf(qaconf_id,`desc`) VALUES (1,'country global'),(2,'site global');

