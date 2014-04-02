use hamsta_db;

drop table job_on_machine_part;
drop table job_part;

CREATE TABLE job_part	(
	job_part_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	job_id INT NOT NULL,
	started TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT cons_job_part_jobid FOREIGN KEY(job_id) REFERENCES job(job_id) ON DELETE CASCADE
) ENGINE InnoDB DEFAULT CHARSET='utf8';


CREATE TABLE job_on_machine_part (
	job_on_machine_part_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	job_on_machine_id INT NOT NULL,
	job_part_id INT NOT NULL,
	job_status_id TINYINT NOT NULL,
	`start` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`stop` TIMESTAMP NULL,
	CONSTRAINT fk_job_on_machine_part_statusid FOREIGN KEY(job_status_id) REFERENCES job_status(job_status_id) ON DELETE CASCADE,
	CONSTRAINT fk_job_on_machine_part_partid FOREIGN KEY(job_part_id) REFERENCES job_part(job_part_id) ON DELETE CASCADE

) ENGINE InnoDB DEFAULT CHARSET='utf8';

