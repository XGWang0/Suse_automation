-- swaps 'release' and 'version' in the table 'kotd_testing' (they are already swapped)
update kotd_testing set `release`=(@tmp:=`release`), `release`=`version`, `version`=@tmp;

