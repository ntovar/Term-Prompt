#-*- perl -*-
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile('NAME'	=> 'Term::Prompt',
	      'VERSION_FROM' => 'Prompt.pm', # finds $VERSION
	      'PREREQ_PM' => {
			      'Term::ReadKey' => 2.13
			     },
	      'dist' => {
			 'COMPRESS'=>"gzip",
			 'SUFFIX'=>"gz",
			 'PREOP'=> "COLUMNS=76 pod2text \$(MAN1PODS)" .
			 " \$(MAN3PODS) > \$(DISTVNAME)/README"
			}
	     );
