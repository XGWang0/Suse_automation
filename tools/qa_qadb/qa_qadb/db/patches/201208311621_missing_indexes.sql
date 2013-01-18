ALTER TABLE submission ADD INDEX(submission_date);
ALTER TABLE submission ADD INDEX(md5sum);
ALTER TABLE submission ADD INDEX(patch_id);