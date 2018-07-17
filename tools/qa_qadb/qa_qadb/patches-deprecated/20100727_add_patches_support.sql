-- Create table schema and add version 000000000000 into it.
-- this table is needed to tell the update_db.sh script which
-- version the DB's schema is
-- version is in fact a datetime so it's known in which order patches
-- need to be applied
-- version format: YYYYMMDDhhmm

CREATE TABLE `qadb`.`schema` (
  `version` CHAR(12)  NOT NULL,
  PRIMARY KEY (`version`)
)
ENGINE = InnoDB
CHARACTER SET utf8 COLLATE utf8_unicode_ci;

insert into qadb.schema (version) values ('000000000000');

