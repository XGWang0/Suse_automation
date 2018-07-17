ALTER TABLE software_config ADD INDEX(rpm_config_id,rpm_id);
ALTER TABLE software_config DROP INDEX configID;
