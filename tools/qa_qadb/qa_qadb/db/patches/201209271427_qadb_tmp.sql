CREATE DATABASE IF NOT EXISTS qadb_tmp;
INSERT IGNORE INTO mysql.db(Host,Db,User,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Index_priv,Alter_priv,Create_tmp_table_priv,Lock_tables_priv) SELECT * FROM (SELECT DISTINCT Host,'qadb_tmp' AS Db,User,'Y' AS Select_priv,'Y' AS Insert_priv,'Y' AS Update_priv,'Y' AS Delete_priv,'Y' AS Create_priv,'Y' AS Drop_priv,'Y' AS Index_priv,'Y' AS Alter_priv,'Y' AS Create_tmp_table_priv,'Y' AS Lock_tables_priv FROM mysql.db WHERE db='qadb') t;
FLUSH PRIVILEGES;
