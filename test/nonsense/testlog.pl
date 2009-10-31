use strict;
use warnings;

use Data::Dumper;

use lib 'lib';

use LinuxRulz::Bot::Logger;

my $test = LinuxRulz::Bot::Logger->new(configfile => "/home/linuxrulz/bots/linuxrulz/etc/log4perl.cfg", checktime => 10, namespace => "test");

my $test2 = $test->get_logger("admin");

$test2->warn("1");
$test->info("abc");
