package Term::Prompt;
require 5.002;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG $MULTILINE_INDENT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(prompt);
@EXPORT_OK = qw(rangeit legalit typeit menuit exprit yesit termwrap);

$VERSION = '0.12';
$DEBUG = 0;
$MULTILINE_INDENT = "\t";

use Carp;
use Text::Wrap;
use Term::ReadKey qw(GetTerminalSize);

my %menu = (
	    order => 'down',
	    return_base => 0,
	    display_base => 1,
	    accept_multiple_selections => 0,
	    accept_empty_selection => 0,
	    title => '',
	    prompt => '>'
	   );

# Preloaded methods go here.

sub prompt ($$$$;@) {

  my($mopt, $prompt, $prompt_options, $default, @things);
  my($repl, $match_options, $case, $low, $high, $before, $regexp);
  my $prompt_full;

  # Figure out just what we are doing here
  $mopt = $_[0];
  print "mopt is: $mopt\n" if $DEBUG;

  # check the size of the match option, it should just have one char.
  if (length($mopt) == 1
      or $mopt =~ /\-n/i
      or $mopt =~ /\+-n/i) {
      my $dummy = "mopt is ok";
  } else {
      croak "Illegal call of prompt; $mopt is more than one character; stopped";
  }

  my $type = 0;
  my $menu = 0;
  my $legal = 0;
  my $range = 0;
  my $expr = 0;
  my $yn = 0;
  my $uc = 0;

  if ($mopt ne lc($mopt)) {
    $uc = 1;
    $mopt = lc($mopt);
  }

  if ($mopt eq "x" || $mopt eq "a" || ($mopt =~ /n$/) || $mopt eq "f") {
    # More efficient this way - Allen
    ($mopt, $prompt, $prompt_options, $default) = @_;
    $type = 1;
  } elsif ($mopt eq 'm') {
    ($mopt, $prompt, $prompt_options, $default) = @_;
   $menu = 1;
  } elsif ($mopt eq "c" || $mopt eq "i") {
    ($mopt, $prompt, $prompt_options, $default, @things) = @_;
    $legal = 1;
  } elsif ($mopt eq "r") {
    ($mopt, $prompt, $prompt_options, $default, $low, $high) = @_;
    $range = 1;
  } elsif ($mopt eq "e") {
    ($mopt, $prompt, $prompt_options, $default, $regexp) = @_;
    $expr = 1;
  } elsif ($mopt eq "y") {
    ($mopt, $prompt, $prompt_options, $default) = @_;
    $yn = 1;
    unless (defined($prompt_options) && length($prompt_options)) {
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

  my $ok = 0;

  $mopt = lc($mopt);

  while (1) {

    if (!$menu) {

	# print out the prompt string in all its gore
	$prompt_full = "$prompt ";

    }  else {

	## We're working on a menu
	@menu{sort keys %{$prompt}} = @{$prompt}{sort keys %{$prompt}};

	$prompt_full = "$menu{'prompt'} ";

	my @menu_items = @{$menu{'items'}};
	my $number_menu_items = scalar(@menu_items);

	$menu{'low'} = $menu{'display_base'};
	$menu{'high'} = $number_menu_items+$menu{'display_base'}-1;

	my $digits_in_menu_item = (int(log($menu{'high'})/log(10)) + 1);

	my $entry_length = 0;
	my $item_length = 0;
	for (@menu_items) {
	    $entry_length = length($_)
	      if length($_) > $entry_length;
	}
	$item_length = $entry_length;
	$entry_length += ( $digits_in_menu_item 	## Max number of digits in a selection
			 +
			 3 ## two for ') ', at least one for a column separator
		       );

	my $gw = get_width();

	my $num_cols = (defined($menu{'cols'})
			? $menu{'cols'}
			: int($gw/$entry_length));
	my $num_rows = (defined($menu{'rows'})
			? $menu{'rows'}
			: int($number_menu_items/$num_cols)+1) ;

	my $data_fmt = "%${digits_in_menu_item}d) %-${item_length}.${item_length}s";
	my $column_end_fmt = ("%s ");
	my $line_end_fmt   = ("%s\n");
	my @menu_out = ();
	my $row = 0;
	my $col = 0;
	my $idx = 0;

	if ($menu{order} =~ /ACROSS/i) {
	  ACROSS_LOOP:
	    for ($row = 0; $row < $num_rows; $row++) {
		for ($col = 0; $col < $num_cols; $col++) {
		    $menu_out[$row][$col] = sprintf($data_fmt,$idx+$menu{'display_base'},$menu_items[$idx++]);
		    last ACROSS_LOOP
		      if $idx eq scalar(@menu_items);
		}
	    }
	} else {
	  DOWN_LOOP:
	    for ($col = 0; $col < $num_cols; $col++) {
		for ($row = 0; $row < $num_rows; $row++) {
		    $menu_out[$row][$col] = sprintf($data_fmt,$idx+$menu{'display_base'},$menu_items[$idx++]);
		    last DOWN_LOOP
		      if $idx eq scalar(@menu_items);
		}
	    }
	}

	if (length($menu{'title'})) {
	    print $menu{'title'},"\n",'-' x length($menu{'title'}),"\n";
	}

	for ($row = 0;$row < $num_rows;$row++) {
	    for ($col = 0;$col < $num_cols-1;$col++) {
		printf($column_end_fmt,$menu_out[$row][$col])
		  if defined($menu_out[$row][$col]);
	    }
	    if(defined($menu_out[$row][$num_cols-1])) {
		printf($line_end_fmt,$menu_out[$row][$num_cols-1])
	    } else {
		print "\n";
	    }
	}

	if ($number_menu_items != ($num_rows)*($num_cols)) {
	    print "\n";
	}

	unless (defined($prompt_options) && length($prompt_options)) {
	    $prompt_options = "$menu{'low'} - $menu{'high'}";
	    if($menu{'accept_multiple_selections'}) {
		$prompt_options .= ", separate multiple entries with spaces";
	    }
	}
    }

    unless ($before || $uc || ($prompt_options eq '')) {
	$prompt_full .= "($prompt_options) ";
    }

    if ($default ne '') {
	$prompt_full .= "[default $default] ";
    }

    print termwrap($prompt_full);
    my $old_divide = undef;

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

    if (!$menu && ($repl eq '') && (! $uc)) {
      # so that a simple return can be an end of a series of prompts - Allen
      print "Invalid option\n";
      next;
    }

    print termwrap("Reply: '$repl'\n") if $DEBUG;

    # Now here is where things get real interesting
    my @menu_repl = ();
    if ($uc && ($repl eq '')) {
      $ok = 1;
    } elsif ($type) {
      $ok = &typeit($mopt, $repl, $DEBUG, $uc);
    } elsif ($menu) {
      $ok = &menuit(\@menu_repl, $repl, $DEBUG, $uc);
    } elsif ($legal) {
      ($ok,$repl) = &legalit($mopt, $repl, $uc, @things);
    } elsif ($range) {
      $ok = &rangeit($repl, $low, $high, $uc);
    } elsif ($expr) {
      $ok = &exprit($repl, $regexp, $prompt_options, $uc, $DEBUG);
    } elsif ($yn) {
      ($ok,$repl) = &yesit($repl, $uc, $DEBUG);
    } else {
      croak "No subroutine known for prompt type $mopt.";
    }

    if ($ok) {
	if($menu) {
	    if($menu{'accept_multiple_selections'}) {
		return (wantarray ? @menu_repl : \@menu_repl);
	    } else {
		return $menu_repl[0];
	    }
	} else {
	    return $repl;
	}
    } elsif (defined($prompt_options) && length($prompt_options)) {
      if ($uc) {
	print termwrap("$prompt_options\n");
      } else {
	  if (!$menu) {
	      print termwrap("Options are: $prompt_options\n");
	  }
	$before = 1;
      }
    }
  }
}

sub rangeit ($$$$ ) {
  # this routine makes sure that the reply is within a given range

  my($repl, $low, $high, $uc) = @_;

  if ( $low <= $repl && $repl <= $high ) {
    return 1;
  } elsif (!$uc) {
    print "Invalid range value.  ";
  }
  return 0;
}

sub legalit ($$$@) {
  # this routine checks to see if a repl is one of a set of "things"
  # it checks case based on c = case check, i = ignore case

  my($mopt, $repl, $uc, @things) = @_;
  my(@match) = ();

  if (grep {$_ eq $repl} (@things)) {
    return 1, $repl;		# save time
  }

  my $quote_repl = quotemeta($repl);

  if ($mopt eq "i") {
    @match = grep {$_ =~ m/^$quote_repl/i} (@things);
  } else {
    @match = grep {$_ =~ m/^$quote_repl/} (@things);
  }

  if (scalar(@match) == 1) {
    return 1, $match[0];
  } else {
    if (! $uc) {
      print "Invalid.  ";
    }
    return 0, "";
  }
}

sub typeit ($$$$ ) {
  # this routine does checks based on the following:
  # x = no checks, a = alpha only, n = numeric only

  my ($mopt, $repl, $DEBUG, $uc) = @_;

  print "inside of typeit\n" if $DEBUG;

  if ( $mopt eq "x" ) {
    return 1;
  } elsif ( $mopt eq "a" ) {
    if ( $repl =~ /^[a-zA-Z]*$/ ) {
      return 1;
    } elsif (! $uc) {
      print "Invalid type value.  ";
    }
  } elsif ( $mopt eq "n" ) {
    if ( $repl =~/^[0-9]*$/ ) {
      return 1;
    } elsif (! $uc) {
      print "Invalid numeric value. Must be a positive integer or 0. ";
    }
  } elsif ( $mopt eq "-n" ) {
    if ( $repl =~/^-[0-9]*$/ ) {
      return 1;
    } elsif (! $uc) {
      print "Invalid numeric value. Must be a negative integer or 0. ";
    }
  } elsif ( $mopt eq "+-n" ) {
    if ( $repl =~/^-?[0-9]*$/ ) {
      return 1;
    } elsif (! $uc) {
      print "Invalid numeric value. Must be an integer. ";
    }
  } elsif ( $mopt eq "f" ) {
    if ( $repl =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d)?([Ee]([+-]?\d+))?$/) {
      return 1;
    } elsif (! $uc) {
      print "Invalid floating point value.  ";
    }
  } else {
    croak "typeit called with unknown prompt type $mopt; stopped";
  }

  return 0;
}

sub menuit (\@$$$ ) {

  print "inside of menuit\n" if $DEBUG;

  my ($ra_repl, $repl, $DEBUG, $uc) = @_;
  my @msgs = ();

  ## Parse for multiple values. Any non-numeric char is a
  ## separator. Strip leading and trailing whitespace to avoid a being
  ## interpreted as separating empty choices.

  $repl =~ s/^(?:\s+)//;
  $repl =~ s/(?:\s+)$//;
  my @repls = split(/[^0-9]+/,$repl);

  ## Validations
  if ( scalar(@repls) > 1
       &&
       !$menu{'accept_multiple_selections'} ) {
      push @msgs, 'Multiple choices not allowed.';
  } elsif (!scalar(@repls)
	   &&
	   !$menu{'accept_empty_selection'}) {
      push @msgs, "You must make a selection.";
  } else {
      for (@repls) {
	  if ( !rangeit($_,$menu{'low'},$menu{'high'},1)) {
	      push @msgs, "$_ is an invalid choice.";
	  }
      }
  }

  ## Print errors or return values
  if(scalar(@msgs)) {
      print "\n",join("\n",@msgs),"\n\n";
      return 0;
  } else {
      @{$ra_repl} = map {$_ - $menu{'display_base'} + $menu{'return_base'}} @repls;
      return 1;
  }

}

sub exprit ($$$$$ ) {
  # This routine does checks based on whether something
  # matches a supplied regexp - Allen
  my($repl, $regexp, $prompt_options, $uc, $DEBUG) = @_;
  print "inside of exprit\n" if $DEBUG;

  if ( $repl =~ /^$regexp$/ ) {
    return 1;
  } elsif ((!$uc) ||
	   (!defined($prompt_options)) || (!length($prompt_options))) {
    print termwrap("Reply needs to match regular expression /^$regexp$/.\n");
  }
  return 0;
}

sub yesit ($$$ ) {
  # basic yes or no - Allen
  my ($repl, $uc, $DEBUG) = @_;
  print "inside of yesit\n" if $DEBUG;

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

  my $width = get_width();

  if (defined($width) && $width) {
    $Text::Wrap::Columns = $width;
  }

  if ($message =~ m/\n\Z/) {
    $message = wrap("", $MULTILINE_INDENT, $message);
    $message =~ s/\n*\Z/\n/;
    return $message;
  } else {
    $message = wrap("", $MULTILINE_INDENT, $message);
    $message =~ s/\n*\Z//;
    return $message;
  }
}

sub get_width {

    ## The 'use strict' added above caused the calls
    ## GetTerminalSize(STDOUT) and GetTerminalSize(STDERR) to fail in
    ## compilation. The fix as to REMOVE the parens. It seems as if
    ## this call works the same way as 'print' - if you need to
    ## specify the filehandle, you don't use parens (and don't put a
    ## comma after the filehandle, although that is irrelevant here.)

    ## SO DON'T PUT THEM BACK! :-)

    my($width) = eval {
	local($SIG{__DIE__});
	(GetTerminalSize(select))[0];
    } || eval {
	if (-T STDOUT) {
	    local($SIG{__DIE__});
	    return (GetTerminalSize STDOUT )[0];
	} else {
	    return 0;
	}
    } || eval {
	if (-T STDERR) {
	    local($SIG{__DIE__});
	    return (GetTerminalSize STDERR )[0];
	} else {
	    return 0;
	}
    } || eval {
	local($SIG{__DIE__});
	(GetTerminalSize STDOUT )[0];
    } || eval {
	local($SIG{__DIE__});
	(GetTerminalSize STDERR )[0];
    };
    return $width;
}

1;

# Autoload methods go after =cut, and are processed by the autosplit program.

__END__

=head1 NAME

Term::Prompt - Perl extension for prompting a user for information

=head1 SYNOPSIS

    use Term::Prompt;
    $value = &prompt(...);

    use Term::Prompt qw(termwrap);
    print &termwrap(...);

    $Term::Prompt::MULTILINE_INDENT = '';

=head1 DESCRIPTION

This perl routine will take a prompt, a default response and a list of
possible responses and deal with the user interface, (and the user!),
by displaying the prompt, showing the default, and checking to be sure
that the response is one of the legal choices. --Mark Henderson

Derived from im_prompt2.pl, from anlpasswd (see
ftp://info.mcs.anl.gov/pub/systems/), with permission. Revisions for
Perl 5, addition of alternative help text presentation, addition of
floating point type, addition of regular expression type, addition of
yes/no type, and line wrapping by E. Allen Smith.

Addition of menu functionality and $Term::Prompt::MULTILINE_INDENT by
Matthew Persico.

Additional "types" that could be added would be a phone type, a social
security type, a generic numeric pattern type...

The usage is the following:

 x = do not care, a = alpha-only, n = numeric-only, i = ignore case
 c = case sensitive, r = ranged by the low and high values
 f = floating-point, y = yes/no, e = regular expression - Added by Allen
 m = menu - Added by Matthew

 $result = &prompt("x", "text prompt", "help prompt", "default" );

$result is whatever the user types.

 $result = &prompt("a", "text prompt", "help prompt", "default" );

$result is a single "word" consisting of [A-Za-z] only. The response
is rejected until it conforms.

 $result = &prompt("n", "text prompt", "help prompt", "default" );

The result will be a positive integer or 0.

 $result = &prompt("-n", "text prompt", "help prompt", "default" );

The result will be a negative integer or 0.

 $result = &prompt("+-n", "text prompt", "help prompt", "default" );

The result will be a any integer or 0.

 $result = &prompt("i", "text prompt", "help prompt", "default",
	                 "legal_options-ignore-case-list");

 $result = &prompt("c", "text prompt", "help prompt", "default",
	                 "legal_options-case-sensitive-list");

 $result = &prompt("r", "text prompt", "help prompt", "default",
                       "low", "high");

 $result = &prompt("f", "text prompt", "help prompt", "default");

The result will be a floating-point number.

 $result = &prompt("y", "text prompt", "help prompt", "default")

The result will be 1 for y, 0 for n. A default not starting with y or
n (or the uc versions of these) will be treated as y for positive, n
for negative.

 $result = &prompt("e", "text prompt", "help prompt", "default",
                       "regular expression");

The regular expression for the last has ^ and $ surrounding it
automatically; just put in .* before or after if you need to free it
up before or after. - Allen

What, you might ask, is the difference between a "text prompt" and a
"help prompt"?  Think about the case where the "legal_options" look
something like: "1-1000".  Now consider what happens when you tell
someone that "0" is not between 1-1000 and that the possible choices
are: :) 1 2 3 4 5 .....  This is what the "help prompt" is for.

It will work off of unique parts of "legal_options".

Changed by Allen - if you capitalize the type of prompt, it will be
treated as a true "help prompt"; that is, it will be printed ONLY if
the menu has to be redisplayed due to and entry error. Otherwise, it
will be treated as a list of options and displayed only the first time
the menu is displayed.

Capitalizing the type of prompt will also mean that a return may be
accepted as a response, even if there is no default; whether it
actually is will depend on the type of prompt. Menus, for example, do
not do this. The logic of a return being accepted as a response is
controlled by the I<no_selection_accepted> flag; see below.


 $result = &prompt("m", {
			 prompt           => "text prompt",
			 title            => 'My Silly Menu',
                         items            => [ qw (foo bar baz biff spork boof akak) ],
			 order            => 'across',
			 rows             => 1,
			 cols             => 1,
                         display_base     => 1,
			 return_base      => 0,
			 accept_multiple_selections => 0,
			 accept_empty_selection     => 0
			},
		   "help prompt", "default");

 @results = &prompt("m", {
			  prompt           => "text prompt",
			  title            => 'My Silly Menu',
                          items            => [ qw (foo bar baz biff spork boof akak) ],
			  order            => 'across',
			  rows             => 1,
			  cols             => 1,
			  display_base     => 1,
			  return_base      => 0,
			  accept_multiple_selections => 0,
			  accept_empty_selection     => 0
			 },
		    "help prompt", "default");

This will create a menu with numbered items to select. You replace the
normal I<prompt> argument with a hash reference containing this
information:

=item prompt

The prompt string.

=item title

Text printed above the menu.

=item items

An array reference to the list of text items to display. They will be
numbered ascending in the order presented.

=item order

If set to 'across', the item numbers run across the menu:

 1) foo    2) bar    3) baz
 4) biff   5) spork  6) boof
 7) akak

If set to 'down', the item numbers run down the menu:

 1) foo    4) biff   7) akak
 2) bar    5) spork
 3) baz    6) boof

'down' is the default.

=item rows,cols

Forces the number of rows and columns. Otherwise, the number of rows
and columns is determined from the number of items and the maximum
length of an item with its number.

Usually, you would set rows = 1 or cols = 1 to force a non-wrapped
layout. Setting both in tandem is untested. Cavet programmer.

=item display_base,return_base

Internally, the items are indexed the 'Perl' way, from 0 to scalar
-1. The display_base is the number added to the index on the menu
display. The return_base is the number added to the index before the
reply is returned to the programmer.

The defaults are 1 and 0, respectively.

=item accept_multiple_selections

When set to logical true (1 will suffice), more than one menu item may
be selected. The return from I<prompt()> will be an array or array
ref, depending on how it is called.

The default is 0. The return value is a single scalar containing the
selection.

=item accept_empty_selection

When set to logical true (1 will suffice), if no items are selected,
the menu will not be repeated and the 'empty' selection will be
returned. The value of an 'empty' selection is an empty array or a
reference to same, if I<accept_multiple_selections> is in effect, or
I<undef> if not.

=head2 Other Functions and Variables

=item termwrap

Part of Term::Prompt is the optionally exported function termwrap,
which is used to wrap lines to the width of the currently selected
filehandle (or to STDOUT or STDERR if the width of the current
filehandle cannot be determined).  It uses the GetTerminalSize
function from Term::ReadKey then Text::Wrap.

=item MULTILINE_INDENT

This package variable holds the string to be used to indent lines of a
multiline prompt, after the first line. The default is "\t", which is
how the module worked before the variable was exposed. If yo do not want ANY indentation:

 $Term::Prompt::MULTILINE_INDENT = '';

=head1 AUTHOR

Mark Henderson (henderson@mcs.anl.gov or systems@mcs.anl.gov)

Primary contact author: Allen Smith (easmith@beatrice.rutgers.edu)

Menu additions by Matthew O. Persico (persicom@acedsl.com)

=head1 SEE ALSO

L<perl>, L<Term::ReadKey>, and L<Text::Wrap>.

=cut
