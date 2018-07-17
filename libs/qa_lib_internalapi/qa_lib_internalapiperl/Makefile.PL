# File : Makefile.PL
use ExtUtils::MakeMaker;
WriteMakefile(
        'NAME'    => 'libqainternalperl',                  # Name of package
	'VERSION' => '0.2',
	'AUTHOR'  => 'QA Team <qa-team@suse.de>',
        'LIBS'    => ['-lqainternal'],                    # Name of custom libraries
        'OBJECT'  => 'libqainternalperl.so',  # Object files
        'EXE_FILES' => ['bin/demo_use_perl.pl']
);

