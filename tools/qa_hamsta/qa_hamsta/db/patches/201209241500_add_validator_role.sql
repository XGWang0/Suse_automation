INSERT INTO `user_role` (`role`, `descr`) VALUES ('validator', 'Validation tests role');

INSERT INTO `role_privilege` (`role_id`, `privilege_id`)
VALUES ((SELECT `role_id` FROM `user_role` WHERE `role` = 'validator'),
  (SELECT `privilege_id` FROM `privilege` WHERE `privilege` = 'validation_start'));
