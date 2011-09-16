ALTER TABLE bench_data DROP FOREIGN KEY bench_data_ibfk_1;
ALTER TABLE bench_data ADD CONSTRAINT fk_bench_data_partID_bench_parts_partID FOREIGN KEY (`partID`) REFERENCES `bench_parts` (`partID`);
