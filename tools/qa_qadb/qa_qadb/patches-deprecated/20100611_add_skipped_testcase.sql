-- add skipped column - testcase can have special result skipped
alter table results add column skipped int default 0 after internal_error;

-- make other results count default to 0
alter table results alter column succeeded set default 0;
alter table results alter column failed set default 0;
alter table results alter column internal_error set default 0;

-- no older results were ever skipped - is it neccessary at all?
-- update results set skipped=0 where skipped is NULL;

