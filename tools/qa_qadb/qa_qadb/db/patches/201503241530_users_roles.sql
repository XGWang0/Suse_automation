-- add new users
-- production QADB is likely to have different passwords
-- i.e. these are for testing

GRANT ALL ON qadb.* TO qadb_admin@localhost IDENTIFIED BY 'bignastyboy' WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE,DELETE ON qadb.* TO qadb_user@localhost IDENTIFIED BY 'givememydata';
GRANT ALL ON qadb_tmp.* TO qadb_admin@localhost WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON qadb_tmp.* TO qadb_user;
FLUSH PRIVILEGES;
