alter table testcases add column relative_url varchar(255) not null default '';
update testcases set relative_url=testcase;


