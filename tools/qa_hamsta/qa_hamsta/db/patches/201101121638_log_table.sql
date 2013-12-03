/*
****************************************************************************
  Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
  
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