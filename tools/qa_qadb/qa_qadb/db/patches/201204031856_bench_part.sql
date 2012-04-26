ALTER TABLE bench_part 
	ADD COLUMN bench_part_x VARCHAR(80) NOT NULL COMMENT 'What goes on X axis', 
	ADD COLUMN bench_part_z VARCHAR(170) NOT NULL COMMENT 'Different settings or parts of the test, creates separate graphs',
	COMMENT='Different cathegories for benchmark numbers.';
UPDATE bench_part SET bench_part_x=LTRIM(SUBSTRING_INDEX(bench_part,';',1));
UPDATE bench_part SET bench_part_z=LTRIM(TRIM(LEADING ';' FROM LTRIM(TRIM(LEADING bench_part_x FROM bench_part))));
ALTER TABLE bench_part ADD UNIQUE(bench_part_z,bench_part_x);
ALTER TABLE bench_part DROP COLUMN bench_part;
