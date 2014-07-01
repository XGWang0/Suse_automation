CREATE TABLE IF NOT EXISTS `job_part` (
       `job_part_id` int not null auto_increment primary key,
       `job_id` int not null,
       CONSTRAINT `fk_job_part_job` FOREIGN KEY (`job_id`) REFERENCES `job` (`job_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `job_part_on_machine` (
	`job_part_on_machine_id` int not null auto_increment primary key,
	`job_part_id` int not null,
	`job_status_id` tinyint(4) not null,
	`job_on_machine_id` int not null,
    `xml_file` varchar(255) not null,
	`start` timestamp,
	`stop` timestamp,
	`config_id` int  not null,
	`does_reboot` tinyint not null default 0,
	CONSTRAINT `fk_job_part_on_machine_job_part` FOREIGN KEY (`job_part_id`) REFERENCES `job_part` (`job_part_id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_job_part_on_machine_job_status` FOREIGN KEY (`job_status_id`) REFERENCES `job_status` (`job_status_id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_job_part_on_machine_job_on_machine` FOREIGN KEY (`job_on_machine_id`) REFERENCES `job_on_machine` (`job_on_machine_id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_job_part_on_machine_config` FOREIGN KEY (`config_id`) REFERENCES `config` (`config_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mm_role` (
       `mm_role_id` int not null auto_increment primary key,
       `mm_role` varchar(255) not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Alter related table
ALTER TABLE `job_on_machine` 
	ADD COLUMN `mm_role_id` INT NOT NULL,
	ADD CONSTRAINT `fk_job_on_machine_mm_role` FOREIGN KEY (`mm_role_id`) REFERENCES `mm_role` (`mm_role_id`) ON DELETE RESTRICT,
	DROP FOREIGN KEY `fk_job_on_machine_config_id_config_config_id`,
	DROP COLUMN `config_id`,
	DROP COLUMN `start`,
	DROP COLUMN `stop`,
	DROP COLUMN `last_log`,
	DROP COLUMN `timestamp`,
	DROP COLUMN `return_status`,
	DROP COLUMN `return_xml`;

ALTER TABLE `log`
	DROP FOREIGN KEY `log_ibfk_2`,
	DROP COLUMN `job_on_machine_id`,
	ADD COLUMN `job_part_on_machine_id` INT NOT NULL,
	ADD CONSTRAINT `fk_log_job_part_on_machine` FOREIGN KEY (`job_part_on_machine_id`) references `job_part_on_machine` (`job_part_on_machine_id`) ON DELETE RESTRICT;

ALTER TABLE `job`
	MODIFY COLUMN `job_owner` INT NOT NULL,
	ADD CONSTRAINT `fk_job_user` FOREIGN KEY (`job_owner`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT,
	DROP COLUMN `slave_directory`;

