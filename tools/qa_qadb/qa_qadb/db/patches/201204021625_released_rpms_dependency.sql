DELETE FROM released_rpm WHERE NOT EXISTS ( SELECT * FROM maintenance_testing WHERE released_rpm.submission_id=maintenance_testing.submission_id);
ALTER TABLE released_rpm ADD COLUMN maintenance_testing_id INT NOT NULL;
UPDATE released_rpm,maintenance_testing SET released_rpm.maintenance_testing_id=maintenance_testing.maintenance_testing_id WHERE released_rpm.submission_id=maintenance_testing.submission_id;
ALTER TABLE released_rpm DROP FOREIGN KEY fk_released_rpm_submission, DROP INDEX submissionID, DROP COLUMN submission_id, ADD INDEX(maintenance_testing_id,rpm_basename_id), ADD CONSTRAINT fk_released_rpm_maintenance_testing FOREIGN KEY(maintenance_testing_id) REFERENCES maintenance_testing(maintenance_testing_id) ON DELETE CASCADE;
