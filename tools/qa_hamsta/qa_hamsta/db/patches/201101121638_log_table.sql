CREATE TABLE log (
  log_id int NOT NULL auto_increment primary key,
  machine_id int not null,
  job_on_machine_id int null,
  log_time timestamp NOT NULL default CURRENT_TIMESTAMP,
  log_type enum('RESERVE', 'RELEASE', 'REINSTALL', 'CONFIG', 'JOB_START', 'JOB_FINISH', 'CRITICAL', 'ERROR', 'WARNING', 'NOTICE', 'INFO', 'DETAIL', 'DEBUG', 'STDIN', 'STDOUT', 'STDERR', 'RETURN' ),
  log_user varchar(50) not null default '',
  log_what varchar(50) not null default '',
  log_text varchar(16384) not null default '',
  index(log_time),
  index(log_type),
  index(log_user),
  index(log_what),
  foreign key fk_log_machine(machine_id) references machine(machine_id) on delete cascade,
  foreign key fk_log_job_on_machine(job_on_machine_id) references job_on_machine(job_on_machine_id) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=utf8;