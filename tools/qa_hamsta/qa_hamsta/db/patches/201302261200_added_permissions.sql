INSERT INTO privilege(privilege,descr) VALUES
	('job_edit','Edit custom job XMLs on the master'),
	('vm_admin','Create or delete virtual guests'),
	('vm_admin_reserved','Create or delete virtual guests reserved by other user'),
	('vm_startstop','Start or stop virtual guests'),
	('vm_startstop_reserved','Start or stop virtual guests reserved by other user'),
	('vh_admin','Create, delete or reinstall virtual hosts'),
	('vh_admin_reserved','Create, delete or reinstall virtual hosts reserved by other user');
INSERT INTO role_privilege(role_id,privilege_id) SELECT user_role.role_id,privilege.privilege_id FROM user_role,privilege WHERE user_role.role IN ('admin') AND privilege.privilege IN ('vm_admin','vm_admin_reserved','vm_startstop_reserved','vh_admin','vh_admin_reserved');
INSERT INTO role_privilege(role_id,privilege_id) SELECT user_role.role_id,privilege.privilege_id FROM user_role,privilege WHERE user_role.role IN ('admin','user') AND privilege.privilege IN ('job_edit','vm_startstop');

DELETE FROM role_privilege WHERE privilege_id=(SELECT privilege_id FROM privilege WHERE privilege='group_list_machines');
DELETE FROM privilege WHERE privilege='group_list_machines';

INSERT INTO role_privilege(role_id,privilege_id) SELECT user_role.role_id,privilege.privilege_id FROM user_role,privilege WHERE user_role.role IN ('user') AND privilege.privilege IN ('group_create','group_edit','group_delete');