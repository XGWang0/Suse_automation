ALTER TABLE submission ADD COLUMN build_nr INT NULL;
ALTER TABLE submission ADD INDEX(build_nr);

CREATE TABLE build_promoted (
  build_promoted_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  arch_id INT NOT NULL,
  build_nr INT NOT NULL,
  product_id INT NOT NULL,
  release_id INT NOT NULL,
  UNIQUE(product_id,arch_id,build_nr),
  CONSTRAINT fk_build_promoted_arch FOREIGN KEY(arch_id) REFERENCES
arch(arch_id),
  CONSTRAINT fk_build_promoted_product FOREIGN KEY(product_id) REFERENCES
product(product_id),
  CONSTRAINT fk_build_promoted_release FOREIGN KEY(release_id) REFERENCES `release`(release_id)
) ENGINE InnoDB;
