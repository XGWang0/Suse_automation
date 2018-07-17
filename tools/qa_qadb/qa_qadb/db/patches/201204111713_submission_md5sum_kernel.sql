CREATE TABLE kernel_version (
	kernel_version_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	kernel_version VARCHAR(64) COMMENT 'kernel version number(s)',
	UNIQUE(kernel_version)
) ENGINE InnoDB COMMENT 'List of kernel version number(s)';

INSERT INTO kernel_version(kernel_version) SELECT DISTINCT version FROM kotd_testing;

ALTER TABLE submission
	ADD COLUMN md5sum VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'md5sum of kernel GIT submission or maintenance patch',
	ADD COLUMN kernel_version_id INT NULL COMMENT 'kernel version number(s)';

UPDATE submission,kotd_testing,kernel_version 
	SET submission.md5sum=kotd_testing.`release`, submission.kernel_version_id=kernel_version.kernel_version_id 
	WHERE submission.submission_id=kotd_testing.submission_id AND kernel_version.kernel_version=kotd_testing.version;

UPDATE submission,maintenance_testing SET submission.md5sum=maintenance_testing.md5sum WHERE submission.submission_id=maintenance_testing.submission_id;

ALTER TABLE submission ADD CONSTRAINT fk_submission_kernel_version FOREIGN KEY(kernel_version_id) REFERENCES kernel_version(kernel_version_id) ON DELETE RESTRICT;

ALTER TABLE kotd_testing DROP COLUMN `release`, DROP COLUMN version;
ALTER TABLE maintenance_testing DROP COLUMN md5sum;

ALTER TABLE submission
	ADD COLUMN kernel_branch_id INT NULL COMMENT 'kernel GIT branch',
	ADD COLUMN kernel_flavor_id INT NULL COMMENT 'kernel flavor',
	ADD COLUMN patch_id VARCHAR(50) NOT NULL DEFAULT '' COMMENT 'maintenance patch ID';

UPDATE submission,kotd_testing 
	SET submission.kernel_branch_id=kotd_testing.kernel_branch_id, submission.kernel_flavor_id=kotd_testing.kernel_flavor_id
	WHERE submission.submission_id=kotd_testing.submission_id;

UPDATE submission,maintenance_testing
	SET submission.patch_id=maintenance_testing.patch_id
	WHERE submission.submission_id=maintenance_testing.submission_id;

ALTER TABLE submission 
	ADD CONSTRAINT fk_submission_kernel_branch FOREIGN KEY(kernel_branch_id) REFERENCES kernel_branch(kernel_branch_id) ON DELETE RESTRICT,
	ADD CONSTRAINT fk_submission_kernel_flavor FOREIGN KEY(kernel_flavor_id) REFERENCES kernel_flavor(kernel_flavor_id) ON DELETE RESTRICT;

ALTER TABLE released_rpm ADD COLUMN submission_id INT NOT NULL;
UPDATE released_rpm,maintenance_testing
	SET released_rpm.submission_id=maintenance_testing.submission_id
	WHERE released_rpm.maintenance_testing_id=maintenance_testing.maintenance_testing_id;
ALTER TABLE released_rpm ADD CONSTRAINT fk_released_rpm_submission FOREIGN KEY(submission_id) REFERENCES submission(submission_id) ON DELETE RESTRICT;
ALTER TABLE released_rpm DROP FOREIGN KEY fk_released_rpm_maintenance_testing;
ALTER TABLE released_rpm DROP COLUMN maintenance_testing_id;

DROP TABLE maintenance_testing;
DROP TABLE kotd_testing;
DROP TABLE product_testing;