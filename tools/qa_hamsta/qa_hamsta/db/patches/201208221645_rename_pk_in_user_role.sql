
ALTER TABLE user_in_role DROP FOREIGN KEY fk_user_in_role_role_id;

DROP TABLE `user_role`;

CREATE TABLE user_role (
       role_id    INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'Role identifier.',
       role  VARCHAR (255) NOT NULL UNIQUE COMMENT 'Name of the role.',
       descr  VARCHAR (255) DEFAULT NULL COMMENT 'Obligatory description.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO user_role (role, descr) VALUES ('admin', 'Administrator role');
INSERT INTO user_role (role, descr) VALUES ('user', 'Usual user role');

ALTER TABLE user_in_role ADD FOREIGN KEY (`role_id`) REFERENCES `user_role` (`role_id`) ON DELETE RESTRICT;
