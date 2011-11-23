ALTER TABLE `machine` ADD COLUMN cpu_nr INT AFTER `kernel`;
ALTER TABLE `machine` ADD INDEX(cpu_nr);

CREATE TABLE cpu_vendor ( cpu_vendor_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, cpu_vendor VARCHAR(255) ) engine InnoDB;
ALTER TABLE `machine` ADD COLUMN cpu_vendor_id INT AFTER `cpu_nr`;
ALTER TABLE `machine` ADD CONSTRAINT `fk_machine_cpu_vendor` FOREIGN KEY(`cpu_vendor_id`) REFERENCES `cpu_vendor`(`cpu_vendor_id`) ON DELETE RESTRICT;

ALTER TABLE `machine` ADD COLUMN memsize VARCHAR(256) NOT NULL DEFAULT '' AFTER `cpu_vendor_id`;
ALTER TABLE `machine` ADD INDEX(memsize);

ALTER TABLE `machine` ADD COLUMN disksize VARCHAR(256) NOT NULL DEFAULT '' AFTER `memsize`;
ALTER TABLE `machine` ADD INDEX(disksize);
