CREATE TABLE reference_host (
	reference_host_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	host_id INT NOT NULL,
	arch_id INT NOT NULL,
	product_id INT NOT NULL,
	UNIQUE(host_id, arch_id, product_id)
) ENGINE InnoDB;
ALTER TABLE reference_host ADD CONSTRAINT fk_reference_host_host FOREIGN KEY(host_id) REFERENCES host(host_id) ON DELETE CASCADE;
ALTER TABLE reference_host ADD CONSTRAINT fk_reference_host_arch FOREIGN KEY(arch_id) REFERENCES arch(arch_id) ON DELETE RESTRICT;
ALTER TABLE reference_host ADD CONSTRAINT fk_reference_host_product FOREIGN KEY(product_id) REFERENCES product(product_id) ON DELETE RESTRICT;
ALTER TABLE submission ADD INDEX(host_id, arch_id, product_id);
ALTER TABLE submission DROP INDEX hostID;

ALTER TABLE submission ADD COLUMN ref CHAR(1) NOT NULL DEFAULT '';
ALTER TABLE submission ADD INDEX(ref);
