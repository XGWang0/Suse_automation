create table board_last (
	testerID int not null,
	last timestamp not null default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
	primary key(testerID),
	foreign key(testerID) references testers(testerID) on delete cascade
) engine innodb;
