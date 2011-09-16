--
-- Added missing privilege LOCK TABLES for user hwdb.
--
-- This patch was created from commit revision 671 of opsqa svn
--

grant lock tables on hamsta_db.* to hwdb@localhost;
flush privileges;

