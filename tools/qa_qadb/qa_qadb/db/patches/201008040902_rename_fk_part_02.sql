ALTER TABLE bench_data DROP FOREIGN KEY bench_data_ibfk_2;
ALTER TABLE bench_data ADD CONSTRAINT fk_bench_data_resultsID_results_resultsID FOREIGN KEY (`resultsID`) REFERENCES `results` (`resultsID`) ON DELETE CASCADE;
