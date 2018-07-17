CREATE TABLE kernel_flavors (
	flavorID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	flavor VARCHAR(64) NOT NULL DEFAULT ''
) ENGINE=InnoDB;

ALTER TABLE kotd_testing ADD COLUMN flavorID INT NULL;
ALTER TABLE kotd_testing ADD CONSTRAINT fk_kotd_testing_kernel_flavors FOREIGN KEY(flavorID) REFERENCES kernel_flavors(flavorID) ON DELETE RESTRICT;

