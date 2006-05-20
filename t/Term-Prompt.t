use Test::More tests => 8;
use Test::Expect;
BEGIN { use_ok('Term::Prompt'); };
## First we find the Expect.pl file.
my $command = "perl ";
if(-e "./Expect.pl") {
	$command .= "./Expect.pl";
} elsif(-e "../Expect.pl") {
	$command .= "../Expect.pl";
} elsif(-e "./t/Expect.pl") {
	$command .= "./t/Expect.pl";
} else {
	plan skip_all => "Can't find the Expect file";
}

expect_run(
	command => $command,
	prompt	=> "test: ",
	quit	=> "q",
);

expect("a", "ok", "Giving a good answer");
expect("5", "ok", "Giving a bad answer");
expect("abcdefg", "ok", "Asking a small question");
