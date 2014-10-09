-- Maintenance requests patches identified as issuer_id:issue_id:request_id, in addition to existing md5sum
ALTER TABLE submission 
	ADD COLUMN issuer_id ENUM('SUSE','openSUSE'),
	ADD COLUMN issue_id INT NULL,
	CHANGE `type` `type` ENUM('prod','kotd','maint','maint2');
UPDATE submission SET issuer_id='SUSE' WHERE type='maint';