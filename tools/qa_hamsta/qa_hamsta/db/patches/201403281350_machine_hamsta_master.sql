CREATE TABLE hamsta_master (
  hamsta_master_id int not null auto_increment primary key,
  hamsta_master_name varchar(255) not null,
  hamsta_master_ip varchar(16) not null,
  unique(hamsta_master_ip)
) ENGINE=InnoDB; 

ALTER TABLE `machine` ADD COLUMN hamsta_master_id int after `machine_status_id`;
ALTER TABLE `machine` ADD CONSTRAINT `fk_machine_hamsta_master_id` FOREIGN KEY(`hamsta_master_id`) REFERENCES `hamsta_master`(`hamsta_master_id`) ON DELETE RESTRICT;

