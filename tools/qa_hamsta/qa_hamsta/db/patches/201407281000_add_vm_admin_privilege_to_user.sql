INSERT INTO role_privilege (role_id,privilege_id)
  SELECT user_role.role_id, privilege.privilege_id FROM user_role, privilege
  WHERE user_role.role IN ('user') AND privilege.privilege IN ('vm_admin');
