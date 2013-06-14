-- This relation is introduced because we want more users to be able to reserve the same machine.
CREATE TABLE `user_machine` (
       `machine_id`	integer NOT NULL COMMENT 'Reference to the reserved machine.',
       `user_id`	integer NOT NULL COMMENT 'Reference to the user having the reservation.',
       `user_note`	varchar(64) DEFAULT NULL COMMENT 'Description from the reservating person.',
       `reserved`	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the reservation was created.',
       `expires`	datetime DEFAULT NULL COMMENT 'When the reservation expires.',
       PRIMARY KEY (`machine_id`,`user_id`),
       CONSTRAINT `fk_user_machine_machine_id_machine_machine_id` FOREIGN KEY (`machine_id`) REFERENCES `machine` (`machine_id`) ON DELETE CASCADE,
       CONSTRAINT `fk_user_machine_user_id_user_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT 'Collects information about which user has which machine reserved.';

-- Move the data from the old structure.
INSERT INTO `user_machine` (`machine_id`, `user_id`, `expires`)
SELECT m.machine_id, u.user_id, m.expires FROM machine m INNER JOIN user u ON (m.usedby = u.user_id);

-- Remove attributes from machine.
ALTER TABLE machine
       DROP FOREIGN KEY `fk_machine_usedby_user_user_id`,
       DROP COLUMN usedby,
       DROP COLUMN reserved,
       DROP COLUMN expires;
