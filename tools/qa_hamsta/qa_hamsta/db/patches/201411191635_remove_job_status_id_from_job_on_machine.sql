-- DROP job_status_id from job_on_machine
SELECT CONCAT('ALTER TABLE job_on_machine DROP FOREIGN KEY ',constraint_name,'') INTO @sqlst
FROM information_schema.key_column_usage where table_name='job_on_machine' and column_name='job_status_id';
PREPARE stmt FROM @sqlst;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sqlstr = NULL;

ALTER TABLE `job_on_machine` DROP COLUMN `job_status_id`;
