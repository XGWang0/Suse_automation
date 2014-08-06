INSERT INTO user
(extern_id,
 login,
 name,
 email,
 password
)
VALUES
('https://www.suse.com/openid/user/testuser',
 'testuser',
 'Test User',
 'testuser@testpage.org',
 SHA1('testpassword')
);

INSERT INTO user_in_role
  SELECT user_id, role_id FROM `user`, user_role
  WHERE login = 'testuser' and `role` = 'user';
