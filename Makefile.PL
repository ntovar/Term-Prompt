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
			 'SUFFIX'=>"gz"
			}
	     );

sub MY::dist_dir {
  package MY; # so that "SUPER" works right
  my $inherited = shift->SUPER::dist_dir(@_);
  $inherited =~ s/(distdir\s*:)/$1 README/;
  return $inherited;
}

sub MY::postamble {
  return "\n" .
    "README : \$(MAN1PODS) \$(MAN3PODS)\n" .
      "\tCOLUMNS=76 pod2text \$(MAN1PODS) \$(MAN3PODS) > README\n";
}
