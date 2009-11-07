use strict;
use warnings;
use lib "/home/linuxrulz/libs/perl/";
use LinuxRulz::CRCIPRR;
my $test = LinuxRulz::CRCIPRR->new();

$test->parse("REQUEST|SAY|TEST|TEST|");
$test->parse("REQUEST|SAY|TEST|");
$test->parse("REQUEST|SAY||");

