CREATE TABLE IF NOT EXISTS `job_part` (
    `job_part_id` int not null auto_increment primary key,
    `job_id` int not null,
    CONSTRAINT `fk_job_part_job` FOREIGN KEY (`job_id`) REFERENCES `job` (`job_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
CREATE TABLE IF NOT EXISTS `job_part_on_machine` (
    `job_part_on_machine_id` int not null auto_increment primary key,
    `job_part_id` int not null,
    `job_status_id` tinyint(4) not null,
    `job_on_machine_id` int not null,
    `xml_file` varchar(255) not null,
    `start` datetime default null,
    `stop` datetime default null,
    `timeslots` int not null default 1,
    `does_reboot` tinyint not null default 0,
    CONSTRAINT `fk_job_part_on_machine_job_part` FOREIGN KEY (`job_part_id`) REFERENCES `job_part` (`job_part_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_job_part_on_machine_job_status` FOREIGN KEY (`job_status_id`) REFERENCES `job_status` (`job_status_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_job_part_on_machine_job_on_machine` FOREIGN KEY (`job_on_machine_id`) REFERENCES `job_on_machine` (`job_on_machine_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
CREATE TABLE IF NOT EXISTS `mm_role` (
    `mm_role_id` int not null auto_increment primary key,
    `mm_role` varchar(255) not null
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Insert `default` role into mm_role for non-mm jobs
INSERT INTO `mm_role`(`mm_role`) VALUES ('default');


-- Data migration and modification of related tables

-- Fill table job_part and job_part_on_machine for existing jobs
INSERT INTO `job_part` (job_id) SELECT job_id FROM `job` ORDER BY job_id ASC;
INSERT INTO `job_part_on_machine` (job_part_id , job_status_id, job_on_machine_id, start, stop, xml_file) SELECT jp.job_part_id, jom.job_status_id, jom.job_on_machine_id, jom.start, jom.stop, job.xml_file FROM job_part jp INNER JOIN job_on_machine jom ON (jp.job_id = jom.job_id) INNER JOIN job ON (jom.job_id = job.job_id);

-- Change table log
ALTER TABLE `log` ADD COLUMN `job_part_on_machine_id` INT;
UPDATE `log` SET job_part_on_machine_id = (SELECT job_part_on_machine_id from `job_part_on_machine` jpm WHERE `log`.job_on_machine_id = jpm.job_on_machine_id);

-- DROP fk job_on_machine_id bnc#905242
SELECT CONCAT('ALTER TABLE log DROP FOREIGN KEY ',constraint_name,'') INTO @sqlst
FROM information_schema.key_column_usage where table_name='log' and column_name='job_on_machine_id';
PREPARE stmt FROM @sqlst;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sqlstr = NULL;

ALTER TABLE `log` 
    DROP COLUMN `job_on_machine_id`, 
    ADD CONSTRAINT `fk_log_job_part_on_machine` FOREIGN KEY (`job_part_on_machine_id`) references `job_part_on_machine` (`job_part_on_machine_id`) ON DELETE CASCADE;

-- Change table job
ALTER TABLE `job`
    ADD COLUMN `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DROP COLUMN `slave_directory`;
UPDATE `job` SET `created` = (SELECT `timestamp` from `job_on_machine` WHERE `job`.job_id = `job_on_machine`.job_id);

-- Migrate data for job.job_owner
ALTER TABLE `job`
    MODIFY COLUMN `job_owner` varchar(255);
UPDATE `job` set `job_owner` = '' where `job_owner` not like "%@%";
UPDATE `job` set `job_owner` = (SELECT `user_id` from `user` where `user`.`email` is not null and `user`.`email` != '' and `user`.`email` = `job`.`job_owner` LIMIT 1);

-- Use a default user for jobs that has no owner set
INSERT INTO `user`(extern_id, login, name, email, password) VALUES ('DEFAULT_USER', 'default_user', 'Default user for jobs without owner set', '', '');
UPDATE `job` SET `job_owner` = (SELECT `user_id` from `user` WHERE `extern_id` = 'DEFAULT_USER' and `login` = 'default_user') WHERE job_owner = '' or job_owner is null;

-- Rename job.job_owner to job.user_id and add foreign key to user.user_id
ALTER TABLE `job`
    CHANGE COLUMN `job_owner` `user_id` INT NOT NULL,
    ADD CONSTRAINT `fk_job_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE;

-- Change table job_on_machine;
ALTER TABLE `job_on_machine` 
    ADD COLUMN `mm_role_id` INT NOT NULL DEFAULT '1',
    ADD CONSTRAINT `fk_job_on_machine_mm_role` FOREIGN KEY (`mm_role_id`) REFERENCES `mm_role` (`mm_role_id`) ON DELETE CASCADE,
    DROP COLUMN `start`,
    DROP COLUMN `stop`,
    DROP COLUMN `last_log`,
    DROP COLUMN `timestamp`,
    DROP COLUMN `return_status`,
    DROP COLUMN `return_xml`;


