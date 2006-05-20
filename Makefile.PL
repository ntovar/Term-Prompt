use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Term::Prompt',
    VERSION_FROM      => 'lib/Term/Prompt.pm', # finds $VERSION
    PREREQ_PM         => {
    	Test::Expect	=> 0.30,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/Prompt.pm', # retrieve abstract from module
       AUTHOR         => 'Sjors Gielen <sjorsgielen@gmail.com>') : ()),
);
