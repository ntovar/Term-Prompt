#-*- perl -*-
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use File::Copy;
require 5.002;			# Prompt.pm has prototyping

if ($] >= 5.005) {
  (copy('Prompt.pm.5.005','Prompt.pm')) ||
    (die "Can't copy Prompt.pm.5.005 to Prompt.pm: $!; stopped");
} else {
  (copy('Prompt.pm.5.002','Prompt.pm')) ||
    (die "Can't copy Prompt.pm.5.002 to Prompt.pm: $!; stopped");
}

(chmod(0755,'Prompt.pm')) ||
  (die "Can't chmod Prompt.pm to 0755: $!; stopped");

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
