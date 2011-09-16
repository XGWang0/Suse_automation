
alter table machine 
	add column (
		role enum ('SUT', 'VH') NOT NULL default 'SUT', 
		type varchar(64) not null default 'hw', 
		vh_id integer default NULL
	), 
	add index(role),
	add index(type),
	add index(vh_id),
	add foreign key fk_machine_vh_machine(vh_id) references machine(machine_id) on delete cascade;
