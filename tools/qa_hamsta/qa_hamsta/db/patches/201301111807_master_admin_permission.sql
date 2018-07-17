INSERT INTO privilege(privilege,descr) VALUES('master_administration','Administration of Hamsta master');
INSERT INTO role_privilege(role_id,privilege_id) SELECT user_role.role_id,privilege.privilege_id FROM user_role,privilege WHERE user_role.role IN ('admin') AND privilege.privilege='master_administration';
