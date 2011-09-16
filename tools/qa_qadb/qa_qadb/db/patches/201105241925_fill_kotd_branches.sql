-- delete unused branches
DELETE FROM kernel_branches WHERE NOT EXISTS( SELECT * FROM kotd_testing WHERE kernel_branches.branchID=kotd_testing.branchID );

-- insert current branches
INSERT IGNORE INTO kernel_branches(branch) VALUES
	('master'),
	('stable'),
	('vanilla'),
	('linux-next'),
	('SLE11_BRANCH'),
	('SLE11-SP2'),
	('SLE11-SP1'),
	('SLE11-SP1-RT'),
	('openSUSE-11.4'),
	('openSUSE-11.3'),
	('SLES10_SP4_BRANCH'),
	('SLES10_SP3_BRANCH'),
	('SLERT10_SP3_BRANCH'),
	('SLES10-SP3-TD'),
	('SLES10_SP2_LTSS'),
	('SLES10-SP1-TD'),
	('SLES9_SP4_BRANCH'),
	('SLES9-SP3-TD')
;

-- rename alias 'HEAD' to the original name 'master' so that links to kerncvs work
UPDATE kotd_testing 
	SET   branchID=(SELECT branchID FROM kernel_branches WHERE branch='master') 
	WHERE branchID=(SELECT branchID FROM kernel_branches WHERE branch='HEAD');

-- delete the branch 'HEAD'
DELETE FROM kernel_branches WHERE branch='HEAD';
