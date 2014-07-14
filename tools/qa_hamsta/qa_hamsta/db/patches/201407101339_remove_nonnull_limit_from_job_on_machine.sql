-- On sle12, mariadb requirement
alter table `job_on_machine` modify column `return_xml` varchar(255);
alter table `job_on_machine` modify column `return_status` varchar(255);
alter table `job_on_machine` modify column `last_log` text;
