UPDATE maintenance_testing SET status=0 WHERE status IS NULL;
CREATE TABLE status (
	status_id INT PRIMARY KEY AUTO_INCREMENT,
	status VARCHAR(50) NOT NULL,
	UNIQUE(status)
) ENGINE InnoDB;
INSERT INTO status VALUES (1,'wip'),(2,'rejected'),(3,'approved'),(4,'invalid');
ALTER TABLE submission ADD COLUMN status_id INT NULL;
ALTER TABLE submission ADD CONSTRAINT fk_submission_status FOREIGN KEY(status_id) REFERENCES status(status_id) ON DELETE RESTRICT;
UPDATE submission,maintenance_testing SET submission.status_id=maintenance_testing.status WHERE submission.submission_id=maintenance_testing.submission_id;
ALTER TABLE maintenance_testing DROP COLUMN status;
