package Term::Prompt;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = {
		delim 		=> ") ",
		spaces		=> 7,
		beforetext 	=> "Please choose one of the following options.",
		aftertext	=> "Please enter a letter or number corresponding to the option you want to choose: ",
		nooptiontext	=> "That's not one of the available options.",
		moreoptions	=> " or ",
		tries		=> 0, #0 is infinite tries. if e.g. 2, user can input 2 false things untill question retuns undef.
		toomanytries	=> "You've tried too many times.",
		hidekeys	=> 0,
		@_,
		lastval 	=> undef,
		tried		=> 0,
		};
	
	bless $self, $class;
	return $self;
}

sub setcfg {
	my $self = shift;
	croak("Error: setcfg is an instance method!") if(!ref $self);
	%$self = (%$self, @_);
}
	
sub menu {
	my $self = shift; # Myself.
	$self = undef if(!ref($self)); # Ignore myself if it's not an instance
	my %options = @_; # The keys and corresponding options
	my $delim = defined($self) ? ${$self}{delim} : ") ";
			# The delimiter between keys and label
	my @lines;	# The lines of the options that need to be printed
	my %keyvals;	# A hash that holds what keys should return what values.
	my $maxoptlen = 0; # Max length of keys that correspond to this value.
	foreach(keys %options) {
		my $value = $_;
		my $label = shift @{$options{$_}};
		my @keys  = @{$options{$_}};
		my $options = join ((defined $self ? ${$self}{moreoptions} : ' or '), @keys);
		$keyvals{$_} = $value foreach(@keys);
		push @lines, [(${$self}{hidekeys} ? "" : $options.$delim).$label."\n", length($options)];
			#Length of options included to get the
			#number of spaces that need to be included.
		$maxoptlen = length($options) if(length($options) > $maxoptlen);
	}
	my $spaces = defined($self) ? ${$self}{spaces} : 7;
	$spaces = $maxoptlen if($maxoptlen > $spaces);
	print ${$self}{beforetext},"\n" if defined $self;
	foreach (@lines) {
		my $line = shift @$_;
		my $len = shift @$_;
		my $nspace = $spaces - $len;
		print " " x $nspace, $line;
	}
	QUESTION:
	print ${$self}{aftertext} if defined $self;
	my $answ = <STDIN>;
	chomp $answ;
	foreach(keys %keyvals) {
		if($answ eq $_) {
			${$self}{lastval} = $keyvals{$_};
			return $keyvals{$_};
			goto ENDSUB; #Escape if return failed. (?)
		}
	}
	if(defined($self)) {
		print ${$self}{nooptiontext},"\n";
		${$self}{tried}++ if(${$self}{tries});
		if(${$self}{tried} >= ${$self}{tries}) {
			goto ENDSUB;
		}
	}
	goto QUESTION;
	ENDSUB:
	if(defined($self) and ${$self}{tried} >= ${$self}{tries}) {
		print ${$self}{toomanytries} if defined ${$self}{toomanytries};
		${$self}{tried} = 0;
		${$self}{lastval} = undef;
		return undef;
	}
}

sub question {
	my ($self, $question) = @_;
	print $question;
	my $answer = <STDIN>;
	${$self}{lastval} = $answer;
	return $answer;
}

sub lastval {
	my $self = shift;
	croak("Error: lastval is an instance method") if(!ref($self));
	return ${$self}{lastval};
}
1;
__END__

=head1 NAME

Term::Prompt - Perl extension for asking questions at the terminal 

=head1 SYNOPSIS

  use Term::Prompt;
  my $prompt = new Term::Prompt;
  my $answer = $prompt->menu(
  	foobar	=>	["Go the FooBar Way!", 'f'],
	barfoo	=>	["Or rather choose BarFoo!", 'b'],
	test	=>	["Or test the script out.", 't'],
	number  =>	["Choose this one if you only want to use numbers!", '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  );
  my $same_answer = $prompt->lastval;
  my $smallquestion = $prompt->question("What's your name? ");

=head1 DESCRIPTION

Term::Prompt is an extension that eases the task of programming user interactivity. It helps you to get information from users, and ask what they really want. It uses basic print commands, and has no dependancies. 

=head2 EXPORT

None by default.

=head1 AUTHOR

Sjors Gielen, E<lt>sjorsgielen@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Sjors Gielen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
