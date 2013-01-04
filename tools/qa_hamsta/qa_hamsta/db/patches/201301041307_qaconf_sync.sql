ALTER TABLE qaconf ADD COLUMN sync_url VARCHAR(2048) NULL;
DELETE FROM qaconf;
INSERT INTO qaconf(qaconf_id,`desc`,sync_url) VALUES (1,'global configuration','http://qadb.suse.de/global.conf'),(2,'country configuration','http://qadb.suse.de/blank.txt'),(3,'site configuration','http://qadb.suse.de/blank.txt'),(4,'master configuration',NULL);