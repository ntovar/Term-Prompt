#!/usr/bin/perl
use strict;

#### Make Term::Prompt Object ######
## Needed for the other tests
use Term::Prompt;
my $prompt = new Term::Prompt (
	delim	=> "",
	spaces	=> 0,
	beforetext => "",
	aftertext => "test: ",
	nooptiontext => "",
	moreoptions => "",
	tries => 1,
	toomanytries => "",
	hidekeys => 1,
);

#### Ask for an answer and print ok or error ######
## Test what happens if the good answer is given
my $return = $prompt->menu(
	ok	=>	["","a"],
);
if (defined $return and $return eq $prompt->lastval and $return eq "ok") {
	print "ok\n";
} else {
	print "error\n";
	exit;
}

##### Ask for an answer and print ok or error again ######
## Test what happens if a bad answer is given
my @pos_keys = qw(1 2 3 4 6 7 8 9 0 a b c d e f g h i j k l m n o p q r s t u v w x y z);
$return = $prompt->menu(
	ok	=>	["",@pos_keys],
);
if(!defined $return and !defined $prompt->lastval) {
	print "ok\n";
} else {
	print "error\n";
	exit;
}

##### Print a normal question and print ok or error again ######
## Test the normal question
$return = $prompt->question("test: ");
chomp $return if defined $return;
chomp (my $lastval = $prompt->lastval);
if(defined $return and $return eq $lastval and $return eq "abcdefg") {
	print "ok\n";
} else {
	print "error\n";
	exit;
}

##### Quit #####
## Quit Expect interface
$return = $prompt->question("test: ");
chomp $return if defined $return;
if(defined $return and $return eq "quit") {
	exit;
} else {
	print "error\n";
	exit;
}
