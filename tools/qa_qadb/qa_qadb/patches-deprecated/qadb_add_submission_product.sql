alter table submissions add column `type` enum('prod','kotd','maint');
alter table submissions add index(`type`);
update submissions s,product_testing p set s.type='prod' where s.submissionID=p.submissionID;
update submissions s,kotd_testing k set s.type='kotd' where s.submissionID=k.submissionID;
update submissions s,maintenance_testing m set s.type='maint' where s.submissionID=m.submissionID;

