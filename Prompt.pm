package Term::Prompt;
require 5.000;
require Exporter;
use Carp;

use Text::Abbrev;
use Text::Wrap;
use Term::Size;

BEGIN: {
  $VERSION = '0.03';
}

@ISA = qw(Exporter);
@EXPORT = qw(prompt);
@EXPORT_OK = qw(rangeit legalit typeit exprit yesit);

sub prompt ($$$$;@) {
  my($debug) = 0;		# debugging
  
  my($mopt, $prompt, $prompt_options, $help_prompt, $default, @things);
  my($repl, $match_options, $case, $low, $high, $before, $regexp,
     $prompt_full);
  
  # Figure out just what we are doing here
  $mopt = $_[0];
  print "mopt is: $mopt\n" if $debug;
  
  # check the size of the match option, it should just have one char.
  croak "Illegal call in im_prompt2 prompter."
    if ( length($mopt) > 1 );
  
  my($type) = 0;
  my($legal) = 0;
  my($range) = 0;
  my($expr) = 0;
  my($yn) = 0;
  my($uc) = 0;
  
  if ($mopt ne lc($mopt)) {
    $uc = 1;
    $mopt = lc($mopt);
  }

  if ( $mopt eq "x" || $mopt eq "a" || $mopt eq "n" ) {
    # More efficient this way - Allen
    ($mopt, $prompt, $prompt_options, $default) = @_;
    $type = 1;
  } elsif ( $mopt eq "c" || $mopt eq "i" ) {
    ($mopt, $prompt, $prompt_options, $default, @things) = @_;
    $legal = 1;
  } elsif ( $mopt eq "r" ) {
    ($mopt, $prompt, $prompt_options, $default, $low, $high) = @_;
    $range = 1;
  } elsif ( $mopt eq "e" ) {
    ($mopt, $prompt, $prompt_options, $default, $regexp) = @_;
    $expr = 1;
  } elsif ( $mopt eq "y" ) {
    ($mopt, $prompt, $prompt_options, $default) = @_;
    $yn = 1;
    if ((!defined($prompt_options)) || ($prompt_options eq '')) {
      if ($uc) {
	$prompt_options = "Enter y or n";
      } else {
	$prompt_options = "y or n";
      }
    }
    
    if (defined($default)) {
      unless ($default =~ m/^[ynYN]/) {
	if ($default) {
	  $default = "y";
	} else {
	  $default = "n";
	}
      }
    } else {
      $default = "n";
    }
  } else {
    croak "prompt type $mopt not recognized";
  }

  $ok = 0;
  $before = 0;
  
  while (1) {
    
    $prompt_full = "$prompt ";
    unless ($before || $uc || ($prompt_options eq '')) {
      $prompt_full .= "($prompt_options) ";
    }
    
    if ($default ne '') {
      $prompt_full .= "[default $default] ";
    }
    
    # print out the prompt string in all its gore
    print termwrap($prompt_full);

    my($old_divide) = undef;

    if (defined($/)) {
      $old_divide = $/;
    }

    $/ = "\n";

    $repl = scalar(readline(*STDIN));

    if (defined($old_divide)) {
      $/ = $old_divide;
    } else {
      undef($/);
    }

    chomp($repl);          # nuke the <CR>
    
    $repl =~ s/^\s*//;	# ignore leading white space
    $repl =~ s/\s*$//;	# ignore trailing white space
    
    $repl = $default if $repl eq '';
    
    if (($repl eq '') && (! $uc)) {
      # so that a simple return can be an end of a series of prompts - Allen
      print "Invalid option\n"; 
      next;
    }

    print termwrap("Reply: '$repl'\n") if $debug;
    
    # Now here is where things get real interesting

    if ($uc && ($repl eq '')) {
      $ok = 1;
    } elsif ( $type ) {
      $ok = &typeit(lc($mopt), $repl, $debug, $uc);
    } elsif ( $legal ) {
      $repl = $ok = &legalit(lc($mopt), $repl, $uc, @things);
    } elsif ( $range ) {
      $ok = &rangeit($repl, $low, $high, $uc);
    } elsif ( $expr ) { 
      $ok = &exprit($repl, $regexp, $prompt_options, $debug);
    } elsif ( $yn ) {
      ($ok,$repl) = &yesit($repl, $uc, $debug);
    } else {
      croak "No subroutine known for prompt option $mopt.";
    }
    
    if ( $ok ) {
      return $repl;
    } elsif ( $prompt_options ne '' ) {
      if ($uc) {
	print termwrap("$prompt_options\n");
      } else {
	print termwrap("Options are: $prompt_options\n");
	$before = 1;
      }
    }
  }
}

sub rangeit ($$$$) {
  # this routine makes sure that the reply is within a given range 

  my($repl, $low, $high, $uc) = @_;

  if ( $low <= $repl && $repl <= $high ) { 
    return 1;
  } elsif (! $uc) {
    print "Invalid range value.  ";
  }
  return 0;
}

sub legalit ($$$@) {
  # this routine checks to see if a repl is one of a set of "things"
  # it checks case based on c = case check, i = ignore case
  
  my($mopt, $repl, $uc, @things) = @_;
  my(@match,$tmp) = ();
  
  local(%abbrevhash) = ();
  abbrev(*abbrevhash,@things);
  
  if ( $mopt eq "i" ) {
    my(%abbrevhash2) = %abbrevhash;
    foreach $key (keys %abbrevhash2) {
      $abbrevhash{lc($key)} = $abbrevhash{$key};
    }
    $repl = lc($repl);
  }
  
  if (exists ($abbrevhash{$repl})) {
    return $abbrevhash{$repl};
  } elsif (! $uc) {
    print "Invalid.  ";
  }
  return 0;
}

sub typeit ($$$$) {
  # this routine does checks based on the following:
  # x = no checks, a = alpha only, n = numeric only
  
  my ($mopt, $repl, $debug, $uc) = @_;
  
  print "inside of typeit\n" if $debug;
  
  if ( $mopt eq "x" ) { return 1; }
  
  if ( $mopt eq "a" ) {
    if ( $repl =~ /^[a-zA-Z]*$/ ) { 
      return 1;
    } elsif (! $uc) {		
      print "Invalid type value.  ";
    }
    return 0;
  }

  if ( $mopt eq "n" ) {
    if ( $repl =~/^[0-9]*$/ ) { 
      return 1; 
    } elsif (! $uc) {
      print "Invalid numeric value.  ";
    }
    return 0;
  }
}

sub exprit ($$$$) {
  # This routine does checks based on whether something
  # matches a supplied regexp - Allen
  my ($repl, $regexp, $prompt_options, $debug) = @_;
  print "inside of exprit\n" if $debug;
  
  if ( $repl =~ /^$regexp$/ ) {
    return 1;
  } elsif ( $prompt_options eq '') {
    print termwrap("Reply needs to match regular expression /^$regexp$/.\n");
    return 0;
  }
}

sub yesit ($$$) {
  # basic yes or no - Allen
  my ($repl, $uc, $debug) = @_;
  print "inside of yesit\n" if $debug;
  
  if ($repl =~ m/^[0nN]/) {
    return 1,0;
  } elsif ($repl =~ m/^[1yY]/) {
    return 1,1;
  } elsif (! $uc) {
    print "Invalid yes or no response. ";
  }
  return 0,0;
}

sub termwrap ($;@) {
  my($message) = "";
  if ($#_ > 0) {
    if (defined($,)) {
      $message = join($,,@_);
    } else {
      $message = join(" ",@_);
    }
  } else {
    $message = $_[0];
  }
    
  if (select eq "STDERR") {
    if ((-t STDERR) &&
	defined($width = scalar(Term::Size::chars(*STDERR))) && ($width > 0)) {
      $Text::Wrap::columns = $width;
    } elsif ((-t STDOUT) &&
	     defined($width = scalar(Term::Size::chars(*STDOUT))) &&
	     ($width > 0)) {
      $Text::Wrap::columns = $width;
    }
  } else {
    if ((-t STDOUT) && defined($width = scalar(Term::Size::chars(*STDOUT))) &&
	($width > 0)) {
      $Text::Wrap::columns = $width;
    } elsif ((-t STDERR) &&
	     defined($width = scalar(Term::Size::chars(*STDERR))) &&
	     ($width > 0)) {
      $Text::Wrap::columns = $width;
    }
  }

  if ($message =~ m/\n\Z/) {
    $message = wrap("", "\t", $message);
    $message =~ s/\n*\Z/\n/;
    return $message;
  } else {
    $message = wrap("", "\t", $message);
    $message =~ s/\n*\Z//;
    return $message;
  }
}

1;


__END__

=head1 NAME

Term::Prompt - Perl extension for prompting a user for information

=head1 SYNOPSIS

    use Term::Prompt;

=head1 DESCRIPTION

 This perl routine will take a prompt, a default response and a list of
 possible responses and deal with the user interface, (and the user!),
 by displaying the prompt, showing the default, and checking to be sure
 that the response is one of the legal choices.
 --Mark Henderson


 Derived from im_prompt2.pl, from anlpasswd (see
 ftp://info.mcs.anl.gov/pub/systems/), with permission. Revisions for Perl 5,
 addition of alternative help text presentation, addition of regular
 expression type, addition of yes/no type, and line wrapping by E. Allen Smith.

 Additional "types" that could be added would be a phone type,
 a social security type, a generic numeric pattern type...

 The usage is the following:
 x = don't care, a = alpha-only, n = numeric-only, i = ignore case
 c = case sensitive, r = ranged by the low and high values
 y = yes/no, e = regular expression - Added by Allen

 $result = &prompt("x", "text prompt", "help prompt", "default" );

 $result = &prompt("a", "text prompt", "help prompt", "default" );

 $result = &prompt("n", "text prompt", "help prompt", "default" );

 $result = &prompt("i", "text prompt", "help prompt", "default",
	                 "legal_options-ignore-case-list");

 $result = &prompt("c", "text prompt", "help prompt", "default",
	                 "legal_options-case-sensitive-list");

 $result = &prompt("r", "text prompt", "help prompt", "default",
                       "low", "high");

 $result = &prompt("y", "text prompt", "help prompt", "default")

 The result will be 1 for y, 0 for n. A default not starting with y or n
 (or the uc versions of these) will be treated as y for positive, n for
 negative.

 $result = &prompt("e", "text prompt", "help prompt", "default",
                       "regular expression");

 The regular expression for the last has ^ and $ surrounding it automatically;
 just put in .* before or after if you need to free it up before or
 after. - Allen

 What, you might ask, is the difference between a "text prompt" and a
 "help prompt"?  Think about the case where the "legal_options" look 
 something like: "1-1000".  Now consider what happens when you tell someone
 that "0" is not between 1-1000 and that the possible choices are:  :)
 1 2 3 4 5 .....
 This is what the "help prompt" is for.

 It will work off of unique parts of "legal_options".

 Changed by Allen - it will be treated as a true "help prompt" if you
 capitalize the type of prompt, and otherwise will be treated as a list of
 options. Capitalizing the type of prompt will also mean that a return may be
 accepted as a response, even if there is no default; whether it actually is
 will depend on the type of prompt.

=head1 AUTHOR

Mark Henderson (henderson@mcs.anl.gov or systems@mcs.anl.gov)
Primary contact author: Allen Smith (easmith@beatrice.rutgers.edu)

=head1 SEE ALSO

perl(1).

=cut


