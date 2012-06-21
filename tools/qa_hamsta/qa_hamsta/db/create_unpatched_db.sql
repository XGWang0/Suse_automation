/*
  ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
  THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
  CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
  RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
  THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
  THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
  TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
  PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
  PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
  AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
  LIABILITY.
  
  SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
  WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
  AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
  LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
  WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
  ****************************************************************************
*/

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

drop database IF EXISTS hamsta_db;
create database hamsta_db DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
-- update mysql.user set Password="" where User="hwdb@localhost";
grant select, insert, update, delete on hamsta_db.* to hwdb@localhost;
use hamsta_db;


-- machine main tables
drop table if exists machine_status;
CREATE TABLE machine_status (
  machine_status_id int not null auto_increment primary key,
  machine_status varchar(255) not null,
  unique(machine_status)
) ENGINE=InnoDB;
INSERT INTO machine_status VALUES (1,'up'),(2,'down'),(5,'not responding'),(6,'unknown');

drop table if exists product;
CREATE TABLE product (
  product_id int not null auto_increment primary key,
  product varchar(50),
  unique(product)
) ENGINE=InnoDB;

drop table if exists `release`;
CREATE TABLE `release` (
  release_id int not null auto_increment primary key,
  `release` varchar (50),
  unique(`release`)
) ENGINE=InnoDB;

drop table if exists arch;
CREATE TABLE arch (
  arch_id int not null auto_increment primary key,
  arch varchar (50),
  unique(arch)
) ENGINE=InnoDB;

drop table if exists machine;
CREATE TABLE machine (
  machine_id int not null auto_increment,
  unique_id varchar(255) not null,
  name varchar(255) not null,
  arch_id int,
  maintainer_id varchar(255) default NULL,
  ip varchar(16) not null,
  product_id int,
  product_arch_id int,
  release_id int,
  kernel varchar(255) not null,
  description text not null,
  last_used varchar(255) not null,
  machine_status_id int not null,
  affiliation text not null,
  `usage` varchar(64) not null,
  usedby varchar(255) not null,
  anomaly text not null,
  serialconsole varchar(255),
  powerswitch varchar(255),
  busy tinyint(1) not null default 0,
  primary key  (machine_id),
  foreign key(machine_status_id) references machine_status(machine_status_id) on delete restrict,
  foreign key(arch_id) references arch(arch_id) on delete restrict,
  foreign key(product_arch_id) references arch(arch_id) on delete restrict,
  foreign key(product_id) references product(product_id) on delete restrict,
  foreign key(release_id) references `release`(release_id) on delete restrict
) ENGINE=InnoDB;

-- machine configuration tables
drop table if exists config;
CREATE TABLE config (
  config_id int not null auto_increment primary key,
  timestamp_created timestamp default CURRENT_TIMESTAMP,
  timestamp_last_active timestamp null,
  machine_id int not null,
  config_md5 char(22) not null,
  index(machine_id,config_id),
  unique(config_md5),
  foreign key(machine_id) references machine(machine_id) on delete cascade
) ENGINE=InnoDB;

drop table if exists module_name;
CREATE TABLE module_name (
  module_name_id int not null auto_increment primary key,
  module_name varchar(255),
  unique(module_name)
) ENGINE=InnoDB;

drop table if exists module;
CREATE TABLE module (
  module_id int not null auto_increment primary key,
  module_name_id int not null,
  module_version int not null,
  module_md5 char(22) not null,
  foreign key(module_name_id) references module_name(module_name_id) on delete restrict,
  index(module_name_id,module_version),
  unique(module_name_id,module_md5)
) ENGINE=InnoDB;

drop table if exists config_module;
CREATE TABLE config_module (
  config_id int not null,
  module_id int not null,
  primary key(config_id,module_id),
  foreign key(config_id) references config(config_id) on delete cascade,
  foreign key(module_id) references module(module_id) on delete cascade
) ENGINE=InnoDB;

drop table if exists module_part;
CREATE TABLE module_part (
  module_part_id int not null auto_increment primary key,
  module_id int not null,
  element varchar(255) not null default '',
  value text,
  part int not null default '0',
  foreign key(module_id) references module(module_id) on delete cascade
) ENGINE=InnoDB;


-- job tables
drop table if exists job_status;
CREATE TABLE job_status (
  job_status_id tinyint not null auto_increment primary key,
  job_status varchar(255) not null,
  unique(job_status)
) ENGINE=InnoDB;
INSERT INTO job_status VALUES (0,'new'),(1,'queued'),(2,'running'),(3,'passed'),(4,'failed'),(5,'canceled');

drop table if exists job;
CREATE TABLE job (
  job_id int not null auto_increment primary key,
  short_name varchar(255) not null,
  description text not null,
  job_owner varchar(255) not null,
  slave_directory varchar(255) not null,
  xml_file varchar(255) not null,
  job_status_id tinyint not null,
  aimed_host varchar(15),
  foreign key(job_status_id) references job_status(job_status_id) on delete restrict
) ENGINE=InnoDB;

drop table if exists job_on_machine;
CREATE TABLE job_on_machine (
  job_on_machine_id int not null auto_increment primary key,
  job_id int not null,
  machine_id int not null,
  config_id int not null,
  start datetime,
  stop datetime,
  return_status varchar(255) not null,
  return_xml varchar(255) not null,
  job_status_id tinyint not null,
  last_log text not null,
  timestamp timestamp,
  unique(job_id,machine_id),
  foreign key(job_id) references job(job_id) on delete cascade,
  foreign key(machine_id) references machine(machine_id) on delete cascade,
  foreign key(config_id) references config(config_id) on delete restrict,
  foreign key(job_status_id) references job_status(job_status_id) on delete restrict
) ENGINE=InnoDB;

-- machine group tables
drop table if exists `group`;
CREATE TABLE `group` (
  group_id int not null auto_increment primary key,
  `group` varchar(255) not null,
  description text,
  unique(`group`)
) ENGINE=InnoDB;

drop table if exists group_machine;
CREATE TABLE group_machine (
  group_id int not null,
  machine_id int not null,
  foreign key(group_id) references `group`(group_id) on delete cascade,
  foreign key(machine_id) references machine(machine_id) on delete cascade,
  primary key(group_id,machine_id)
) ENGINE=InnoDB;




/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Create table schema and add version 000000000000 into it.
-- this table is needed to tell the update_db.sh script which
-- version the DB's schema is
-- version is in fact a datetime so it's known in which order patches
-- need to be applied
-- version format: YYYYMMDDhhmm

CREATE TABLE `hamsta_db`.`schema` (
  `version` CHAR(12)  NOT NULL,
  PRIMARY KEY (`version`)
)
ENGINE = InnoDB
CHARACTER SET utf8 COLLATE utf8_unicode_ci;

insert into hamsta_db.schema (version) values ('000000000000');

