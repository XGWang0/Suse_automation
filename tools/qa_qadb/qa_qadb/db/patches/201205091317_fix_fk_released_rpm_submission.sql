ALTER TABLE released_rpm DROP FOREIGN KEY fk_released_rpm_submission;
ALTER TABLE released_rpm ADD CONSTRAINT fk_released_rpm_submission FOREIGN KEY(submission_id) REFERENCES submission(submission_id) ON DELETE CASCADE;
